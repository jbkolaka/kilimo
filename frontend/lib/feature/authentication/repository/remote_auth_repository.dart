import 'package:dio/dio.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';

class RemoteAuthRepository {
  final Dio _dio;
  static const String defaultBaseUrl =
      'https://kilimo-api-j6ve.onrender.com/api/v1';

  RemoteAuthRepository({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? defaultBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return AuthResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthResponseModel> signUp(SignUpPayload payload) async {
    try {
      final response = await _dio.post('/auth/signup', data: payload.toJson());
      final data = Map<String, dynamic>.from(response.data as Map);
      return AuthResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> getFarmerProfile({required String token}) async {
    try {
      final response = await _dio.get(
        '/farm/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _handleDioError(DioException error) {
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Check your network or backend server.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to backend server at ${_dio.options.baseUrl}.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        return 'Server returned error status: $code.';
      default:
        return error.message ?? 'An unexpected network error occurred.';
    }
  }
}
