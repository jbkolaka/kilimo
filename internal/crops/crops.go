package crops

import "strings"

// Category represents the agronomic functional group of a crop.
type Category string

const (
	CategoryCereal    Category = "CEREAL_STAPLE"
	CategoryLegume    Category = "LEGUME_NITROGEN_FIXER"
	CategoryCoverCrop Category = "COVER_SOIL_BUILDER"
	CategoryTuber     Category = "DROUGHT_TUBER_DEEP_ROOT"
	CategoryForage    Category = "FORAGE_BIOMASS"
	CategoryOilseed   Category = "OILSEED_CASH"
)

// CropProfile contains comprehensive agronomic, environmental, and economic parameters.
type CropProfile struct {
	ID                      string   `json:"id"`
	CommonName              string   `json:"common_name"`
	ScientificName          string   `json:"scientific_name"`
	Category                Category `json:"category"`
	WaterDemandSeasonMM     float64  `json:"water_demand_season_mm"`
	MinWaterMM              float64  `json:"min_water_mm"`
	TempMinC                float64  `json:"temp_min_c"`
	TempOptC                float64  `json:"temp_opt_c"`
	TempMaxC                float64  `json:"temp_max_c"`
	PHMin                   float64  `json:"ph_min"`
	PHMax                   float64  `json:"ph_max"`
	RootDepthCategory       string   `json:"root_depth_category"` // Shallow, Medium, Deep
	RootDepthMeters         float64  `json:"root_depth_m"`
	NitrogenFixationKgPerHa float64  `json:"nitrogen_fixation_kg_ha"`
	BiomassYieldTonsPerHa   float64  `json:"biomass_yield_tons_ha"`
	ErosionMitigationScore  float64  `json:"erosion_mitigation_score"` // 1-10
	PestFamilyGroup         string   `json:"pest_family_group"`        // Poaceae, Fabaceae, Asteraceae, etc.
	DroughtTolerance        string   `json:"drought_tolerance"`        // Low, Moderate, High, Exceptional
	HeatTolerance           string   `json:"heat_tolerance"`           // Low, Moderate, High, Exceptional
	GrowingDurationDays     int      `json:"growing_duration_days"`
	MarketDemandRating      string   `json:"market_demand_rating"` // High, Moderate, Emerging
	ForageValueRating       string   `json:"forage_value_rating"`  // High, Moderate, Low, None
	SoilHealthBenefits      []string `json:"soil_health_benefits"`
	AgronomicRole           string   `json:"agronomic_role"`
}

var Catalog = map[string]CropProfile{
	"maize": {
		ID:                      "maize",
		CommonName:              "Maize (Corn)",
		ScientificName:          "Zea mays",
		Category:                CategoryCereal,
		WaterDemandSeasonMM:     550,
		MinWaterMM:              400,
		TempMinC:                10,
		TempOptC:                24,
		TempMaxC:                34,
		PHMin:                   5.5,
		PHMax:                   7.2,
		RootDepthCategory:       "Medium",
		RootDepthMeters:         1.0,
		NitrogenFixationKgPerHa: 0,
		BiomassYieldTonsPerHa:   4.5,
		ErosionMitigationScore:  4.0,
		PestFamilyGroup:         "Poaceae",
		DroughtTolerance:        "Moderate",
		HeatTolerance:           "Moderate",
		GrowingDurationDays:     120,
		MarketDemandRating:      "High (Primary Staple)",
		ForageValueRating:       "Moderate (Stover)",
		SoilHealthBenefits:      []string{"Moderate residue cover", "High biomass carbon"},
		AgronomicRole:           "Primary carbohydrate staple and cash crop",
	},
	"common_bean": {
		ID:                      "common_bean",
		CommonName:              "Common Bean",
		ScientificName:          "Phaseolus vulgaris",
		Category:                CategoryLegume,
		WaterDemandSeasonMM:     350,
		MinWaterMM:              280,
		TempMinC:                12,
		TempOptC:                21,
		TempMaxC:                30,
		PHMin:                   5.8,
		PHMax:                   6.8,
		RootDepthCategory:       "Shallow",
		RootDepthMeters:         0.6,
		NitrogenFixationKgPerHa: 45,
		BiomassYieldTonsPerHa:   2.0,
		ErosionMitigationScore:  5.5,
		PestFamilyGroup:         "Fabaceae",
		DroughtTolerance:        "Moderate",
		HeatTolerance:           "Low to Moderate (Heat drops flowers)",
		GrowingDurationDays:     75,
		MarketDemandRating:      "High (Ready Local Cash Market)",
		ForageValueRating:       "Moderate",
		SoilHealthBenefits:      []string{"Fixes 35-50 kg atmospheric N/ha", "Short season allows double cropping"},
		AgronomicRole:           "High-value short-duration protein legume",
	},
	"cowpea": {
		ID:                      "cowpea",
		CommonName:              "Cowpea (Kunde)",
		ScientificName:          "Vigna unguiculata",
		Category:                CategoryLegume,
		WaterDemandSeasonMM:     300,
		MinWaterMM:              220,
		TempMinC:                15,
		TempOptC:                28,
		TempMaxC:                38,
		PHMin:                   5.5,
		PHMax:                   7.8,
		RootDepthCategory:       "Medium",
		RootDepthMeters:         1.2,
		NitrogenFixationKgPerHa: 70,
		BiomassYieldTonsPerHa:   3.5,
		ErosionMitigationScore:  8.0,
		PestFamilyGroup:         "Fabaceae",
		DroughtTolerance:        "High (Thrives in semi-arid heat)",
		HeatTolerance:           "Exceptional",
		GrowingDurationDays:     70,
		MarketDemandRating:      "High (Dual purpose: leafy greens + dry grain)",
		ForageValueRating:       "High (Nutritious fodder)",
		SoilHealthBenefits:      []string{"Dense ground cover suppresses weeds", "Fixes 60-80 kg N/ha", "Shades soil to lower ECOSTRESS LST"},
		AgronomicRole:           "Drought-hardy soil-cooling cover and food crop",
	},
	"pigeon_pea": {
		ID:                      "pigeon_pea",
		CommonName:              "Pigeon Pea (Mbaazi)",
		ScientificName:          "Cajanus cajan",
		Category:                CategoryLegume,
		WaterDemandSeasonMM:     380,
		MinWaterMM:              250,
		TempMinC:                16,
		TempOptC:                26,
		TempMaxC:                36,
		PHMin:                   5.0,
		PHMax:                   7.5,
		RootDepthCategory:       "Deep",
		RootDepthMeters:         2.2,
		NitrogenFixationKgPerHa: 90,
		BiomassYieldTonsPerHa:   5.0,
		ErosionMitigationScore:  7.5,
		PestFamilyGroup:         "Fabaceae",
		DroughtTolerance:        "Exceptional (Deep taproot survives drought)",
		HeatTolerance:           "High",
		GrowingDurationDays:     150,
		MarketDemandRating:      "High (Export & domestic pulse demand)",
		ForageValueRating:       "High (Prunings and leaves)",
		SoilHealthBenefits:      []string{"Deep taproot breaks hardpans & subsoil compaction", "Pumps subsoil phosphorus", "Fixes 80-100 kg N/ha"},
		AgronomicRole:           "Deep-rooting subsoil perforator and nutrient cycler",
	},
	"chickpea": {
		ID:                      "chickpea",
		CommonName:              "Chickpea",
		ScientificName:          "Cicer arietinum",
		Category:                CategoryLegume,
		WaterDemandSeasonMM:     280,
		MinWaterMM:              200,
		TempMinC:                10,
		TempOptC:                22,
		TempMaxC:                32,
		PHMin:                   6.0,
		PHMax:                   8.0,
		RootDepthCategory:       "Medium",
		RootDepthMeters:         1.1,
		NitrogenFixationKgPerHa: 60,
		BiomassYieldTonsPerHa:   2.8,
		ErosionMitigationScore:  6.0,
		PestFamilyGroup:         "Fabaceae",
		DroughtTolerance:        "High (Grows on residual SMAP moisture after main rains)",
		HeatTolerance:           "Moderate",
		GrowingDurationDays:     90,
		MarketDemandRating:      "High (High commercial value per kg)",
		ForageValueRating:       "Moderate",
		SoilHealthBenefits:      []string{"Thrives on residual black cotton (Vertisols) moisture", "Exudates acidify rhizosphere to solubilize locked phosphorus"},
		AgronomicRole:           "Residual moisture post-harvest cash legume",
	},
	"sorghum": {
		ID:                      "sorghum",
		CommonName:              "Sorghum (Mtama)",
		ScientificName:          "Sorghum bicolor",
		Category:                CategoryCereal,
		WaterDemandSeasonMM:     400,
		MinWaterMM:              280,
		TempMinC:                15,
		TempOptC:                28,
		TempMaxC:                40,
		PHMin:                   5.0,
		PHMax:                   8.5,
		RootDepthCategory:       "Deep",
		RootDepthMeters:         1.8,
		NitrogenFixationKgPerHa: 0,
		BiomassYieldTonsPerHa:   6.0,
		ErosionMitigationScore:  7.0,
		PestFamilyGroup:         "Poaceae",
		DroughtTolerance:        "Exceptional (Dormancy during moisture deficit)",
		HeatTolerance:           "Exceptional",
		GrowingDurationDays:     110,
		MarketDemandRating:      "High (Commercial brewing, porridge, poultry feed)",
		ForageValueRating:       "High (Silage & stover)",
		SoilHealthBenefits:      []string{"Extensive fibrous roots prevent rill erosion", "High root biomass increases organic matter"},
		AgronomicRole:           "Climate-resilient grain replacing vulnerable maize in hot dry zones",
	},
	"pearl_millet": {
		ID:                      "pearl_millet",
		CommonName:              "Pearl Millet (Mawele)",
		ScientificName:          "Pennisetum glaucum",
		Category:                CategoryCereal,
		WaterDemandSeasonMM:     250,
		MinWaterMM:              180,
		TempMinC:                18,
		TempOptC:                32,
		TempMaxC:                44,
		PHMin:                   5.0,
		PHMax:                   8.2,
		RootDepthCategory:       "Deep",
		RootDepthMeters:         1.9,
		NitrogenFixationKgPerHa: 0,
		BiomassYieldTonsPerHa:   4.5,
		ErosionMitigationScore:  6.5,
		PestFamilyGroup:         "Poaceae",
		DroughtTolerance:        "Exceptional (Lowest water demand of any major cereal)",
		HeatTolerance:           "Exceptional",
		GrowingDurationDays:     80,
		MarketDemandRating:      "Moderate to High (Health foods & animal feed)",
		ForageValueRating:       "High",
		SoilHealthBenefits:      []string{"Tolerates sandy poor soils with minimal fertilizer", "Rapid ground closure reduces evaporation"},
		AgronomicRole:           "Ultra-drought insurance crop for arid/semi-arid regions",
	},
	"sunn_hemp": {
		ID:                      "sunn_hemp",
		CommonName:              "Sunn Hemp",
		ScientificName:          "Crotalaria juncea",
		Category:                CategoryCoverCrop,
		WaterDemandSeasonMM:     220,
		MinWaterMM:              150,
		TempMinC:                14,
		TempOptC:                27,
		TempMaxC:                38,
		PHMin:                   5.0,
		PHMax:                   8.0,
		RootDepthCategory:       "Deep",
		RootDepthMeters:         1.6,
		NitrogenFixationKgPerHa: 140,
		BiomassYieldTonsPerHa:   7.5,
		ErosionMitigationScore:  9.5,
		PestFamilyGroup:         "Fabaceae",
		DroughtTolerance:        "High",
		HeatTolerance:           "High",
		GrowingDurationDays:     60,
		MarketDemandRating:      "Moderate (Cover crop seed & fiber)",
		ForageValueRating:       "High (High protein ruminant feed)",
		SoilHealthBenefits:      []string{"Rapid biomass suppresses root-knot nematodes", "Fixes 120-160 kg N/ha in 60 days", "Completely protects bare soil between seasons"},
		AgronomicRole:           "Ultimate bio-fumigant, nematode suppressor, and nitrogen builder",
	},
	"velvet_bean": {
		ID:                      "velvet_bean",
		CommonName:              "Mucuna (Velvet Bean)",
		ScientificName:          "Mucuna pruriens",
		Category:                CategoryCoverCrop,
		WaterDemandSeasonMM:     350,
		MinWaterMM:              250,
		TempMinC:                15,
		TempOptC:                26,
		TempMaxC:                36,
		PHMin:                   4.8,
		PHMax:                   7.5,
		RootDepthCategory:       "Medium",
		RootDepthMeters:         1.2,
		NitrogenFixationKgPerHa: 150,
		BiomassYieldTonsPerHa:   8.0,
		ErosionMitigationScore:  9.8,
		PestFamilyGroup:         "Fabaceae",
		DroughtTolerance:        "High",
		HeatTolerance:           "High",
		GrowingDurationDays:     110,
		MarketDemandRating:      "Moderate (Seed & high-protein livestock feed)",
		ForageValueRating:       "High",
		SoilHealthBenefits:      []string{"Smothers perennial weeds (Couch grass, Striga)", "Adds 8t/ha organic dry matter", "Cools soil surface and holds water"},
		AgronomicRole:           "Weed-smothering living mulch and organic matter factory",
	},
	"cassava": {
		ID:                      "cassava",
		CommonName:              "Cassava",
		ScientificName:          "Manihot esculenta",
		Category:                CategoryTuber,
		WaterDemandSeasonMM:     450,
		MinWaterMM:              300,
		TempMinC:                16,
		TempOptC:                28,
		TempMaxC:                38,
		PHMin:                   4.5,
		PHMax:                   8.0,
		RootDepthCategory:       "Deep",
		RootDepthMeters:         1.8,
		NitrogenFixationKgPerHa: 0,
		BiomassYieldTonsPerHa:   6.5,
		ErosionMitigationScore:  7.0,
		PestFamilyGroup:         "Euphorbiaceae",
		DroughtTolerance:        "Exceptional (Leaves shed during severe drought, resprouts with rain)",
		HeatTolerance:           "High",
		GrowingDurationDays:     240,
		MarketDemandRating:      "High (Industrial starch, flour, local food security)",
		ForageValueRating:       "Moderate (Leaves provide protein)",
		SoilHealthBenefits:      []string{"Breaks pest cycles of Poaceae & Fabaceae", "Thrives in highly acidic, degraded soils"},
		AgronomicRole:           "Perennial drought shock absorber and pest cycle disrupter",
	},
	"sweet_potato": {
		ID:                      "sweet_potato",
		CommonName:              "Orange-Fleshed Sweet Potato",
		ScientificName:          "Ipomoea batatas",
		Category:                CategoryTuber,
		WaterDemandSeasonMM:     380,
		MinWaterMM:              260,
		TempMinC:                15,
		TempOptC:                25,
		TempMaxC:                34,
		PHMin:                   5.2,
		PHMax:                   6.8,
		RootDepthCategory:       "Medium",
		RootDepthMeters:         1.0,
		NitrogenFixationKgPerHa: 0,
		BiomassYieldTonsPerHa:   5.0,
		ErosionMitigationScore:  8.5,
		PestFamilyGroup:         "Convolvulaceae",
		DroughtTolerance:        "Moderate to High",
		HeatTolerance:           "Moderate to High",
		GrowingDurationDays:     105,
		MarketDemandRating:      "High (High local urban market value)",
		ForageValueRating:       "High (Vines are premier dairy feed)",
		SoilHealthBenefits:      []string{"Rapid ground-hugging canopy intercepts raindrop impact", "Leaves conserve soil moisture"},
		AgronomicRole:           "Short-season high-nutrition ground cover and cash crop",
	},
	"sunflower": {
		ID:                      "sunflower",
		CommonName:              "Sunflower",
		ScientificName:          "Helianthus annuus",
		Category:                CategoryOilseed,
		WaterDemandSeasonMM:     380,
		MinWaterMM:              250,
		TempMinC:                10,
		TempOptC:                25,
		TempMaxC:                35,
		PHMin:                   6.0,
		PHMax:                   7.5,
		RootDepthCategory:       "Deep",
		RootDepthMeters:         2.0,
		NitrogenFixationKgPerHa: 0,
		BiomassYieldTonsPerHa:   4.0,
		ErosionMitigationScore:  6.0,
		PestFamilyGroup:         "Asteraceae",
		DroughtTolerance:        "High (Deep taproot scavenges deep soil water)",
		HeatTolerance:           "High",
		GrowingDurationDays:     95,
		MarketDemandRating:      "High (Edible oil processors)",
		ForageValueRating:       "Moderate (Sunflower seed cake)",
		SoilHealthBenefits:      []string{"Draws subsoil moisture inaccessible to shallow crops", "Completely unrelated to cereal/legume pests"},
		AgronomicRole:           "High cash return oilseed and soil structure aerator",
	},
	"rhodes_grass": {
		ID:                      "rhodes_grass",
		CommonName:              "Rhodes Grass",
		ScientificName:          "Chloris gayana",
		Category:                CategoryForage,
		WaterDemandSeasonMM:     450,
		MinWaterMM:              300,
		TempMinC:                12,
		TempOptC:                26,
		TempMaxC:                38,
		PHMin:                   5.5,
		PHMax:                   8.5,
		RootDepthCategory:       "Deep",
		RootDepthMeters:         2.5,
		NitrogenFixationKgPerHa: 0,
		BiomassYieldTonsPerHa:   9.0,
		ErosionMitigationScore:  10.0,
		PestFamilyGroup:         "Poaceae",
		DroughtTolerance:        "High",
		HeatTolerance:           "High",
		GrowingDurationDays:     180,
		MarketDemandRating:      "High (Commercial hay baling for dairy farmers)",
		ForageValueRating:       "Exceptional (Premium livestock forage)",
		SoilHealthBenefits:      []string{"Dense sod stops 100% of soil erosion", "Massive root network rebuilds soil aggregate stability and organic carbon"},
		AgronomicRole:           "Multi-year soil rebuilder, pasture hay producer, and erosion stopper",
	},
}

// GetAllCrops returns a slice of all crops in the agronomic catalog.
func GetAllCrops() []CropProfile {
	list := make([]CropProfile, 0, len(Catalog))
	for _, c := range Catalog {
		list = append(list, c)
	}
	return list
}

// GetCrop retrieves a crop by id or common name.
func GetCrop(id string) (CropProfile, bool) {
	c, ok := Catalog[id]
	return c, ok
}

// GetCropByName resolves a free-text crop name typed by a farmer (for example
// "maize", "Maize (Corn)", "beans" or "Kunde") to a catalog profile.
func GetCropByName(name string) (CropProfile, bool) {
	cleaned := strings.TrimSpace(strings.ToLower(name))
	if cleaned == "" {
		return CropProfile{}, false
	}
	if i := strings.Index(cleaned, "("); i > 0 {
		cleaned = strings.TrimSpace(cleaned[:i])
	}

	key := strings.ReplaceAll(cleaned, " ", "_")
	if c, ok := Catalog[key]; ok {
		return c, true
	}

	aliases := map[string]string{
		"bean":   "common_bean",
		"beans":  "common_bean",
		"corn":   "maize",
		"kunde":  "cowpea",
		"mbaazi": "pigeon_pea",
		"mtama":  "sorghum",
		"mawele": "pearl_millet",
		"mucuna": "velvet_bean",
	}
	if id, ok := aliases[key]; ok {
		return Catalog[id], true
	}

	for _, c := range Catalog {
		common := strings.ToLower(c.CommonName)
		if i := strings.Index(common, "("); i > 0 {
			common = strings.TrimSpace(common[:i])
		}
		if common == cleaned || strings.HasPrefix(common, cleaned) {
			return c, true
		}
	}

	return CropProfile{}, false
}
