package models

import "time"

// FarmerProfile represents a registered farmer with their farm's geospatial and soil profile.
type FarmerProfile struct {
	ID                 string             `json:"id"`
	Email              string             `json:"email"`
	Name               string             `json:"name"`
	FarmName           string             `json:"farm_name"`
	FarmSizeAcres      float64            `json:"farm_size_acres"`
	Location           FarmLocation       `json:"location"`
	SoilPreferences    FarmSoilAttributes `json:"soil_attributes"`
	CurrentCropHistory []string           `json:"current_crop_history"` // e.g. ["maize", "maize"]
	DefaultPriorities  FarmerPriorities   `json:"default_priorities"`
	CreatedAt          time.Time          `json:"created_at"`
	UpdatedAt          time.Time          `json:"updated_at"`
}

type FarmLocation struct {
	Latitude         float64 `json:"latitude"`
	Longitude        float64 `json:"longitude"`
	CountyRegion     string  `json:"county_region"` // e.g. "Nakuru", "Uasin Gishu", "Kisumu"
	SubCountyVillage string  `json:"sub_county_village,omitempty"`
	ElevationMeters  float64 `json:"elevation_m,omitempty"`
}

type FarmSoilAttributes struct {
	MainSoilType     string   `json:"main_soil_type,omitempty"`
	SoilTexture      string   `json:"soil_texture,omitempty"`
	CustomPH         *float64 `json:"custom_ph,omitempty"`
	CustomOMPct      *float64 `json:"custom_om_pct,omitempty"`
	DrainageCapacity string   `json:"drainage_capacity,omitempty"`
}

type FarmerPriorities struct {
	SoilOrganicMatter float64 `json:"soil_organic_matter"`
	WaterConservation float64 `json:"water_conservation"`
	NitrogenFixing    float64 `json:"nitrogen_fixing"`
	PestDisruption    float64 `json:"pest_disruption"`
	IncomeMarketValue float64 `json:"income_market_value"`
	ForageValue       float64 `json:"forage_value"`
	EquipmentType     string  `json:"equipment_type"` // Manual, Animal Traction, Mechanized
}

// SignUpRequest is payload required to register a farmer by farm location.
type SignUpRequest struct {
	Email              string             `json:"email" binding:"required,email"`
	Password           string             `json:"password" binding:"required,min=6"`
	Name               string             `json:"name" binding:"required"`
	FarmName           string             `json:"farm_name"`
	FarmSizeAcres      float64            `json:"farm_size_acres"`
	Location           FarmLocation       `json:"location" binding:"required"`
	SoilAttributes     FarmSoilAttributes `json:"soil_attributes"`
	CurrentCropHistory []string           `json:"current_crop_history"`
	Priorities         *FarmerPriorities  `json:"priorities"`
}

// LoginRequest allows login via email and password.
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse returns the farmer's profile, token, and pre-computed farm baseline.
type AuthResponse struct {
	Token   string        `json:"token"`
	Farmer  FarmerProfile `json:"farmer"`
	Message string        `json:"message"`
}
