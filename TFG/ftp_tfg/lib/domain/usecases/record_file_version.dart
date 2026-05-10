import '../entities/file_version.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_record_file_version_use_case.dart';

class RecordFileVersion implements IRecordFileVersionUseCase {
  final MonitoringRepository repository;

  RecordFileVersion(this.repository);

  @override
  Future<int> execute(FileVersion version) => repository.recordFileVersion(version);
}




