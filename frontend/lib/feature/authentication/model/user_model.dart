import 'package:equatable/equatable.dart';

class FarmLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String countyRegion;
  final String? subCountyVillage;
  final double? elevationMeters;

  const FarmLocation({
    required this.latitude,
    required this.longitude,
    required this.countyRegion,
    this.subCountyVillage,
    this.elevationMeters,
  });

  factory FarmLocation.fromJson(Map<String, dynamic> json) {
    return FarmLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      countyRegion: json['county_region'] as String? ?? '',
      subCountyVillage: json['sub_county_village'] as String?,
      elevationMeters: (json['elevation_m'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'county_region': countyRegion,
    };
    if (subCountyVillage != null && subCountyVillage!.isNotEmpty) {
      map['sub_county_village'] = subCountyVillage;
    }
    if (elevationMeters != null) {
      map['elevation_m'] = elevationMeters;
    }
    return map;
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    countyRegion,
    subCountyVillage,
    elevationMeters,
  ];
}

class FarmSoilAttributes extends Equatable {
  final String? mainSoilType;
  final String? soilTexture;
  final double? customPH;
  final double? customOMPct;
  final String? drainageCapacity;

  const FarmSoilAttributes({
    this.mainSoilType,
    this.soilTexture,
    this.customPH,
    this.customOMPct,
    this.drainageCapacity,
  });

  factory FarmSoilAttributes.fromJson(Map<String, dynamic> json) {
    return FarmSoilAttributes(
      mainSoilType: json['main_soil_type'] as String?,
      soilTexture: json['soil_texture'] as String?,
      customPH: (json['custom_ph'] as num?)?.toDouble(),
      customOMPct: (json['custom_om_pct'] as num?)?.toDouble(),
      drainageCapacity: json['drainage_capacity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (mainSoilType != null && mainSoilType!.isNotEmpty) {
      map['main_soil_type'] = mainSoilType;
    }
    if (soilTexture != null && soilTexture!.isNotEmpty) {
      map['soil_texture'] = soilTexture;
    }
    if (customPH != null) {
      map['custom_ph'] = customPH;
    }
    if (customOMPct != null) {
      map['custom_om_pct'] = customOMPct;
    }
    if (drainageCapacity != null && drainageCapacity!.isNotEmpty) {
      map['drainage_capacity'] = drainageCapacity;
    }
    return map;
  }

  @override
  List<Object?> get props => [
    mainSoilType,
    soilTexture,
    customPH,
    customOMPct,
    drainageCapacity,
  ];
}

class FarmerPriorities extends Equatable {
  final double soilOrganicMatter;
  final double waterConservation;
  final double nitrogenFixing;
  final double pestDisruption;
  final double incomeMarketValue;
  final double forageValue;
  final String equipmentType;

  const FarmerPriorities({
    this.soilOrganicMatter = 0.8,
    this.waterConservation = 0.8,
    this.nitrogenFixing = 0.8,
    this.pestDisruption = 0.7,
    this.incomeMarketValue = 0.8,
    this.forageValue = 0.5,
    this.equipmentType = 'Animal Traction',
  });

  factory FarmerPriorities.fromJson(Map<String, dynamic> json) {
    return FarmerPriorities(
      soilOrganicMatter:
          (json['soil_organic_matter'] as num?)?.toDouble() ?? 0.8,
      waterConservation:
          (json['water_conservation'] as num?)?.toDouble() ?? 0.8,
      nitrogenFixing: (json['nitrogen_fixing'] as num?)?.toDouble() ?? 0.8,
      pestDisruption: (json['pest_disruption'] as num?)?.toDouble() ?? 0.7,
      incomeMarketValue:
          (json['income_market_value'] as num?)?.toDouble() ?? 0.8,
      forageValue: (json['forage_value'] as num?)?.toDouble() ?? 0.5,
      equipmentType: json['equipment_type'] as String? ?? 'Animal Traction',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soil_organic_matter': soilOrganicMatter,
      'water_conservation': waterConservation,
      'nitrogen_fixing': nitrogenFixing,
      'pest_disruption': pestDisruption,
      'income_market_value': incomeMarketValue,
      'forage_value': forageValue,
      'equipment_type': equipmentType,
    };
  }

  @override
  List<Object?> get props => [
    soilOrganicMatter,
    waterConservation,
    nitrogenFixing,
    pestDisruption,
    incomeMarketValue,
    forageValue,
    equipmentType,
  ];
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String farmName;
  final double farmSizeAcres;
  final FarmLocation location;
  final FarmSoilAttributes soilAttributes;
  final List<String> currentCropHistory;
  final FarmerPriorities defaultPriorities;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.farmName = '',
    this.farmSizeAcres = 0.0,
    required this.location,
    this.soilAttributes = const FarmSoilAttributes(),
    this.currentCropHistory = const [],
    this.defaultPriorities = const FarmerPriorities(),
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      farmName: json['farm_name'] as String? ?? '',
      farmSizeAcres: (json['farm_size_acres'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] != null
          ? FarmLocation.fromJson(
              Map<String, dynamic>.from(json['location'] as Map),
            )
          : const FarmLocation(latitude: 0, longitude: 0, countyRegion: ''),
      soilAttributes: json['soil_attributes'] != null
          ? FarmSoilAttributes.fromJson(
              Map<String, dynamic>.from(json['soil_attributes'] as Map),
            )
          : const FarmSoilAttributes(),
      currentCropHistory:
          (json['current_crop_history'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      defaultPriorities: json['default_priorities'] != null
          ? FarmerPriorities.fromJson(
              Map<String, dynamic>.from(json['default_priorities'] as Map),
            )
          : const FarmerPriorities(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'farm_name': farmName,
      'farm_size_acres': farmSizeAcres,
      'location': location.toJson(),
      'soil_attributes': soilAttributes.toJson(),
      'current_crop_history': currentCropHistory,
      'default_priorities': defaultPriorities.toJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    farmName,
    farmSizeAcres,
    location,
    soilAttributes,
    currentCropHistory,
    defaultPriorities,
    createdAt,
    updatedAt,
  ];
}

class SignUpPayload {
  final String email;
  final String password;
  final String name;
  final String farmName;
  final double farmSizeAcres;
  final FarmLocation location;
  final FarmSoilAttributes soilAttributes;
  final List<String> currentCropHistory;
  final FarmerPriorities? priorities;

  SignUpPayload({
    required this.email,
    required this.password,
    required this.name,
    required this.farmName,
    required this.farmSizeAcres,
    required this.location,
    required this.soilAttributes,
    this.currentCropHistory = const ['maize'],
    this.priorities,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
      'farm_name': farmName,
      'farm_size_acres': farmSizeAcres,
      'location': location.toJson(),
      'soil_attributes': soilAttributes.toJson(),
      'current_crop_history': currentCropHistory,
    };
    if (priorities != null) {
      map['priorities'] = priorities!.toJson();
    }
    return map;
  }
}

class AuthResponseModel {
  final String token;
  final UserModel farmer;
  final String message;

  const AuthResponseModel({
    required this.token,
    required this.farmer,
    required this.message,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String? ?? '',
      farmer: UserModel.fromJson(
        Map<String, dynamic>.from(json['farmer'] as Map),
      ),
      message: json['message'] as String? ?? '',
    );
  }
}
