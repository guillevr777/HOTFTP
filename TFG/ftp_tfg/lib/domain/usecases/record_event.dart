import '../entities/system_event.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_record_event_use_case.dart';

class RecordEvent implements IRecordEventUseCase {
  final MonitoringRepository repository;

  RecordEvent(this.repository);

  @override
  Future<void> execute(SystemEvent event) => repository.recordEvent(event);
}




