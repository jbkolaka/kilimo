import 'package:mwandu/feature/authentication/model/user_model.dart';
import 'package:mwandu/feature/authentication/repository/local_auth_repository.dart';
import 'package:mwandu/feature/authentication/repository/remote_auth_repository.dart';

class AuthRepository {
  final RemoteAuthRepository _remoteRepo;
  final LocalAuthRepository _localRepo;

  AuthRepository({
    required RemoteAuthRepository remoteRepo,
    required LocalAuthRepository localRepo,
  }) : _remoteRepo = remoteRepo,
       _localRepo = localRepo;

  LocalAuthRepository get localRepo => _localRepo;
  RemoteAuthRepository get remoteRepo => _remoteRepo;

  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteRepo.login(email: email, password: password);
    await _localRepo.saveToken(response.token);
    await _localRepo.saveUser(response.farmer);
    return (user: response.farmer, token: response.token);
  }

  Future<({UserModel user, String token})> signUp(SignUpPayload payload) async {
    final response = await _remoteRepo.signUp(payload);
    await _localRepo.saveToken(response.token);
    await _localRepo.saveUser(response.farmer);
    return (user: response.farmer, token: response.token);
  }

  Future<({UserModel user, String token})?> checkAuth() async {
    final token = _localRepo.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    // Try reading cached user first
    UserModel? cached = _localRepo.getUser();
    if (cached != null) {
      return (user: cached, token: token);
    }

    try {
      final user = await _remoteRepo.getFarmerProfile(token: token);
      await _localRepo.saveUser(user);
      return (user: user, token: token);
    } catch (_) {
      await _localRepo.clearAuth();
      return null;
    }
  }

  Future<void> logout() async {
    await _localRepo.clearAuth();
  }
}
