package soil

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
	"sync"
)

// Profile represents a local soil profile with physical and chemical attributes.
type Profile struct {
	Region                 string  `json:"region_county"`
	MainSoilType           string  `json:"main_soil_type"`
	SoilTexture            string  `json:"soil_texture"`
	AveragePH              float64 `json:"average_ph"`
	OrganicMatterPct       float64 `json:"organic_matter_pct"`
	DrainageCapacity       string  `json:"drainage_capacity"`
	PrimaryAgriculturalUse string  `json:"primary_agricultural_use"`

	// Derived Agronomic Indices
	EstimatedCEC           float64  `json:"estimated_cec_meq_100g"`   // Cation Exchange Capacity
	ErosionRiskRating      string   `json:"erosion_risk_rating"`      // Low, Moderate, High, Severe
	CompactionRisk         string   `json:"compaction_crusting_risk"` // Low, Moderate, High
	InfiltrationRateMmHr   float64  `json:"infiltration_rate_mm_hr"`
	WaterRetentionCapacity string   `json:"water_retention_capacity"` // Low, Moderate, High
	KeySoilDeficits        []string `json:"key_soil_deficits"`
	RecommendedAmendments  []string `json:"recommended_amendments"`
}

type Service struct {
	mu       sync.RWMutex
	profiles map[string]Profile
	ordered  []Profile
}

func NewService(csvPath string) (*Service, error) {
	s := &Service{
		profiles: make(map[string]Profile),
	}

	if csvPath != "" {
		if err := s.loadCSV(csvPath); err != nil {
			fmt.Printf("Notice: could not load soil csv %s: %v. Using standard regional defaults.\n", csvPath, err)
			s.loadDefaults()
		}
	} else {
		s.loadDefaults()
	}

	return s, nil
}

func (s *Service) loadCSV(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()

	reader := csv.NewReader(f)
	records, err := reader.ReadAll()
	if err != nil {
		return err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	for i, r := range records {
		if i == 0 || len(r) < 7 {
			continue
		}
		region := strings.TrimSpace(r[0])
		soilType := strings.TrimSpace(r[1])
		texture := strings.TrimSpace(r[2])
		ph, _ := strconv.ParseFloat(strings.TrimSpace(r[3]), 64)
		om, _ := strconv.ParseFloat(strings.TrimSpace(r[4]), 64)
		drainage := strings.TrimSpace(r[5])
		use := strings.TrimSpace(r[6])

		p := s.enrichSoilProfile(Profile{
			Region:                 region,
			MainSoilType:           soilType,
			SoilTexture:            texture,
			AveragePH:              ph,
			OrganicMatterPct:       om,
			DrainageCapacity:       drainage,
			PrimaryAgriculturalUse: use,
		})

		s.profiles[strings.ToLower(region)] = p
		s.ordered = append(s.ordered, p)
	}

	return nil
}

func (s *Service) enrichSoilProfile(p Profile) Profile {
	// Cation Exchange Capacity estimate
	cec := 10.0 + (p.OrganicMatterPct * 3.5)
	if strings.Contains(strings.ToLower(p.SoilTexture), "clay") {
		cec += 15.0
	} else if strings.Contains(strings.ToLower(p.SoilTexture), "loam") {
		cec += 8.0
	}
	p.EstimatedCEC = math.Round(cec*10) / 10

	// Erosion risk & Infiltration based on texture and OM%
	switch {
	case strings.Contains(strings.ToLower(p.SoilTexture), "sandy"):
		p.InfiltrationRateMmHr = 28.0
		p.ErosionRiskRating = "High (Wind & Water Rill Risk)"
		p.CompactionRisk = "Low"
		p.WaterRetentionCapacity = "Low (Requires organic matter / biochar to hold moisture)"
	case strings.Contains(strings.ToLower(p.SoilTexture), "heavy clay") || strings.Contains(strings.ToLower(p.MainSoilType), "vertisol"):
		p.InfiltrationRateMmHr = 4.5
		p.ErosionRiskRating = "Severe (Surface crusting causes high runoff velocity)"
		p.CompactionRisk = "High (Severe waterlogging and root asphyxiation when wet)"
		p.WaterRetentionCapacity = "High (Water locked tightly to clay lattices)"
	case strings.Contains(strings.ToLower(p.SoilTexture), "clay loam") || strings.Contains(strings.ToLower(p.SoilTexture), "loam"):
		p.InfiltrationRateMmHr = 16.0
		p.ErosionRiskRating = "Moderate"
		p.CompactionRisk = "Moderate"
		p.WaterRetentionCapacity = "High (Optimal plant-available water)"
	default:
		p.InfiltrationRateMmHr = 12.0
		p.ErosionRiskRating = "Moderate"
		p.CompactionRisk = "Moderate"
		p.WaterRetentionCapacity = "Moderate"
	}

	// Deficits and Amendments
	var deficits []string
	var amendments []string

	if p.AveragePH < 5.8 {
		deficits = append(deficits, "Soil Acidity (Aluminum toxicity, Phosphorus lockout)")
		amendments = append(amendments, "Agricultural Lime (CaCO3) @ 1.5 - 2.5 t/ha", "Rock Phosphate or Agroforestry prunings")
	} else if p.AveragePH > 7.8 {
		deficits = append(deficits, "Alkalinity / Salinity (Micronutrient Zinc & Iron lockout)")
		amendments = append(amendments, "Gypsum (CaSO4) application to displace sodium", "Acidifying compost / manure")
	}

	if p.OrganicMatterPct < 2.5 {
		deficits = append(deficits, "Critical Organic Matter Depletion (< 2.5%)")
		amendments = append(amendments, "Deep-rooting cover crops (Sunn Hemp, Mucuna)", "Zero-tillage with continuous crop residue mulch")
	}

	if strings.Contains(strings.ToLower(p.DrainageCapacity), "poor") {
		deficits = append(deficits, "Poor Drainage / Waterlogging Hazard")
		amendments = append(amendments, "Broad-bed and furrow (BBF) shaping", "Deep-rooting pigeon pea to create biological drainage channels")
	}

	p.KeySoilDeficits = deficits
	p.RecommendedAmendments = amendments
	return p
}

func (s *Service) loadDefaults() {
	defaults := []Profile{
		{Region: "Nairobi", MainSoilType: "Nitisols (Volcanic)", SoilTexture: "Clay loam", AveragePH: 6.0, OrganicMatterPct: 3.5, DrainageCapacity: "Moderate", PrimaryAgriculturalUse: "Urban/Horticulture"},
		{Region: "Nakuru", MainSoilType: "Andosols (Volcanic ash)", SoilTexture: "Loam", AveragePH: 5.8, OrganicMatterPct: 4.0, DrainageCapacity: "Good", PrimaryAgriculturalUse: "Maize/Wheat/Vegetables"},
		{Region: "Uasin Gishu (Eldoret)", MainSoilType: "Acrisols", SoilTexture: "Clay loam", AveragePH: 5.5, OrganicMatterPct: 3.2, DrainageCapacity: "Moderate", PrimaryAgriculturalUse: "Wheat/Maize"},
		{Region: "Kisumu", MainSoilType: "Vertisols (Black Cotton)", SoilTexture: "Heavy clay", AveragePH: 7.8, OrganicMatterPct: 2.0, DrainageCapacity: "Poor", PrimaryAgriculturalUse: "Rice/Sugarcane"},
		{Region: "Kakamega", MainSoilType: "Ferralsols (Deep clay)", SoilTexture: "Clay", AveragePH: 5.2, OrganicMatterPct: 4.5, DrainageCapacity: "Moderate", PrimaryAgriculturalUse: "Sugarcane/Maize"},
		{Region: "Nyeri", MainSoilType: "Nitisols (Fertile red)", SoilTexture: "Clay", AveragePH: 5.6, OrganicMatterPct: 4.2, DrainageCapacity: "Good", PrimaryAgriculturalUse: "Tea/Coffee"},
		{Region: "Narok", MainSoilType: "Phaeozems", SoilTexture: "Loam", AveragePH: 6.5, OrganicMatterPct: 3.8, DrainageCapacity: "Good", PrimaryAgriculturalUse: "Wheat/Barley/Livestock"},
		{Region: "Mombasa", MainSoilType: "Ferralsols (Sandy/Coastal)", SoilTexture: "Sandy loam", AveragePH: 7.2, OrganicMatterPct: 1.2, DrainageCapacity: "High", PrimaryAgriculturalUse: "Tree crops (Coconut/Cashew)"},
		{Region: "Marsabit", MainSoilType: "Regosols (Arid/Sandy)", SoilTexture: "Sandy", AveragePH: 8.2, OrganicMatterPct: 0.5, DrainageCapacity: "Excessive", PrimaryAgriculturalUse: "Nomadic Pastoralism"},
		{Region: "Wajir", MainSoilType: "Solonchaks (Saline/Arid)", SoilTexture: "Sandy clay", AveragePH: 8.5, OrganicMatterPct: 0.3, DrainageCapacity: "Poor to Excessive", PrimaryAgriculturalUse: "Nomadic Pastoralism"},
	}

	for _, d := range defaults {
		p := s.enrichSoilProfile(d)
		s.profiles[strings.ToLower(d.Region)] = p
		s.ordered = append(s.ordered, p)
	}
}

// GetProfile returns the profile for a region or finds closest match.
func (s *Service) GetProfile(regionOrCounty string) (Profile, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	clean := strings.ToLower(strings.TrimSpace(regionOrCounty))
	p, ok := s.profiles[clean]
	if ok {
		return p, true
	}

	// Partial match search
	for k, v := range s.profiles {
		if strings.Contains(k, clean) || strings.Contains(clean, k) {
			return v, true
		}
	}

	// Default fallback profile (balanced loam)
	fallback := Profile{
		Region:                 regionOrCounty,
		MainSoilType:           "Nitisols / Loam (General Agricultural)",
		SoilTexture:            "Loam",
		AveragePH:              6.2,
		OrganicMatterPct:       3.0,
		DrainageCapacity:       "Good",
		PrimaryAgriculturalUse: "Mixed Cropping",
	}
	return s.enrichSoilProfile(fallback), false
}

// GetAllProfiles returns all loaded soil profiles.
func (s *Service) GetAllProfiles() []Profile {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.ordered
}
