import '../entities/models.dart';

abstract class TutorialsRepository {
  Future<List<MenuTutorial>> tutorials();
}
