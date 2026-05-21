import '../entities/file_version.dart';
abstract class IGetRecentFileVersionsUseCase {
  Future<List<FileVersion>> execute(String ownerId, {int limit});
}





