import 'package:flutter_test/flutter_test.dart';
import 'package:mwandu/core/services/nasa_service.dart';

void main() {
  group('NasaService & NasaSoilProfile Tests', () {
    test('NasaSoilProfile parses NASA POWER GeoJSON correctly', () {
      final mockData = {
        'geometry': {
          'type': 'Point',
          'coordinates': [36.08, -0.3031, 1850.5],
        },
        'properties': {
          'parameter': {
            'GWETTOP': {'20240101': 0.72},
            'T2M': {'20240101': 19.4},
          },
        },
      };

      final profile = NasaSoilProfile.fromNasaPower(
        lat: -0.3031,
        lon: 36.08,
        data: mockData,
      );

      expect(profile.elevationMeters, 1850.5);
      expect(profile.surfaceWetness, 0.72);
      expect(profile.avgTemp, 19.4);
      expect(profile.soilType, contains('Clay'));
      expect(profile.ph, 6.0);
      expect(profile.dataSource, contains('NASA POWER'));
    });

    test(
      'NasaSoilProfile parses Go backend NASA observations payload correctly',
      () {
        final mockBackendData = {
          'coordinates': {
            'latitude': -0.3031,
            'longitude': 36.08,
            'elevation_m': 1600.0,
          },
          'source': 'NASA_POWER_LIVE',
          'smap_soil_moisture': {
            'surface_soil_moisture_m3_m3': 0.236,
            'infiltration_potential': 'Moderate',
          },
          'nasa_power': {
            't2m_avg_c': {'ANN': 15.64},
          },
        };

        final profile = NasaSoilProfile.fromBackend(
          lat: -0.3031,
          lon: 36.08,
          data: mockBackendData,
        );

        expect(profile.elevationMeters, 1600.0);
        expect(profile.surfaceWetness, 0.236);
        expect(profile.avgTemp, 15.64);
        expect(
          profile.soilType,
          anyOf(contains('Ferralsol'), contains('Loam')),
        );
        expect(profile.drainage, contains('Moderate'));
        expect(profile.dataSource, contains('Backend Synced'));
      },
    );

    test('NasaSoilProfile fallback provides resilient agronomic baseline', () {
      final profile = NasaSoilProfile.fallback(lat: -0.3031, lon: 36.08);

      expect(profile.elevationMeters, greaterThan(1000));
      expect(profile.soilType, isNotEmpty);
      expect(profile.ph, 6.2);
      expect(profile.organicMatterPct, 3.5);
    });

    test('Monthly time series generates canonical month names (Jan..Dec), never 01/01', () {
      final service = NasaService();
      final data = service.getCalibratedTimeSeries(
        interval: NasaTimeInterval.monthly,
      );

      expect(data.xLabels.length, 12);
      expect(data.xLabels.first, 'Jan');
      expect(data.xLabels[1], 'Feb');
      expect(data.xLabels.last, 'Dec');
      expect(data.xLabels.contains('01/01'), isFalse);
      expect(data.xLabels.contains('01/02'), isFalse);
      expect(data.tickIndices, [0, 3, 6, 9, 11]);
    });

    test('Daily time series produces 1..14 with tickIndices [0, 6, 13] for 1-7 and 7-14 range', () {
      final service = NasaService();
      final data = service.getCalibratedTimeSeries(
        interval: NasaTimeInterval.daily,
      );

      expect(data.xLabels.length, 14);
      expect(data.xLabels.first, '1');
      expect(data.xLabels[6], '7');
      expect(data.xLabels.last, '14');
      expect(data.xLabels.contains('01/01'), isFalse);
      expect(data.tickIndices, [0, 6, 13]);
    });
  });
}
