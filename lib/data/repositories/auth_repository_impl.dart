import '../../domain/entities/models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<SendOtpResult> sendOtp(String phone) => _remote.sendOtp(phone);

  @override
  Future<AuthUser> verifyOtp(String phone, String otp) => _remote.verifyOtp(phone, otp);

  @override
  Future<void> logout() => _remote.logout();

  @override
  Future<AuthUser> me() => _remote.me();

  @override
  Future<AuthUser> updateProfile({required String firstName, required String lastName, required String email}) => _remote.updateProfile(firstName: firstName, lastName: lastName, email: email);

  @override
  Future<AuthUser> uploadAvatar(String path, String filename) => _remote.uploadAvatar(path, filename);
}
