import '../entities/file_version.dart';
abstract class IRecordFileVersionUseCase {
  Future<int> execute(FileVersion version);
}





