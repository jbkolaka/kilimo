package server

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"kilimo/internal/ml"
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

	return &Server{
		port:     8080,
		db:       &mockDB{},
		nasa:     nasaSvc,
		soil:     soilSvc,
		ml:       mlEng,
		rotation: rotSvc,
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
