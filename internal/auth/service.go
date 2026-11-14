package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strings"
	"sync"
	"time"

	"kilimo/internal/models"
	"kilimo/internal/soil"
)

var (
	ErrUserAlreadyExists  = errors.New("a farmer account with this email already exists")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrFarmerNotFound     = errors.New("farmer not found")
	ErrInvalidLocation    = errors.New("invalid farm location coordinates or region")
)

type UserRecord struct {
	Profile      models.FarmerProfile
	PasswordHash string
	Salt         string
}

// Service manages farmer registration, authentication, and farm profile retrieval.
type Service struct {
	mu          sync.RWMutex
	users       map[string]*UserRecord // keyed by email
	usersByID   map[string]*UserRecord // keyed by user ID
	sessions    map[string]string      // token -> user ID
	soilService *soil.Service
}

func NewService(soilSvc *soil.Service) *Service {
	return &Service{
		users:       make(map[string]*UserRecord),
		usersByID:   make(map[string]*UserRecord),
		sessions:    make(map[string]string),
		soilService: soilSvc,
	}
}

// hashPassword produces a SHA256 hex digest with salt.
func hashPassword(password, salt string) string {
	h := sha256.New()
	h.Write([]byte(password + ":" + salt))
	return hex.EncodeToString(h.Sum(nil))
}

func generateRandomHex(n int) string {
	b := make([]byte, n)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// SignUp registers a farmer bound to their farm's geospatial coordinates and regional soil.
func (s *Service) SignUp(req models.SignUpRequest) (*models.FarmerProfile, string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	emailNorm := strings.ToLower(strings.TrimSpace(req.Email))
	if _, exists := s.users[emailNorm]; exists {
		return nil, "", ErrUserAlreadyExists
	}

	// Geocode default coordinates if region given but coordinates are 0
	loc := req.Location
	if loc.Latitude == 0 && loc.Longitude == 0 {
		coords := defaultCoordsForRegion(loc.CountyRegion)
		loc.Latitude = coords.lat
		loc.Longitude = coords.lon
	}

	// Auto-fill soil attributes from local regional dataset if not explicitly customized
	soilAttrs := req.SoilAttributes
	if s.soilService != nil {
		sp, found := s.soilService.GetProfile(loc.CountyRegion)
		if found {
			if soilAttrs.MainSoilType == "" {
				soilAttrs.MainSoilType = sp.MainSoilType
			}
			if soilAttrs.SoilTexture == "" {
				soilAttrs.SoilTexture = sp.SoilTexture
			}
			if soilAttrs.DrainageCapacity == "" {
				soilAttrs.DrainageCapacity = sp.DrainageCapacity
			}
			if soilAttrs.CustomPH == nil {
				ph := sp.AveragePH
				soilAttrs.CustomPH = &ph
			}
			if soilAttrs.CustomOMPct == nil {
				om := sp.OrganicMatterPct
				soilAttrs.CustomOMPct = &om
			}
		}
	}

	priorities := models.FarmerPriorities{
		SoilOrganicMatter: 0.8,
		WaterConservation: 0.8,
		NitrogenFixing:    0.8,
		PestDisruption:    0.7,
		IncomeMarketValue: 0.8,
		EquipmentType:     "Animal Traction",
	}
	if req.Priorities != nil {
		priorities = *req.Priorities
	}

	cropsHistory := req.CurrentCropHistory
	if len(cropsHistory) == 0 {
		cropsHistory = []string{"maize", "maize"}
	}

	farmerID := "farmer_" + generateRandomHex(8)
	salt := generateRandomHex(16)
	pwdHash := hashPassword(req.Password, salt)

	profile := models.FarmerProfile{
		ID:                 farmerID,
		Email:              emailNorm,
		Name:               req.Name,
		FarmName:           req.FarmName,
		FarmSizeAcres:      req.FarmSizeAcres,
		Location:           loc,
		SoilPreferences:    soilAttrs,
		CurrentCropHistory: cropsHistory,
		DefaultPriorities:  priorities,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	rec := &UserRecord{
		Profile:      profile,
		PasswordHash: pwdHash,
		Salt:         salt,
	}

	s.users[emailNorm] = rec
	s.usersByID[farmerID] = rec

	token := "kilimo_session_" + generateRandomHex(24)
	s.sessions[token] = farmerID

	return &profile, token, nil
}

// Login authenticates a farmer and generates a session token.
func (s *Service) Login(req models.LoginRequest) (*models.FarmerProfile, string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	emailNorm := strings.ToLower(strings.TrimSpace(req.Email))
	rec, exists := s.users[emailNorm]
	if !exists {
		return nil, "", ErrInvalidCredentials
	}

	expectedHash := hashPassword(req.Password, rec.Salt)
	if rec.PasswordHash != expectedHash {
		return nil, "", ErrInvalidCredentials
	}

	token := "kilimo_session_" + generateRandomHex(24)
	s.sessions[token] = rec.Profile.ID

	return &rec.Profile, token, nil
}

// AuthenticateToken verifies the session token and retrieves the farmer profile.
func (s *Service) AuthenticateToken(token string) (*models.FarmerProfile, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	farmerID, ok := s.sessions[token]
	if !ok {
		return nil, errors.New("unauthorized or expired session")
	}

	rec, ok := s.usersByID[farmerID]
	if !ok {
		return nil, ErrFarmerNotFound
	}

	return &rec.Profile, nil
}

// GetFarmerByID retrieves profile by ID.
func (s *Service) GetFarmerByID(id string) (*models.FarmerProfile, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	rec, ok := s.usersByID[id]
	if !ok {
		return nil, ErrFarmerNotFound
	}
	return &rec.Profile, nil
}

// UpdateFarmLocation updates farm boundaries and location coordinates.
func (s *Service) UpdateFarmLocation(farmerID string, loc models.FarmLocation, soilAttrs *models.FarmSoilAttributes) (*models.FarmerProfile, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.usersByID[farmerID]
	if !ok {
		return nil, ErrFarmerNotFound
	}

	rec.Profile.Location = loc
	if soilAttrs != nil {
		rec.Profile.SoilPreferences = *soilAttrs
	}
	rec.Profile.UpdatedAt = time.Now()

	return &rec.Profile, nil
}

type coord struct {
	lat float64
	lon float64
}

func defaultCoordsForRegion(region string) coord {
	switch strings.ToLower(strings.TrimSpace(region)) {
	case "nakuru":
		return coord{lat: -0.3031, lon: 36.0800}
	case "uasin gishu", "eldoret", "uasin gishu (eldoret)":
		return coord{lat: 0.5143, lon: 35.2698}
	case "kisumu":
		return coord{lat: -0.0917, lon: 34.7680}
	case "kakamega":
		return coord{lat: 0.2827, lon: 34.7519}
	case "nyeri":
		return coord{lat: -0.4244, lon: 36.9517}
	case "mombasa":
		return coord{lat: -4.0435, lon: 39.6682}
	case "narok":
		return coord{lat: -1.0833, lon: 35.8667}
	case "marsabit":
		return coord{lat: 2.3333, lon: 37.9833}
	case "wajir":
		return coord{lat: 1.7500, lon: 40.0500}
	case "nairobi":
		return coord{lat: -1.2921, lon: 36.8219}
	default:
		return coord{lat: -0.3031, lon: 36.0800}
	}
}
