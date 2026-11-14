package server

import (
	"net/http"
	"strings"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"kilimo/internal/crops"
	"kilimo/internal/ml"
	"kilimo/internal/models"
	"kilimo/internal/nasa"
	"kilimo/internal/rotation"
)

func (s *Server) RegisterRoutes() http.Handler {
	r := gin.Default()

	// Robust CORS configuration
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:5173", "http://localhost:3000", "http://127.0.0.1:5173", "*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Accept", "Authorization", "Content-Type", "Origin", "X-Requested-With"},
		AllowCredentials: false,
	}))

	// System & Health Endpoints
	r.GET("/", s.RootHandler)
	r.GET("/health", s.HealthHandler)

	// API v1 Group
	v1 := r.Group("/api/v1")
	{
		// Farmer Auth & Farm Profile Setup (Sign up by Farm Location)
		v1.POST("/auth/signup", s.SignUpHandler)
		v1.POST("/auth/login", s.LoginHandler)

		// Authenticated Farmer Farm-Specific Routes
		farmerGroup := v1.Group("/farm")
		farmerGroup.Use(s.AuthMiddleware())
		{
			farmerGroup.GET("/profile", s.GetFarmerProfileHandler)
			farmerGroup.PUT("/location", s.UpdateFarmLocationHandler)
			farmerGroup.GET("/recommendations", s.GetFarmRecommendationsHandler)
			farmerGroup.GET("/vulnerabilities", s.GetFarmVulnerabilitiesHandler)
			farmerGroup.POST("/simulate", s.SimulateFarmScenariosHandler)
		}

		// Agronomic & Soil Reference Endpoints
		v1.GET("/regions", s.GetRegionsHandler)
		v1.GET("/crops", s.GetCropsHandler)
		v1.GET("/crops/:id", s.GetCropByIDHandler)

		// NASA Earth Observation Endpoints
		v1.POST("/nasa/observations", s.FetchNASAObservationsHandler)
		v1.GET("/nasa/metrics-info", s.GetNASAMetricsInfoHandler)

		// Field Vulnerability Diagnosis
		v1.POST("/analyze/vulnerabilities", s.AnalyzeVulnerabilitiesHandler)

		// Gorgonia Machine Learning Inference Endpoints
		v1.POST("/ml/predict-crop-suitability", s.PredictCropSuitabilityHandler)
		v1.POST("/ml/batch-predict", s.BatchPredictHandler)

		// General Crop Rotation Decision Support & Simulation Endpoints
		v1.POST("/rotations/recommend", s.RecommendRotationsHandler)
		v1.POST("/rotations/simulate", s.SimulateScenariosHandler)
	}

	return r
}

func (s *Server) RootHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"project":     "Kilimo Decision-Support System",
		"challenge":   "NASA Space Apps Challenge - Resilient Crop Rotations",
		"description": "Decision-support API using NASA Earth observations (POWER, SMAP, ECOSTRESS, GPM, MODIS, SRTM, GRACE), local soil data, and Gorgonia machine learning to explore resilient crop rotation strategies.",
		"status":      "online",
		"version":     "1.1.0",
		"endpoints": gin.H{
			"auth_signup":          "POST /api/v1/auth/signup (Sign up with farm location & soil)",
			"auth_login":           "POST /api/v1/auth/login",
			"farm_profile":         "GET  /api/v1/farm/profile (Bearer token auth)",
			"farm_recommendations": "GET  /api/v1/farm/recommendations (Direct tailored strategies)",
			"farm_vulnerabilities": "GET  /api/v1/farm/vulnerabilities",
			"farm_simulate":        "POST /api/v1/farm/simulate",
			"health":               "GET  /health",
			"regions":              "GET  /api/v1/regions",
			"crops":                "GET  /api/v1/crops",
			"nasa_observations":    "POST /api/v1/nasa/observations",
			"nasa_metrics_info":    "GET  /api/v1/nasa/metrics-info",
			"rotations_recommend":  "POST /api/v1/rotations/recommend",
			"rotations_simulate":   "POST /api/v1/rotations/simulate",
		},
	})
}

func (s *Server) HealthHandler(c *gin.Context) {
	dbHealth := s.db.Health()
	c.JSON(http.StatusOK, gin.H{
		"server":   "healthy",
		"database": dbHealth,
		"ml_engine": gin.H{
			"backend": "Gorgonia Neural Network (TapeMachine)",
			"status":  "ready",
		},
	})
}

// AuthMiddleware validates the Authorization Bearer token header.
func (s *Server) AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required (Bearer token)"})
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid Authorization header format. Format: Bearer <token>"})
			return
		}

		token := parts[1]
		farmer, err := s.auth.AuthenticateToken(token)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired session token"})
			return
		}

		c.Set("farmer", farmer)
		c.Next()
	}
}

// SignUpHandler registers a farmer by farm location coordinates and local soil characteristics.
func (s *Server) SignUpHandler(c *gin.Context) {
	var req models.SignUpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, token, err := s.auth.SignUp(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, models.AuthResponse{
		Token:   token,
		Farmer:  *profile,
		Message: "Farmer account successfully registered with farm geospatial location",
	})
}

// LoginHandler logs in a farmer.
func (s *Server) LoginHandler(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, token, err := s.auth.Login(req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.AuthResponse{
		Token:   token,
		Farmer:  *profile,
		Message: "Authentication successful",
	})
}

// GetFarmerProfileHandler returns the authenticated farmer's profile.
func (s *Server) GetFarmerProfileHandler(c *gin.Context) {
	val, exists := c.Get("farmer")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Farmer context not found"})
		return
	}
	farmer := val.(*models.FarmerProfile)
	c.JSON(http.StatusOK, farmer)
}

// UpdateFarmLocationHandler updates the farmer's registered farm location.
func (s *Server) UpdateFarmLocationHandler(c *gin.Context) {
	val, _ := c.Get("farmer")
	farmer := val.(*models.FarmerProfile)

	var req struct {
		Location       models.FarmLocation        `json:"location" binding:"required"`
		SoilAttributes *models.FarmSoilAttributes `json:"soil_attributes,omitempty"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updated, err := s.auth.UpdateFarmLocation(farmer.ID, req.Location, req.SoilAttributes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Farm location updated successfully",
		"farmer":  updated,
	})
}

// GetFarmRecommendationsHandler automatically generates tailored crop rotations using the farmer's registered farm location.
func (s *Server) GetFarmRecommendationsHandler(c *gin.Context) {
	val, _ := c.Get("farmer")
	farmer := val.(*models.FarmerProfile)

	// Build rotation request directly from registered farm location and soil
	recReq := rotation.RecommendationRequest{
		Latitude:        farmer.Location.Latitude,
		Longitude:       farmer.Location.Longitude,
		Region:          farmer.Location.CountyRegion,
		CurrentRotation: farmer.CurrentCropHistory,
		CustomSoilPH:    farmer.SoilPreferences.CustomPH,
		CustomSoilOM:    farmer.SoilPreferences.CustomOMPct,
		CustomTexture:   farmer.SoilPreferences.SoilTexture,
		FarmerPriorities: rotation.FarmerPriorities{
			SoilOrganicMatter: farmer.DefaultPriorities.SoilOrganicMatter,
			WaterConservation: farmer.DefaultPriorities.WaterConservation,
			NitrogenFixing:    farmer.DefaultPriorities.NitrogenFixing,
			PestDisruption:    farmer.DefaultPriorities.PestDisruption,
			IncomeMarketValue: farmer.DefaultPriorities.IncomeMarketValue,
			ForageValue:       farmer.DefaultPriorities.ForageValue,
			Equipment:         farmer.DefaultPriorities.EquipmentType,
		},
	}

	report, err := s.rotation.GenerateRecommendations(c.Request.Context(), recReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"farm_id":         farmer.ID,
		"farm_name":       farmer.FarmName,
		"farm_location":   farmer.Location,
		"rotation_report": report,
	})
}

// GetFarmVulnerabilitiesHandler provides vulnerability analysis for the registered farm.
func (s *Server) GetFarmVulnerabilitiesHandler(c *gin.Context) {
	val, _ := c.Get("farmer")
	farmer := val.(*models.FarmerProfile)

	obs, err := s.nasa.FetchObservations(c.Request.Context(), farmer.Location.Latitude, farmer.Location.Longitude)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	soilProfile, _ := s.soil.GetProfile(farmer.Location.CountyRegion)

	var bareMonths []string
	var thermalStressPeriods []string
	for _, m := range obs.Monthly {
		if m.IsBareSoil {
			bareMonths = append(bareMonths, m.Month)
		}
		if m.MaxTemperatureC > 30.0 || m.WaterDeficitMM < -30.0 {
			thermalStressPeriods = append(thermalStressPeriods, m.Month)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"farm_id":         farmer.ID,
		"farm_name":       farmer.FarmName,
		"location":        farmer.Location,
		"soil_attributes": farmer.SoilPreferences,
		"soil_baseline":   soilProfile,
		"bare_soil_diagnosis": gin.H{
			"bare_soil_months":       bareMonths,
			"bare_soil_months_count": len(bareMonths),
			"erosion_hazard":         obs.SRTM.RunoffHazard,
		},
		"climate_stress_diagnosis": gin.H{
			"smap_drought_stress":    obs.SMAP.DroughtStressIndex,
			"ecostress_heat_stress":  obs.ECOSTRESS.HeatStressCategory,
			"thermal_stress_periods": thermalStressPeriods,
			"shallow_root_risk":      obs.ECOSTRESS.ShallowRootVulnerability,
		},
	})
}

// SimulateFarmScenariosHandler runs perturbation simulations for the registered farm.
func (s *Server) SimulateFarmScenariosHandler(c *gin.Context) {
	val, _ := c.Get("farmer")
	farmer := val.(*models.FarmerProfile)

	var simReq struct {
		RainfallAnomalyPct    float64 `json:"rainfall_anomaly_pct"`
		TemperatureIncreaseC  float64 `json:"temperature_increase_c"`
		DroughtFrequencyYears int     `json:"drought_frequency_years"`
	}
	if err := c.ShouldBindJSON(&simReq); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	sim := rotation.SimulationRequest{
		RecommendationRequest: rotation.RecommendationRequest{
			Latitude:        farmer.Location.Latitude,
			Longitude:       farmer.Location.Longitude,
			Region:          farmer.Location.CountyRegion,
			CurrentRotation: farmer.CurrentCropHistory,
			CustomSoilPH:    farmer.SoilPreferences.CustomPH,
			CustomSoilOM:    farmer.SoilPreferences.CustomOMPct,
			CustomTexture:   farmer.SoilPreferences.SoilTexture,
			FarmerPriorities: rotation.FarmerPriorities{
				SoilOrganicMatter: farmer.DefaultPriorities.SoilOrganicMatter,
				WaterConservation: farmer.DefaultPriorities.WaterConservation,
				NitrogenFixing:    farmer.DefaultPriorities.NitrogenFixing,
				PestDisruption:    farmer.DefaultPriorities.PestDisruption,
				IncomeMarketValue: farmer.DefaultPriorities.IncomeMarketValue,
			},
		},
		RainfallAnomalyPct:    simReq.RainfallAnomalyPct,
		TemperatureIncreaseC:  simReq.TemperatureIncreaseC,
		DroughtFrequencyYears: simReq.DroughtFrequencyYears,
	}

	report, err := s.rotation.SimulateScenarios(c.Request.Context(), sim)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"farm_id":           farmer.ID,
		"farm_name":         farmer.FarmName,
		"simulation_report": report,
	})
}

func (s *Server) GetRegionsHandler(c *gin.Context) {
	profiles := s.soil.GetAllProfiles()
	c.JSON(http.StatusOK, gin.H{
		"count":   len(profiles),
		"regions": profiles,
	})
}

func (s *Server) GetCropsHandler(c *gin.Context) {
	allCrops := crops.GetAllCrops()
	c.JSON(http.StatusOK, gin.H{
		"count": len(allCrops),
		"crops": allCrops,
	})
}

func (s *Server) GetCropByIDHandler(c *gin.Context) {
	id := c.Param("id")
	crop, ok := crops.GetCrop(id)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Crop not found in catalog"})
		return
	}
	c.JSON(http.StatusOK, crop)
}

type CoordsRequest struct {
	Latitude  float64 `json:"latitude" binding:"required"`
	Longitude float64 `json:"longitude" binding:"required"`
}

func (s *Server) FetchNASAObservationsHandler(c *gin.Context) {
	var req CoordsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid coordinates payload. 'latitude' and 'longitude' are required numbers."})
		return
	}

	obs, err := s.nasa.FetchObservations(c.Request.Context(), req.Latitude, req.Longitude)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, obs)
}

func (s *Server) GetNASAMetricsInfoHandler(c *gin.Context) {
	info := nasa.MetricsEducationalInfo()
	c.JSON(http.StatusOK, gin.H{
		"title":       "NASA Earth Observation Metrics for Agronomy",
		"definitions": info,
	})
}

type VulnerabilityRequest struct {
	Latitude        float64  `json:"latitude"`
	Longitude       float64  `json:"longitude"`
	Region          string   `json:"region"`
	CurrentRotation []string `json:"current_rotation"`
}

func (s *Server) AnalyzeVulnerabilitiesHandler(c *gin.Context) {
	var req VulnerabilityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Latitude == 0 && req.Longitude == 0 {
		req.Latitude = -0.3031 // default Nakuru
		req.Longitude = 36.0800
	}
	if req.Region == "" {
		req.Region = "Nakuru"
	}

	obs, err := s.nasa.FetchObservations(c.Request.Context(), req.Latitude, req.Longitude)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	soilProfile, _ := s.soil.GetProfile(req.Region)

	current := req.CurrentRotation
	if len(current) == 0 {
		current = []string{"maize", "maize"}
	}

	var bareMonths []string
	var thermalStressPeriods []string
	for _, m := range obs.Monthly {
		if m.IsBareSoil {
			bareMonths = append(bareMonths, m.Month)
		}
		if m.MaxTemperatureC > 30.0 || m.WaterDeficitMM < -30.0 {
			thermalStressPeriods = append(thermalStressPeriods, m.Month)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"region":             soilProfile.Region,
		"soil_type":          soilProfile.MainSoilType,
		"soil_texture":       soilProfile.SoilTexture,
		"ph":                 soilProfile.AveragePH,
		"organic_matter_pct": soilProfile.OrganicMatterPct,
		"current_rotation":   current,
		"bare_soil_diagnosis": gin.H{
			"bare_soil_months":       bareMonths,
			"bare_soil_months_count": len(bareMonths),
			"erosion_hazard":         obs.SRTM.RunoffHazard,
			"risk_explanation":       "Uncovered soil during dry intervals leads to rapid organic matter oxidation, microbial die-off, and devastating topsoil loss during intense rainfall events.",
		},
		"climate_stress_diagnosis": gin.H{
			"smap_drought_stress":    obs.SMAP.DroughtStressIndex,
			"ecostress_heat_stress":  obs.ECOSTRESS.HeatStressCategory,
			"thermal_stress_periods": thermalStressPeriods,
			"shallow_root_risk":      obs.ECOSTRESS.ShallowRootVulnerability,
		},
		"pest_cycle_diagnosis": gin.H{
			"risk":               "Continuous host cultivation permits persistent cycles of stem borers, aphids, and nematodes.",
			"recommended_action": "Introduce non-host crops (e.g. Fabaceae legumes or Asteraceae sunflower) to break reproductive pest cycles.",
		},
	})
}

type MLPredictRequest struct {
	CropID           string                    `json:"crop_id" binding:"required"`
	Latitude         float64                   `json:"latitude"`
	Longitude        float64                   `json:"longitude"`
	Region           string                    `json:"region"`
	CustomSoilPH     *float64                  `json:"custom_soil_ph,omitempty"`
	CustomSoilOM     *float64                  `json:"custom_soil_om_pct,omitempty"`
	FarmerPriorities rotation.FarmerPriorities `json:"farmer_priorities"`
}

func (s *Server) PredictCropSuitabilityHandler(c *gin.Context) {
	var req MLPredictRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	crop, ok := crops.GetCrop(req.CropID)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Crop ID not recognized in agronomic catalog"})
		return
	}

	if req.Latitude == 0 && req.Longitude == 0 {
		req.Latitude = -0.3031
		req.Longitude = 36.0800
	}

	obs, err := s.nasa.FetchObservations(c.Request.Context(), req.Latitude, req.Longitude)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	soilProfile, _ := s.soil.GetProfile(req.Region)
	ph := soilProfile.AveragePH
	if req.CustomSoilPH != nil {
		ph = *req.CustomSoilPH
	}
	om := soilProfile.OrganicMatterPct
	if req.CustomSoilOM != nil {
		om = *req.CustomSoilOM
	}

	textureCode := 0.5
	if soilProfile.SoilTexture == "Sandy" || soilProfile.SoilTexture == "Sandy loam" {
		textureCode = 0.2
	} else if soilProfile.SoilTexture == "Heavy clay" || soilProfile.SoilTexture == "Clay" {
		textureCode = 0.8
	}

	heatCode := 0.5
	if crop.HeatTolerance == "Exceptional" {
		heatCode = 1.0
	} else if crop.HeatTolerance == "High" {
		heatCode = 0.8
	}

	modelInput := ml.ModelInputVector{
		AnnualPrecipMM:       obs.GPM.AnnualPrecipitationMM,
		MeanTempC:            obs.Monthly[0].AvgTemperatureC,
		SMAPSoilMoisture:     obs.SMAP.SurfaceSoilMoistureM3M3,
		ECOSTRESS_ESI:        obs.ECOSTRESS.EvaporativeStressIndexESI,
		SRTMSlopePct:         obs.SRTM.SlopePercentage,
		SoilPH:               ph,
		SoilOMPct:            om,
		SoilTextureCode:      textureCode,
		CropWaterDemandMM:    crop.WaterDemandSeasonMM,
		CropNitrogenFixKg:    crop.NitrogenFixationKgPerHa,
		CropRootDepthM:       crop.RootDepthMeters,
		CropHeatToleranceVal: heatCode,
		FarmerPriorityOM:     req.FarmerPriorities.SoilOrganicMatter,
		FarmerPriorityWater:  req.FarmerPriorities.WaterConservation,
		FarmerPriorityPest:   req.FarmerPriorities.PestDisruption,
		FarmerPriorityMarket: req.FarmerPriorities.IncomeMarketValue,
	}

	result, err := s.ml.Predict(modelInput, req.CropID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"crop":       crop,
		"prediction": result,
		"model_info": gin.H{
			"framework":     "Gorgonia Neural Network (TapeMachine Execution Graph)",
			"input_nodes":   16,
			"hidden_layers": []int{32, 16},
			"output_heads":  4,
		},
	})
}

func (s *Server) BatchPredictHandler(c *gin.Context) {
	var req struct {
		Latitude         float64                   `json:"latitude"`
		Longitude        float64                   `json:"longitude"`
		Region           string                    `json:"region"`
		FarmerPriorities rotation.FarmerPriorities `json:"farmer_priorities"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Latitude == 0 && req.Longitude == 0 {
		req.Latitude = -0.3031
		req.Longitude = 36.0800
	}

	obs, err := s.nasa.FetchObservations(c.Request.Context(), req.Latitude, req.Longitude)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	soilProfile, _ := s.soil.GetProfile(req.Region)
	allCrops := crops.GetAllCrops()

	type Item struct {
		Crop       crops.CropProfile    `json:"crop"`
		Prediction *ml.PredictionResult `json:"prediction"`
	}

	results := make([]Item, 0, len(allCrops))
	for _, cr := range allCrops {
		textureCode := 0.5
		heatCode := 0.5
		if cr.HeatTolerance == "Exceptional" {
			heatCode = 1.0
		} else if cr.HeatTolerance == "High" {
			heatCode = 0.8
		}

		in := ml.ModelInputVector{
			AnnualPrecipMM:       obs.GPM.AnnualPrecipitationMM,
			MeanTempC:            20.0,
			SMAPSoilMoisture:     obs.SMAP.SurfaceSoilMoistureM3M3,
			ECOSTRESS_ESI:        obs.ECOSTRESS.EvaporativeStressIndexESI,
			SRTMSlopePct:         obs.SRTM.SlopePercentage,
			SoilPH:               soilProfile.AveragePH,
			SoilOMPct:            soilProfile.OrganicMatterPct,
			SoilTextureCode:      textureCode,
			CropWaterDemandMM:    cr.WaterDemandSeasonMM,
			CropNitrogenFixKg:    cr.NitrogenFixationKgPerHa,
			CropRootDepthM:       cr.RootDepthMeters,
			CropHeatToleranceVal: heatCode,
			FarmerPriorityOM:     req.FarmerPriorities.SoilOrganicMatter,
			FarmerPriorityWater:  req.FarmerPriorities.WaterConservation,
			FarmerPriorityPest:   req.FarmerPriorities.PestDisruption,
			FarmerPriorityMarket: req.FarmerPriorities.IncomeMarketValue,
		}

		pred, err := s.ml.Predict(in, cr.ID)
		if err == nil {
			results = append(results, Item{Crop: cr, Prediction: pred})
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"count":   len(results),
		"results": results,
	})
}

func (s *Server) RecommendRotationsHandler(c *gin.Context) {
	var req rotation.RecommendationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Latitude == 0 && req.Longitude == 0 {
		req.Latitude = -0.3031
		req.Longitude = 36.0800
	}
	if req.Region == "" {
		req.Region = "Nakuru"
	}

	report, err := s.rotation.GenerateRecommendations(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, report)
}

func (s *Server) SimulateScenariosHandler(c *gin.Context) {
	var sim rotation.SimulationRequest
	if err := c.ShouldBindJSON(&sim); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if sim.Latitude == 0 && sim.Longitude == 0 {
		sim.Latitude = -0.3031
		sim.Longitude = 36.0800
	}
	if sim.Region == "" {
		sim.Region = "Nakuru"
	}

	report, err := s.rotation.SimulateScenarios(c.Request.Context(), sim)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, report)
}
