import '../entities/local_file.dart';
abstract class IGetLocalFileDetailsUseCase {
  Future<List<LocalFile>> execute(String path);
}





