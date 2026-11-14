import 'package:equatable/equatable.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserModel user;
  final String token;

  const Authenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}
