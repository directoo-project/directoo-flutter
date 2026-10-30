import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/json.dart';
import '../../domain/entities/models.dart';

abstract class AuthRemoteDataSource {
  Future<SendOtpResult> sendOtp(String phone);
  Future<AuthUser> verifyOtp(String phone, String otp);
  Future<void> logout();
  Future<AuthUser> me();
  Future<AuthUser> updateProfile({required String firstName, required String lastName, required String email});
  Future<AuthUser> uploadAvatar(String path, String filename);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<SendOtpResult> sendOtp(String phone) {
      return _client.post('/api/v1/auth/send-otp/', data: {'phone': phone}, parse: (data) => SendOtpResult.fromJson(asJson(data)));
    }

  @override
  Future<AuthUser> verifyOtp(String phone, String otp) async {
      final data = await _client.post<Json>('/api/v1/auth/verify-otp/', data: {'phone': phone, 'otp': otp}, parse: asJson);
      final access = asString(data['access']);
      final refresh = asString(data['refresh']);
      await _client.tokens.save(access, refresh);
      return AuthUser.fromJson(asJson(data['user']));
    }

  @override
  Future<void> logout() async {
      final refresh = _client.tokens.refresh;
      try {
        if (refresh != null && refresh.isNotEmpty) {
          await _client.post('/api/v1/auth/logout/', auth: true, data: {'refresh': refresh});
        }
      } finally {
        await _client.tokens.clear();
      }
    }

  @override
  Future<AuthUser> me() => _client.get('/api/v1/auth/me/', auth: true, parse: (data) => AuthUser.fromJson(asJson(data)));

  @override
  Future<AuthUser> updateProfile({required String firstName, required String lastName, required String email}) {
      return _client.patch(
        '/api/v1/auth/profile/',
        auth: true,
        data: {'first_name': firstName, 'last_name': lastName, 'email': email},
        parse: (data) => AuthUser.fromJson(asJson(data)),
      );
    }

  @override
  Future<AuthUser> uploadAvatar(String path, String filename) async {
      final form = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(path, filename: filename),
      });
      final data = await _client.post<Json>('/api/v1/auth/profile/avatar/', auth: true, data: form, parse: asJson);
      return AuthUser.fromJson(asJson(data['user']));
    }
}
