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

// NotificationResponse represents the API response for live notifications.
type NotificationResponse struct {
	Count         int                `json:"count"`
	CriticalCount int                `json:"critical_count"`
	Coordinates   FarmLocation       `json:"coordinates"`
	Region        string             `json:"region"`
	DataSource    string             `json:"data_source"`
	Notifications []FarmNotification `json:"notifications"`
}
