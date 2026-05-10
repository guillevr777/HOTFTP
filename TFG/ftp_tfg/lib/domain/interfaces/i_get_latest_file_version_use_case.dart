import '../entities/file_version.dart';
abstract class IGetLatestFileVersionUseCase {
  Future<FileVersion?> execute(
    String ownerId,
    int profileId,
    String filePath,
  );
}





