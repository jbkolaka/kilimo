import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';
import 'package:mwandu/feature/authentication/repository/auth_repository.dart';
import 'package:mwandu/feature/authentication/repository/local_auth_repository.dart';
import 'package:mwandu/feature/authentication/repository/remote_auth_repository.dart';
import 'package:mwandu/feature/home/home_screen.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  LocalAuthRepository get localRepo => throw UnimplementedError();

  @override
  RemoteAuthRepository get remoteRepo => throw UnimplementedError();

  @override
  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<({UserModel user, String token})> signUp(
    SignUpPayload payload,
  ) async => throw UnimplementedError();

  @override
  Future<({UserModel user, String token})?> checkAuth() async => (
    user: const UserModel(
      id: '123',
      email: 'test@farm.com',
      name: 'Test Farmer',
      farmName: 'Test Green Farm',
      farmSizeAcres: 5.0,
      location: FarmLocation(
        latitude: -0.3031,
        longitude: 36.08,
        countyRegion: 'Nakuru',
      ),
      soilAttributes: FarmSoilAttributes(),
      currentCropHistory: ['maize'],
      defaultPriorities: FarmerPriorities(),
    ),
    token: 'fake_token',
  );

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('HomeScreen has no back button and no sign out icon on AppBar', (
    tester,
  ) async {
    final themeController = AppThemeController(AppThemeMode.gray100);

    await tester.pumpWidget(
      AppThemeScope(
        controller: themeController,
        child: MaterialApp(
          theme: AppTheme.gray100Theme,
          home: BlocProvider(
            create: (context) => AuthBloc(authRepository: FakeAuthRepository()),
            child: const HomeScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify AppBar title is present
    expect(find.text('Kilimo Farm Dashboard'), findsOneWidget);

    // Verify back button is NOT present in AppBar
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    // Verify sign out logout icon is NOT present on AppBar
    expect(find.byIcon(Icons.logout_rounded), findsNothing);

    // Verify PopScope with canPop false is present
    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
  });
}
