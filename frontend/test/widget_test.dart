import 'package:flutter_test/flutter_test.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';

void main() {
  group('Authentication UserModel and Payloads', () {
    test('UserModel serializes and deserializes correctly', () {
      final json = {
        'id': 'farmer_12345',
        'email': 'farmer@kilimo.ke',
        'name': 'Kiprono Koech',
        'farm_name': 'Rongai Green Farm',
        'farm_size_acres': 12.5,
        'location': {
          'latitude': -0.3031,
          'longitude': 36.0800,
          'county_region': 'Nakuru',
          'sub_county_village': 'Rongai',
          'elevation_m': 1850.0,
        },
        'soil_attributes': {
          'main_soil_type': 'Clay Loam',
          'soil_texture': 'Loamy',
          'custom_ph': 6.2,
          'custom_om_pct': 3.5,
          'drainage_capacity': 'Well-drained',
        },
        'current_crop_history': ['maize', 'beans'],
        'default_priorities': {
          'soil_organic_matter': 0.8,
          'water_conservation': 0.8,
          'nitrogen_fixing': 0.8,
          'pest_disruption': 0.7,
          'income_market_value': 0.8,
          'forage_value': 0.5,
          'equipment_type': 'Animal Traction',
        },
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'farmer_12345');
      expect(user.email, 'farmer@kilimo.ke');
      expect(user.location.countyRegion, 'Nakuru');
      expect(user.soilAttributes.customPH, 6.2);
      expect(user.currentCropHistory, ['maize', 'beans']);

      final serialized = user.toJson();
      expect(serialized['id'], 'farmer_12345');
      expect(serialized['email'], 'farmer@kilimo.ke');
      expect(serialized['farm_name'], 'Rongai Green Farm');
    });

    test('SignUpPayload generates correct payload for backend', () {
      final payload = SignUpPayload(
        name: 'Jane Doe',
        email: 'jane@farm.com',
        password: 'password123',
        farmName: 'Jane Valley',
        farmSizeAcres: 8.0,
        location: const FarmLocation(
          latitude: 0.5143,
          longitude: 35.2698,
          countyRegion: 'Uasin Gishu',
        ),
        soilAttributes: const FarmSoilAttributes(
          mainSoilType: 'Volcanic Loam',
          soilTexture: 'Loamy',
          customPH: 6.5,
        ),
      );

      final json = payload.toJson();
      expect(json['email'], 'jane@farm.com');
      expect(json['name'], 'Jane Doe');
      expect(json['location']['county_region'], 'Uasin Gishu');
      expect(json['soil_attributes']['main_soil_type'], 'Volcanic Loam');
    });
  });
}
