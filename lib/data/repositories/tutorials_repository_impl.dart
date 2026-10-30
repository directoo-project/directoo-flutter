import '../../domain/entities/models.dart';
import '../../domain/repositories/tutorials_repository.dart';
import '../datasources/tutorials_remote_data_source.dart';

class TutorialsRepositoryImpl implements TutorialsRepository {
  TutorialsRepositoryImpl(this._remote);

  final TutorialsRemoteDataSource _remote;

  @override
  Future<List<MenuTutorial>> tutorials() => _remote.tutorials();
}
