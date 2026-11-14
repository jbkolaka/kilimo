import 'package:equatable/equatable.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class SignInSubmitted extends AuthEvent {
  final String email;
  final String password;

  const SignInSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpSubmitted extends AuthEvent {
  final SignUpPayload payload;

  const SignUpSubmitted(this.payload);

  @override
  List<Object?> get props => [payload];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
