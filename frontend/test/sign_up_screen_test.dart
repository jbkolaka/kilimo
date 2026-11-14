import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';
import 'package:mwandu/feature/authentication/repository/auth_repository.dart';
import 'package:mwandu/feature/authentication/repository/local_auth_repository.dart';
import 'package:mwandu/feature/authentication/repository/remote_auth_repository.dart';
import 'package:mwandu/feature/authentication/screen/sign_up_screen.dart';

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
  Future<({UserModel user, String token})?> checkAuth() async => null;

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('SignUpScreen pumps and shows first step text field', (
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
            child: const SignUpScreen(enableAutoNasaInit: false),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('What is your full name?'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
