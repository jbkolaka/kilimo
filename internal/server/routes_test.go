package server

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"kilimo/internal/auth"
	"kilimo/internal/ml"
	"kilimo/internal/models"
	"kilimo/internal/nasa"
	"kilimo/internal/rotation"
	"kilimo/internal/soil"
)

type mockDB struct{}

func (m *mockDB) Health() map[string]string {
	return map[string]string{"status": "up", "message": "It's healthy"}
}
func (m *mockDB) Close() error { return nil }

func setupTestServer() *Server {
	nasaSvc := nasa.NewService("../../training_data/kenya-climate-data-1991-2016-rainfallmm.csv")
	soilSvc, _ := soil.NewService("../../training_data/kenya_regional_soil_data.csv")
	mlEng := ml.NewEngine()
	rotSvc := rotation.NewService(nasaSvc, soilSvc, mlEng)
	authSvc := auth.NewService(soilSvc)

	return &Server{
		port:     8080,
		db:       &mockDB{},
		nasa:     nasaSvc,
		soil:     soilSvc,
		ml:       mlEng,
		rotation: rotSvc,
		auth:     authSvc,
	}
}

func TestFarmerSignUpAndFarmRequests(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	// 1. Sign up by farm location
	signUpPayload := map[string]interface{}{
		"email":           "farmer.kamau@kilimo.africa",
		"password":        "secret123",
		"name":            "Kamau Njoroge",
		"farm_name":       "Green Valley Farm",
		"farm_size_acres": 5.5,
		"location": map[string]interface{}{
			"latitude":           -0.3031,
			"longitude":          36.0800,
			"county_region":      "Nakuru",
			"sub_county_village": "Njoro Sub-County",
		},
		"current_crop_history": []string{"maize", "maize"},
		"priorities": map[string]interface{}{
			"soil_organic_matter": 0.9,
			"water_conservation":  0.85,
			"nitrogen_fixing":     0.8,
			"income_market_value": 0.75,
		},
	}
	body, _ := json.Marshal(signUpPayload)
	req, _ := http.NewRequest("POST", "/api/v1/auth/signup", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("expected 201 Created for signup, got %d, body: %s", rr.Code, rr.Body.String())
	}

	var authResp struct {
		Token  string `json:"token"`
		Farmer struct {
			ID       string `json:"id"`
			Location struct {
				Latitude  float64 `json:"latitude"`
				Longitude float64 `json:"longitude"`
				Region    string  `json:"county_region"`
			} `json:"location"`
		} `json:"farmer"`
	}
	if err := json.Unmarshal(rr.Body.Bytes(), &authResp); err != nil {
		t.Fatalf("failed to decode signup response: %v", err)
	}

	if authResp.Token == "" {
		t.Fatalf("expected non-empty token")
	}
	token := authResp.Token

	// 2. Request profile using Token
	req, _ = http.NewRequest("GET", "/api/v1/farm/profile", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr = httptest.NewRecorder()
	handler.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200 for farm profile, got %d", rr.Code)
	}

	// 3. Request Farm Recommendations directly (uses registered farm location automatically)
	req, _ = http.NewRequest("GET", "/api/v1/farm/recommendations", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr = httptest.NewRecorder()
	handler.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200 for farm recommendations, got %d, body: %s", rr.Code, rr.Body.String())
	}

	var recResp map[string]interface{}
	json.Unmarshal(rr.Body.Bytes(), &recResp)
	if _, ok := recResp["rotation_report"]; !ok {
		t.Fatalf("expected rotation_report in response")
	}

	// 4. Request Farm Vulnerability Diagnosis directly for registered farm
	req, _ = http.NewRequest("GET", "/api/v1/farm/vulnerabilities", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr = httptest.NewRecorder()
	handler.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200 for farm vulnerabilities, got %d", rr.Code)
	}

	// 5. Simulate climate perturbation for registered farm
	simPayload := map[string]interface{}{
		"rainfall_anomaly_pct":   -20.0,
		"temperature_increase_c": 1.5,
	}
	simBody, _ := json.Marshal(simPayload)
	req, _ = http.NewRequest("POST", "/api/v1/farm/simulate", bytes.NewBuffer(simBody))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	handler.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200 for farm simulate, got %d", rr.Code)
	}
}

func TestRootHandler(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	req, _ := http.NewRequest("GET", "/", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(rr.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode json: %v", err)
	}
	if resp["project"] != "Kilimo Decision-Support System" {
		t.Errorf("unexpected project name: %v", resp["project"])
	}
}

func TestHealthHandler(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	req, _ := http.NewRequest("GET", "/health", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}
}

func TestRegionsAndCropsEndpoints(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	// Test GET /api/v1/regions
	req, _ := http.NewRequest("GET", "/api/v1/regions", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("regions expected 200, got %d", rr.Code)
	}

	// Test GET /api/v1/crops
	req, _ = http.NewRequest("GET", "/api/v1/crops", nil)
	rr = httptest.NewRecorder()
	handler.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("crops expected 200, got %d", rr.Code)
	}

	// Test GET /api/v1/crops/maize
	req, _ = http.NewRequest("GET", "/api/v1/crops/maize", nil)
	rr = httptest.NewRecorder()
	handler.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("crop maize expected 200, got %d", rr.Code)
	}
}

func TestNASAMetricsInfo(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	req, _ := http.NewRequest("GET", "/api/v1/nasa/metrics-info", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}
}

func TestNASAObservationsHandler(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	payload := map[string]float64{
		"latitude":  -0.3031,
		"longitude": 36.0800,
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/api/v1/nasa/observations", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d, body: %s", rr.Code, rr.Body.String())
	}
}

func TestGorgoniaMLPredictEndpoint(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	payload := map[string]interface{}{
		"crop_id":   "cowpea",
		"latitude":  -0.3031,
		"longitude": 36.0800,
		"region":    "Nakuru",
		"farmer_priorities": map[string]float64{
			"soil_organic_matter": 0.8,
			"water_conservation":  0.9,
			"nitrogen_fixing":     0.9,
		},
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/api/v1/ml/predict-crop-suitability", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d, body: %s", rr.Code, rr.Body.String())
	}

	var resp map[string]interface{}
	json.Unmarshal(rr.Body.Bytes(), &resp)
	if _, ok := resp["prediction"]; !ok {
		t.Fatalf("missing prediction in response")
	}
}

func TestRecommendRotationsEndpoint(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	payload := map[string]interface{}{
		"latitude":         -0.3031,
		"longitude":        36.0800,
		"region":           "Nakuru",
		"current_rotation": []string{"maize", "maize"},
		"farmer_priorities": map[string]float64{
			"soil_organic_matter": 0.9,
			"water_conservation":  0.8,
			"nitrogen_fixing":     0.85,
			"pest_disruption":     0.7,
			"income_market_value": 0.75,
		},
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/api/v1/rotations/recommend", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d, body: %s", rr.Code, rr.Body.String())
	}

	var comparison rotation.StrategyComparison
	if err := json.Unmarshal(rr.Body.Bytes(), &comparison); err != nil {
		t.Fatalf("failed to parse comparison json: %v", err)
	}

	if len(comparison.Strategies) < 3 {
		t.Fatalf("expected at least 3 strategies, got %d", len(comparison.Strategies))
	}
}

func TestSimulateScenariosEndpoint(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	payload := map[string]interface{}{
		"latitude":               -0.3031,
		"longitude":              36.0800,
		"region":                 "Nakuru",
		"current_rotation":       []string{"maize", "maize"},
		"rainfall_anomaly_pct":   -25.0,
		"temperature_increase_c": 2.0,
		"farmer_priorities": map[string]float64{
			"water_conservation": 0.9,
		},
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/api/v1/rotations/simulate", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d, body: %s", rr.Code, rr.Body.String())
	}
}

func TestNASANotificationsEndpoint(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	const latitude = 0.0917
	const longitude = 34.7680
	payload := map[string]interface{}{
		"latitude":  latitude,
		"longitude": longitude,
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/api/v1/nasa/notifications", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d, body: %s", rr.Code, rr.Body.String())
	}

	var resp struct {
		Count         int                       `json:"count"`
		CriticalCount int                       `json:"critical_count"`
		Coordinates   models.FarmLocation       `json:"coordinates"`
		Region        string                    `json:"region"`
		Notifications []models.FarmNotification `json:"notifications"`
	}
	if err := json.Unmarshal(rr.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode notification response: %v", err)
	}

	if resp.Count == 0 {
		t.Fatalf("expected notifications to be generated, got 0")
	}
	if resp.Coordinates.Latitude != latitude || resp.Coordinates.Longitude != longitude {
		t.Fatalf("expected response coordinates %f,%f, got %f,%f", latitude, longitude, resp.Coordinates.Latitude, resp.Coordinates.Longitude)
	}
	if resp.Region == "Nakuru" {
		t.Fatalf("expected coordinate-only request not to use the Nakuru profile")
	}

	hasSatelliteAlert := false
	for _, n := range resp.Notifications {
		if n.Category == "soil" || n.Category == "carbon" {
			t.Fatalf("coordinate-only request returned county-based %s notification", n.Category)
		}
		if strings.Contains(n.Source, "NASA") {
			hasSatelliteAlert = true
			break
		}
	}
	if !hasSatelliteAlert {
		t.Fatalf("expected at least one NASA satellite notification")
	}
}

func TestNASANotificationsRequireFarmCoordinates(t *testing.T) {
	s := setupTestServer()
	handler := s.RegisterRoutes()

	req, _ := http.NewRequest(
		"POST",
		"/api/v1/nasa/notifications",
		strings.NewReader(`{"latitude":0,"longitude":0}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 when farm coordinates are missing, got %d", rr.Code)
	}
}
