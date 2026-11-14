import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mwandu/core/components/bottom_app_bar/index.dart';
import 'package:mwandu/core/theme/variables.dart';

void main() {
  group('Carbon CBottomAppBar Widget Tests', () {
    testWidgets('renders all items, labels, and badges accurately', (
      tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        AppThemeScope(
          controller: AppThemeController(AppThemeMode.gray100),
          child: MaterialApp(
            theme: AppTheme.gray100Theme,
            home: Scaffold(
              bottomNavigationBar: StatefulBuilder(
                builder: (context, setState) {
                  return CBottomAppBar(
                    currentIndex: selectedIndex,
                    onTap: (index) {
                      setState(() => selectedIndex = index);
                    },
                    items: const [
                      CBottomAppBarItem(
                        label: 'Home',
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                      ),
                      CBottomAppBarItem(
                        label: 'Notifications',
                        icon: Icon(Icons.notifications_outlined),
                        selectedIcon: Icon(Icons.notifications),
                        badgeCount: 5,
                      ),
                      CBottomAppBarItem(
                        label: 'Settings',
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify labels exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify badge count
      expect(find.text('5'), findsOneWidget);

      // Verify initial selected icon
      expect(find.byIcon(Icons.home), findsOneWidget);

      // Tap on Notifications tab
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);
      expect(find.byIcon(Icons.notifications), findsOneWidget);

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 2);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets(
      'supports fromProps constructor with custom height and labels toggle',
      (tester) async {
        int tappedIndex = -1;

        final props = CBottomAppBarProps(
          height: 56.0,
          showLabels: false,
          currentIndex: 1,
          onTap: (idx) => tappedIndex = idx,
          items: const [
            CBottomAppBarItem(label: 'Home', icon: Icon(Icons.home)),
            CBottomAppBarItem(
              label: 'Notifications',
              icon: Icon(Icons.notifications),
            ),
            CBottomAppBarItem(label: 'Settings', icon: Icon(Icons.settings)),
          ],
        );

        await tester.pumpWidget(
          AppThemeScope(
            controller: AppThemeController(AppThemeMode.white),
            child: MaterialApp(
              theme: AppTheme.whiteTheme,
              home: Scaffold(
                bottomNavigationBar: CBottomAppBar.fromProps(props: props),
              ),
            ),
          ),
        );

        // Labels should be hidden
        expect(find.text('Home'), findsNothing);
        expect(find.text('Notifications'), findsNothing);

        // Tapping Settings tab triggers callback
        await tester.tap(find.byIcon(Icons.settings));
        expect(tappedIndex, 2);
      },
    );
  });
}
