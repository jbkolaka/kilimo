import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwandu/feature/authentication/bloc/auth_event.dart';
import 'package:mwandu/feature/authentication/bloc/auth_state.dart';
import 'package:mwandu/feature/authentication/repository/auth_repository.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SignInSubmitted>(_onSignInSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final authResult = await _authRepository.checkAuth();
      if (authResult != null) {
        emit(Authenticated(user: authResult.user, token: authResult.token));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignInSubmitted(
    SignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authResult = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user: authResult.user, token: authResult.token));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authResult = await _authRepository.signUp(event.payload);
      emit(Authenticated(user: authResult.user, token: authResult.token));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _authRepository.logout();
    emit(const Unauthenticated());
  }
}
