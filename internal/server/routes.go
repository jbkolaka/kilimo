package server

import (
	"net/http"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"kilimo/internal/crops"
	"kilimo/internal/ml"
	"kilimo/internal/nasa"
	"kilimo/internal/rotation"
)

func (s *Server) RegisterRoutes() http.Handler {
	r := gin.Default()

	// Robust CORS configuration for frontend and external clients
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

		// Crop Rotation Decision Support & Simulation Endpoints
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
		"version":     "1.0.0",
		"endpoints": gin.H{
			"health":              "GET /health",
			"regions":             "GET /api/v1/regions",
			"crops":               "GET /api/v1/crops",
			"nasa_observations":   "POST /api/v1/nasa/observations",
			"nasa_metrics_info":   "GET /api/v1/nasa/metrics-info",
			"vulnerabilities":     "POST /api/v1/analyze/vulnerabilities",
			"ml_predict":          "POST /api/v1/ml/predict-crop-suitability",
			"ml_batch_predict":    "POST /api/v1/ml/batch-predict",
			"rotations_recommend": "POST /api/v1/rotations/recommend",
			"rotations_simulate":  "POST /api/v1/rotations/simulate",
		},
	})
}

func (s *Server) HealthHandler(c *gin.Context) {
	dbHealth := s.db.Health()
	c.JSON(http.StatusOK, gin.H{
		"server":   "healthy",
		"database": dbHealth,
		"ml_engine": gin.H{
			"backend": "Gorgonia Computation Graph",
			"status":  "ready",
		},
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

	// Calculate bare soil periods and vulnerability
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
