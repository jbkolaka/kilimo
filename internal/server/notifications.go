package server

import (
	"fmt"
	"math"
	"net/http"
	"strings"
	"time"

	"kilimo/internal/crops"
	"kilimo/internal/models"
	"kilimo/internal/nasa"
	"kilimo/internal/soil"

	"github.com/gin-gonic/gin"
)

// weatherSnapshot holds the freshest temperature, moisture and rainfall values
// available for a farm, whether from live daily observations or the seasonal
// climatology fallback.
type weatherSnapshot struct {
	meanTemp    float64
	maxTemp     float64
	minTemp     float64
	window      string
	source      string
	moisture    float64
	hasMoisture bool
	precip      float64
	hasPrecip   bool
}

func buildWeatherSnapshot(obs *nasa.EarthObservationData, live *nasa.DailyObservation) weatherSnapshot {
	if live != nil {
		return weatherSnapshot{
			meanTemp:    live.MeanTempC,
			maxTemp:     live.MaxTempC,
			minTemp:     live.MinTempC,
			window:      fmt.Sprintf("%s – %s", live.StartDate, live.EndDate),
			source:      live.Source,
			moisture:    live.SurfaceSoilMoisture,
			hasMoisture: live.HasSoilMoisture,
			precip:      live.DailyPrecipitationMM,
			hasPrecip:   live.HasPrecipitation,
		}
	}

	snapshot := weatherSnapshot{
		source: "NASA POWER Climatology",
		window: "the current seasonal window",
	}
	if obs == nil {
		return snapshot
	}

	monthIndex := int(time.Now().Month()) - 1
	if monthIndex < 0 || monthIndex >= len(obs.Monthly) {
		monthIndex = 0
	}
	month := obs.Monthly[monthIndex]
	snapshot.meanTemp = month.AvgTemperatureC
	snapshot.maxTemp = month.MaxTemperatureC
	snapshot.minTemp = month.MinTemperatureC
	snapshot.window = fmt.Sprintf("%s seasonal normal", month.Month)
	snapshot.moisture = obs.SMAP.SurfaceSoilMoistureM3M3
	snapshot.hasMoisture = snapshot.moisture > 0
	snapshot.precip = month.PrecipitationMM / 30.416
	snapshot.hasPrecip = snapshot.precip >= 0
	return snapshot
}

// buildFarmSummary condenses the live snapshot into the compact weather and
// crop-risk blocks rendered by the dashboard summary card.
func buildFarmSummary(
	obs *nasa.EarthObservationData,
	live *nasa.DailyObservation,
	cropList []string,
) (models.FarmWeatherSummary, []models.CropTemperatureRisk) {
	snapshot := buildWeatherSnapshot(obs, live)
	summary := models.FarmWeatherSummary{
		MeanTempC: round1(snapshot.meanTemp),
		MaxTempC:  round1(snapshot.maxTemp),
		MinTempC:  round1(snapshot.minTemp),
		Window:    snapshot.window,
		Source:    snapshot.source,
	}
	if snapshot.hasMoisture {
		value := math.Round(snapshot.moisture*100) / 100
		summary.SoilMoistureM3M3 = &value
	}
	if snapshot.hasPrecip {
		value := round1(snapshot.precip)
		summary.PrecipitationMMDay = &value
	}
	return summary, cropTemperatureRisks(snapshot, cropList)
}

// GenerateLiveNotifications builds alerts from actual NASA observations for the
// farm, including a temperature-tolerance check for the crops the farmer keyed
// in. County-level soil/carbon advisories are only added when a regional soil
// profile is supplied.
func (s *Server) GenerateLiveNotifications(
	obs *nasa.EarthObservationData,
	live *nasa.DailyObservation,
	soilProfile soil.Profile,
	farmName string,
	cropList []string,
) []models.FarmNotification {
	now := time.Now()
	// IDs are stable for the calendar day so clients can persist read state
	// across refreshes instead of seeing every poll as a brand new alert.
	day := now.Format("2006-01-02")
	notifications := make([]models.FarmNotification, 0, 8)

	place := strings.TrimSpace(farmName)
	if place == "" {
		place = "your farm"
	}

	snapshot := buildWeatherSnapshot(obs, live)

	// 1. NASA SMAP / POWER: soil moisture from the latest observed surface wetness.
	if snapshot.hasMoisture {
		if snapshot.moisture < 0.22 {
			notifications = append(notifications, models.FarmNotification{
				ID:             fmt.Sprintf("smap-moisture-%s", day),
				Title:          "NASA Satellite Alert: Soil Moisture Deficit",
				Description:    fmt.Sprintf("NASA SMAP surface wetness averaged %.2f m³/m³ at %s over %s. Root-zone moisture is depleting under current evapotranspiration.", snapshot.moisture, place, snapshot.window),
				Category:       "satellite",
				Severity:       "critical",
				IsCritical:     true,
				Source:         "NASA SMAP",
				MetricValue:    fmt.Sprintf("%.2f m³/m³", snapshot.moisture),
				Recommendation: "Apply supplemental drip irrigation or spread organic mulch immediately to insulate root-zone moisture and reduce bare-soil evaporation.",
				Timestamp:      now,
			})
		} else {
			notifications = append(notifications, models.FarmNotification{
				ID:             fmt.Sprintf("smap-optimal-%s", day),
				Title:          "NASA SMAP: Healthy Soil Moisture Window",
				Description:    fmt.Sprintf("Surface moisture is stable at %.2f m³/m³ at %s over %s.", snapshot.moisture, place, snapshot.window),
				Category:       "satellite",
				Severity:       "success",
				Source:         "NASA SMAP",
				MetricValue:    fmt.Sprintf("%.2f m³/m³", snapshot.moisture),
				Recommendation: "Optimal moisture profile supports active crop root respiration and scheduled top-dress fertilization.",
				Timestamp:      now,
			})
		}
	}

	// 2. NASA POWER: observed air temperature at the farm.
	notifications = append(notifications, models.FarmNotification{
		ID:             fmt.Sprintf("power-thermal-%s", day),
		Title:          thermalTitle(snapshot.maxTemp),
		Description:    fmt.Sprintf("NASA POWER measured a mean air temperature of %.1f°C (max %.1f°C, min %.1f°C) at %s over %s.", snapshot.meanTemp, snapshot.maxTemp, snapshot.minTemp, place, snapshot.window),
		Category:       "climate",
		Severity:       thermalSeverity(snapshot.maxTemp),
		IsCritical:     snapshot.maxTemp >= 32,
		Source:         "NASA POWER",
		MetricValue:    fmt.Sprintf("%.1f°C max", snapshot.maxTemp),
		Recommendation: thermalRecommendation(snapshot.maxTemp),
		Timestamp:      now,
	})

	// 3. NASA GPM / POWER: observed precipitation.
	if snapshot.hasPrecip {
		if snapshot.precip < 1.0 {
			notifications = append(notifications, models.FarmNotification{
				ID:             fmt.Sprintf("gpm-dry-%s", day),
				Title:          "NASA GPM: Below-Average Rainfall Window",
				Description:    fmt.Sprintf("NASA GPM/POWER measured %.1f mm/day of precipitation at %s over %s. Soil water recharge is lagging behind crop demand.", snapshot.precip, place, snapshot.window),
				Category:       "climate",
				Severity:       "warning",
				Source:         "NASA GPM",
				MetricValue:    fmt.Sprintf("%.1f mm/day", snapshot.precip),
				Recommendation: "Prioritise mulching and defer nitrogen top-dressing until soil moisture recovers.",
				Timestamp:      now,
			})
		} else {
			notifications = append(notifications, models.FarmNotification{
				ID:             fmt.Sprintf("gpm-rain-%s", day),
				Title:          "NASA GPM: Rainfall Recharge Window",
				Description:    fmt.Sprintf("NASA GPM/POWER measured %.1f mm/day of precipitation at %s over %s, replenishing the root zone.", snapshot.precip, place, snapshot.window),
				Category:       "climate",
				Severity:       "success",
				Source:         "NASA GPM",
				MetricValue:    fmt.Sprintf("%.1f mm/day", snapshot.precip),
				Recommendation: "Time split fertilizer applications with the current rainfall to improve nutrient uptake.",
				Timestamp:      now,
			})
		}
	}

	// 4. Crop-specific temperature tolerance check using the crops the farmer entered.
	if len(cropList) > 0 {
		if alert, ok := cropTemperatureNotification(day, snapshot, place, cropList, now); ok {
			notifications = append(notifications, alert)
		}
	}

	// 5. Precision soil chemistry advisory (regional profile only).
	if soilProfile.Region != "" || soilProfile.MainSoilType != "" {
		ph := soilProfile.AveragePH
		om := soilProfile.OrganicMatterPct
		texture := soilProfile.SoilTexture
		if ph < 5.8 {
			notifications = append(notifications, models.FarmNotification{
				ID:             fmt.Sprintf("soil-acidity-%s", day),
				Title:          "Precision Soil Advisory: Acidity & Phosphorus Fixation",
				Description:    fmt.Sprintf("Soil pH is %.1f at %s (%s). Acidic conditions precipitate aluminum and lock phosphorus, impeding seedling vigor.", ph, place, soilProfile.MainSoilType),
				Category:       "soil",
				Severity:       "warning",
				Source:         "Soil Engine",
				MetricValue:    fmt.Sprintf("pH %.1f", ph),
				Recommendation: "Apply agricultural lime at 1.5–2.0 tonnes/ha or incorporate mature compost/biochar 4 weeks prior to planting.",
				Timestamp:      now,
			})
		} else {
			notifications = append(notifications, models.FarmNotification{
				ID:             fmt.Sprintf("soil-advisory-%s", day),
				Title:          "Precision Soil Health & Fertilizer Advisory",
				Description:    fmt.Sprintf("Soil pH %.1f with %s texture and %.1f%% organic matter at %s. High nutrient bioavailability window.", ph, texture, om, place),
				Category:       "soil",
				Severity:       "info",
				Source:         "Soil Engine",
				MetricValue:    fmt.Sprintf("pH %.1f | OM %.1f%%", ph, om),
				Recommendation: "Apply balanced NPK at planting and top-dress CAN/Urea in synchrony with expected rainfall events.",
				Timestamp:      now,
			})
		}

		// 6. Carbon baseline sync.
		if om >= 2.8 {
			notifications = append(notifications, models.FarmNotification{
				ID:             fmt.Sprintf("carbon-sync-%s", day),
				Title:          "Carbon Credit Baseline Sync: Qualified Tier A",
				Description:    fmt.Sprintf("Soil organic matter level at %.1f%% qualifies %s for verified soil carbon sequestration rewards under regenerative practice tiers.", om, place),
				Category:       "carbon",
				Severity:       "success",
				Source:         "Carbon Registry",
				MetricValue:    fmt.Sprintf("%.1f%% OM", om),
				Recommendation: "Retain crop residues in-situ and eliminate disc plowing to maintain carbon permanence and lock annual carbon payouts.",
				Timestamp:      now,
			})
		}
	}

	return notifications
}

func thermalTitle(maxTemp float64) string {
	switch {
	case maxTemp >= 32:
		return "NASA POWER: Canopy Heat Stress Detected"
	case maxTemp >= 28:
		return "NASA POWER: Elevated Temperature Watch"
	default:
		return "NASA POWER: Normal Thermal Envelope"
	}
}

func thermalSeverity(maxTemp float64) string {
	switch {
	case maxTemp >= 32:
		return "critical"
	case maxTemp >= 28:
		return "warning"
	default:
		return "success"
	}
}

func thermalRecommendation(maxTemp float64) string {
	switch {
	case maxTemp >= 32:
		return "Irrigate during cooler evening hours and plan shade intercropping (e.g. pigeon pea or agroforestry strips) to break radiative thermal load."
	case maxTemp >= 28:
		return "Monitor sensitive crops and irrigate early morning to reduce transpiration stress."
	default:
		return "Temperature is within the optimal range for vegetative photosynthesis and nutrient uptake."
	}
}

type cropTempImpact struct {
	name  string
	limit float64
	kind  string
	delta float64
}

// resolveCrops maps the farmer's free-text crop names onto catalog profiles,
// preserving the entered order and dropping duplicates.
func resolveCrops(cropList []string) []crops.CropProfile {
	resolved := make([]crops.CropProfile, 0, len(cropList))
	seen := map[string]bool{}
	for _, name := range cropList {
		profile, ok := crops.GetCropByName(name)
		if !ok || seen[profile.ID] {
			continue
		}
		seen[profile.ID] = true
		resolved = append(resolved, profile)
	}
	return resolved
}

// cropTempImpacts lists every crop whose temperature tolerance is broken.
func cropTempImpacts(snapshot weatherSnapshot, resolved []crops.CropProfile) []cropTempImpact {
	var impacts []cropTempImpact
	for _, profile := range resolved {
		if snapshot.maxTemp > profile.TempMaxC {
			impacts = append(impacts, cropTempImpact{
				name:  profile.CommonName,
				limit: profile.TempMaxC,
				kind:  "heat",
				delta: round1(snapshot.maxTemp - profile.TempMaxC),
			})
		}
		if snapshot.minTemp < profile.TempMinC {
			impacts = append(impacts, cropTempImpact{
				name:  profile.CommonName,
				limit: profile.TempMinC,
				kind:  "cold",
				delta: round1(profile.TempMinC - snapshot.minTemp),
			})
		}
	}
	return impacts
}

// cropTemperatureRisks returns one status row per resolved crop for the
// dashboard card, choosing the larger exceedance when both ends break.
func cropTemperatureRisks(snapshot weatherSnapshot, cropList []string) []models.CropTemperatureRisk {
	resolved := resolveCrops(cropList)
	if len(resolved) == 0 {
		return nil
	}

	risks := make([]models.CropTemperatureRisk, 0, len(resolved))
	for _, profile := range resolved {
		risk := models.CropTemperatureRisk{Name: profile.CommonName}
		heat := snapshot.maxTemp - profile.TempMaxC
		cold := profile.TempMinC - snapshot.minTemp
		switch {
		case heat > 0 && heat >= cold:
			limit := profile.TempMaxC
			excess := round1(heat)
			risk.Status = "heat_stress"
			risk.LimitC = &limit
			risk.ExceedanceC = &excess
		case cold > 0:
			limit := profile.TempMinC
			excess := round1(cold)
			risk.Status = "cold_stress"
			risk.LimitC = &limit
			risk.ExceedanceC = &excess
		default:
			risk.Status = "ok"
		}
		risks = append(risks, risk)
	}
	return risks
}

// cropTemperatureNotification compares the live observed air temperature with
// the heat/cold limits of every crop the farmer entered and reports the ones
// that fall outside their tolerance. It returns false when no crop name can be
// resolved to the agronomic catalog.
func cropTemperatureNotification(
	day string,
	snapshot weatherSnapshot,
	place string,
	cropList []string,
	now time.Time,
) (models.FarmNotification, bool) {
	resolved := resolveCrops(cropList)
	if len(resolved) == 0 {
		return models.FarmNotification{}, false
	}

	impacts := cropTempImpacts(snapshot, resolved)
	names := make([]string, 0, len(resolved))
	for _, profile := range resolved {
		names = append(names, profile.CommonName)
	}

	if len(impacts) == 0 {
		return models.FarmNotification{
			ID:             fmt.Sprintf("crop-temp-ok-%s", day),
			Title:          "NASA Temperature Check: Your Crops Are Within Tolerance",
			Description:    fmt.Sprintf("NASA POWER observed %.1f–%.1f°C at %s over %s. Your %d crop(s) — %s — remain inside their temperature limits.", snapshot.minTemp, snapshot.maxTemp, place, snapshot.window, len(resolved), strings.Join(names, ", ")),
			Category:       "climate",
			Severity:       "success",
			Source:         "NASA POWER + Crop Catalog",
			MetricValue:    fmt.Sprintf("%.1f–%.1f°C", snapshot.minTemp, snapshot.maxTemp),
			Recommendation: "No temperature action is required; keep monitoring the next NASA observation window.",
			Timestamp:      now,
		}, true
	}

	parts := make([]string, 0, len(impacts))
	worst := 0.0
	hasHeat := false
	hasCold := false
	for _, im := range impacts {
		if im.kind == "heat" {
			hasHeat = true
			parts = append(parts, fmt.Sprintf("%s exceeds its %.1f°C heat limit by %.1f°C", im.name, im.limit, im.delta))
		} else {
			hasCold = true
			parts = append(parts, fmt.Sprintf("%s is below its %.1f°C cold limit by %.1f°C", im.name, im.limit, im.delta))
		}
		if im.delta > worst {
			worst = im.delta
		}
	}

	severity := "warning"
	isCritical := false
	if worst >= 3.0 {
		severity = "critical"
		isCritical = true
	}

	recommendation := ""
	switch {
	case hasHeat && hasCold:
		recommendation = "Irrigate at dawn/dusk and mulch to buffer heat, while protecting the cold-sensitive crop from cooler nights."
	case hasHeat:
		recommendation = "Irrigate at dawn/dusk, mulch bare soil, and provide temporary shade for the affected crops."
	case hasCold:
		recommendation = "Delay planting or use row covers and mulch to protect the affected crops from cold nights."
	}

	return models.FarmNotification{
		ID:             fmt.Sprintf("crop-temp-risk-%s", day),
		Title:          fmt.Sprintf("NASA Temperature Alert: %d Crop Issue(s) at %s", len(impacts), place),
		Description:    fmt.Sprintf("Live NASA POWER temperature at %s ranged %.1f–%.1f°C over %s. %s.", place, snapshot.minTemp, snapshot.maxTemp, snapshot.window, strings.Join(parts, "; ")),
		Category:       "climate",
		Severity:       severity,
		IsCritical:     isCritical,
		Source:         "NASA POWER + Crop Catalog",
		MetricValue:    fmt.Sprintf("%.1f–%.1f°C", snapshot.minTemp, snapshot.maxTemp),
		Recommendation: recommendation,
		Timestamp:      now,
	}, true
}

func round1(value float64) float64 {
	return math.Round(value*10) / 10
}

// GetFarmNotificationsHandler returns live satellite alerts for the authenticated farmer.
func (s *Server) GetFarmNotificationsHandler(c *gin.Context) {
	val, exists := c.Get("farmer")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Farmer context not found"})
		return
	}
	farmer := val.(*models.FarmerProfile)

	lat := farmer.Location.Latitude
	lon := farmer.Location.Longitude
	if lat == 0 && lon == 0 {
		lat = -0.3031
		lon = 36.0800
	}

	// Prefer the latest real daily observations; the climatology is only used
	// when NASA POWER has no fresh daily data for this coordinate.
	live, liveErr := s.nasa.FetchRecentDaily(c.Request.Context(), lat, lon)
	obs, err := s.nasa.FetchObservations(c.Request.Context(), lat, lon)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if liveErr != nil {
		live = nil
	}

	soilProfile, _ := s.soil.GetProfile(farmer.Location.CountyRegion)
	notifications := s.GenerateLiveNotifications(obs, live, soilProfile, farmer.FarmName, farmer.CurrentCropHistory)

	criticalCount := 0
	for _, n := range notifications {
		if n.IsCritical {
			criticalCount++
		}
	}

	dataSource := obs.Source
	if live != nil {
		dataSource = live.Source
	}

	summary, cropRisk := buildFarmSummary(obs, live, farmer.CurrentCropHistory)

	c.JSON(http.StatusOK, models.NotificationResponse{
		Count:         len(notifications),
		CriticalCount: criticalCount,
		Coordinates:   farmer.Location,
		Region:        farmer.FarmName,
		DataSource:    dataSource,
		Weather:       &summary,
		CropRisk:      cropRisk,
		Notifications: notifications,
	})
}

// FetchNASANotificationsHandler returns live satellite alerts for any given coordinates.
func (s *Server) FetchNASANotificationsHandler(c *gin.Context) {
	var req struct {
		Latitude  float64  `json:"latitude"`
		Longitude float64  `json:"longitude"`
		Region    string   `json:"region"`
		FarmName  string   `json:"farm_name"`
		Crops     []string `json:"crops"`
		CustomPH  *float64 `json:"custom_ph,omitempty"`
		CustomOM  *float64 `json:"custom_om_pct,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "valid farm coordinates are required"})
		return
	}

	if req.Latitude == 0 && req.Longitude == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "valid farm coordinates are required"})
		return
	}

	hasRegionalProfile := strings.TrimSpace(req.Region) != ""
	if !hasRegionalProfile {
		req.Region = "your farm"
	}

	live, liveErr := s.nasa.FetchRecentDaily(c.Request.Context(), req.Latitude, req.Longitude)
	obs, err := s.nasa.FetchObservations(c.Request.Context(), req.Latitude, req.Longitude)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if liveErr != nil {
		live = nil
	}

	soilProfile, _ := s.soil.GetProfile(req.Region)
	if req.CustomPH != nil {
		soilProfile.AveragePH = *req.CustomPH
	}
	if req.CustomOM != nil {
		soilProfile.OrganicMatterPct = *req.CustomOM
	}
	if !hasRegionalProfile {
		// Coordinate-only requests should not inherit county soil chemistry.
		soilProfile = soil.Profile{}
	}

	notifications := s.GenerateLiveNotifications(obs, live, soilProfile, req.FarmName, req.Crops)

	criticalCount := 0
	for _, n := range notifications {
		if n.IsCritical {
			criticalCount++
		}
	}

	dataSource := obs.Source
	if live != nil {
		dataSource = live.Source
	}

	summary, cropRisk := buildFarmSummary(obs, live, req.Crops)

	c.JSON(http.StatusOK, models.NotificationResponse{
		Count:         len(notifications),
		CriticalCount: criticalCount,
		Coordinates: models.FarmLocation{
			Latitude:     req.Latitude,
			Longitude:    req.Longitude,
			CountyRegion: req.Region,
		},
		Region:        req.Region,
		DataSource:    dataSource,
		Weather:       &summary,
		CropRisk:      cropRisk,
		Notifications: notifications,
	})
}
