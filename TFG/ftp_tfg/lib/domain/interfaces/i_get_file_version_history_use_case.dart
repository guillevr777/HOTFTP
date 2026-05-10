import '../entities/file_version.dart';
abstract class IGetFileVersionHistoryUseCase {
  Future<List<FileVersion>> execute(
    String ownerId,
    int profileId,
    String filePath, {
    int limit,
  });
}





