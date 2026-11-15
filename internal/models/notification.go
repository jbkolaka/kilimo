package models

import "time"

// FarmNotification represents a real-time satellite alert or agronomic advisory.
type FarmNotification struct {
	ID             string    `json:"id"`
	Title          string    `json:"title"`
	Description    string    `json:"description"`
	Category       string    `json:"category"` // "satellite", "climate", "soil", "irrigation", "carbon"
	Severity       string    `json:"severity"` // "critical", "warning", "info", "success"
	IsCritical     bool      `json:"is_critical"`
	Source         string    `json:"source"` // "NASA SMAP", "NASA ECOSTRESS", "NASA GPM", "NASA MODIS", "Soil Engine"
	MetricValue    string    `json:"metric_value,omitempty"`
	Recommendation string    `json:"recommendation,omitempty"`
	TimeAgo        string    `json:"time_ago"`
	Timestamp      time.Time `json:"timestamp"`
}

// FarmWeatherSummary is the compact weather block the dashboard card renders.
type FarmWeatherSummary struct {
	MeanTempC          float64  `json:"mean_temp_c"`
	MaxTempC           float64  `json:"max_temp_c"`
	MinTempC           float64  `json:"min_temp_c"`
	SoilMoistureM3M3   *float64 `json:"soil_moisture_m3_m3,omitempty"`
	PrecipitationMMDay *float64 `json:"precipitation_mm_day,omitempty"`
	Window             string   `json:"window"`
	Source             string   `json:"source"`
}

// CropTemperatureRisk reports whether one farmer crop sits outside its
// temperature tolerance. Status is "ok", "heat_stress" or "cold_stress".
type CropTemperatureRisk struct {
	Name        string   `json:"name"`
	Status      string   `json:"status"`
	LimitC      *float64 `json:"limit_c,omitempty"`
	ExceedanceC *float64 `json:"exceedance_c,omitempty"`
}

// NotificationResponse represents the API response for live notifications.
type NotificationResponse struct {
	Count         int                   `json:"count"`
	CriticalCount int                   `json:"critical_count"`
	Coordinates   FarmLocation          `json:"coordinates"`
	Region        string                `json:"region"`
	DataSource    string                `json:"data_source"`
	Weather       *FarmWeatherSummary   `json:"weather,omitempty"`
	CropRisk      []CropTemperatureRisk `json:"crop_risk,omitempty"`
	Notifications []FarmNotification    `json:"notifications"`
}
