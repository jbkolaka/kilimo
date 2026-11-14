import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mwandu/core/components/line_chart/index.dart';
import 'package:mwandu/core/components/select/index.dart';
import 'package:mwandu/core/services/nasa_service.dart';
import 'package:mwandu/core/shared/styles/colors.style.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/home/widgets/nasa_climate_chart_card.dart';

void main() {
  Widget buildTestableWidget({
    NasaTimeInterval initialInterval = NasaTimeInterval.monthly,
  }) {
    final themeController = AppThemeController(AppThemeMode.gray100);
    return AppThemeScope(
      controller: themeController,
      child: MaterialApp(
        theme: AppTheme.gray100Theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: NasaClimateChartCard(
              latitude: -0.3031,
              longitude: 36.08,
              initialInterval: initialInterval,
              enableAutoFetch: false,
            ),
          ),
        ),
      ),
    );
  }

  group('NasaClimateChartCard & CLineChart Tests', () {
    testWidgets(
      'renders Carbon Line Chart with 3 NASA climate series and header',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget());
        await tester.pump();

        // Verify title & badges
        expect(
          find.text('NASA SATELLITE CLIMATE & SOIL TRENDS'),
          findsOneWidget,
        );
        expect(
          find.text('Multi-Metric 1-Year Agroclimatology'),
          findsOneWidget,
        );

        // Verify Carbon CSelect dropdown exists
        expect(find.byType(CSelect<NasaTimeInterval>), findsOneWidget);
        expect(find.text('Timeframe Granularity'), findsOneWidget);

        // Verify metric summary pills
        expect(find.text('Moisture: '), findsOneWidget);
        expect(find.text('Mean Temp: '), findsOneWidget);
        expect(find.text('Total Precip: '), findsOneWidget);

        // Verify Carbon CLineChart is rendered
        expect(find.byType(CLineChart), findsOneWidget);

        final chart = tester.widget<CLineChart>(find.byType(CLineChart));
        expect(chart.props.series.length, 3);
        expect(chart.props.series[0].name, 'Soil Moisture (%)');
        expect(chart.props.series[0].color, CColors.teal40);
        expect(chart.props.series[1].name, 'Temperature (°C)');
        expect(chart.props.series[1].color, CColors.red50);
        expect(chart.props.series[2].name, 'Precipitation (mm)');
        expect(chart.props.series[2].color, CColors.blue50);

        // Monthly default has 12 points and edge-to-edge padding
        expect(chart.props.series[0].points.length, 12);
        expect(chart.props.xAxisLabels.length, 12);
        expect(chart.props.xAxisLabels.first, 'Jan');
        expect(chart.props.xAxisLabels.last, 'Dec');
        expect(chart.props.removePadding, isTrue);

        // Verify satellite insight text
        expect(find.text('AGRONOMIC SATELLITE INSIGHT'), findsOneWidget);
      },
    );

    testWidgets('toggling numerical breakdown expands DataTable', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // DataTable should initially not be visible
      expect(find.byType(DataTable), findsNothing);

      // Scroll and tap toggle button
      await tester.ensureVisible(find.text('Show Numerical Breakdown'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Numerical Breakdown'));
      await tester.pumpAndSettle();

      // DataTable is now visible
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Hide Numerical Breakdown'), findsOneWidget);
      expect(find.text('Period'), findsOneWidget);
      expect(find.text('Moisture (%)'), findsOneWidget);
      expect(find.text('Temp (°C)'), findsOneWidget);
      expect(find.text('Precip (mm)'), findsOneWidget);

      // Rows for months exist
      expect(find.text('Jan'), findsWidgets);
    });

    testWidgets('renders weekly, daily, and yearly granularities accurately', (
      tester,
    ) async {
      // Weekly test
      await tester.pumpWidget(
        buildTestableWidget(initialInterval: NasaTimeInterval.weekly),
      );
      await tester.pump();

      var chart = tester.widget<CLineChart>(find.byType(CLineChart));
      expect(chart.props.xAxisLabels.first, 'W4');
      expect(chart.props.xAxisLabels.last, 'W48');
      expect(chart.props.xAxisTickIndices, [0, 5, 11]);

      // Daily test with 1-7 and 7-14 duration axis range and zero edge padding
      await tester.pumpWidget(
        buildTestableWidget(initialInterval: NasaTimeInterval.daily),
      );
      await tester.pump();

      chart = tester.widget<CLineChart>(find.byType(CLineChart));
      expect(chart.props.xAxisLabels.first, '1');
      expect(chart.props.xAxisLabels.last, '14');
      expect(chart.props.xAxisTickIndices, [0, 6, 13]); // Marks 1, 7, and 14
      expect(chart.props.removePadding, isTrue);

      // Yearly test
      await tester.pumpWidget(
        buildTestableWidget(initialInterval: NasaTimeInterval.yearly),
      );
      await tester.pump();

      chart = tester.widget<CLineChart>(find.byType(CLineChart));
      expect(chart.props.xAxisLabels, ['2021', '2022', '2023', '2024']);
    });
  });
}
