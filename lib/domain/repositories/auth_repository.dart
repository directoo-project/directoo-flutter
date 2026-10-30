import '../entities/models.dart';

abstract class AuthRepository {
  Future<SendOtpResult> sendOtp(String phone);
  Future<AuthUser> verifyOtp(String phone, String otp);
  Future<void> logout();
  Future<AuthUser> me();
  Future<AuthUser> updateProfile({required String firstName, required String lastName, required String email});
  Future<AuthUser> uploadAvatar(String path, String filename);
}
