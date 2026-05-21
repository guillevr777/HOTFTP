import '../entities/system_event.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_get_recent_events_use_case.dart';

class GetRecentEvents implements IGetRecentEventsUseCase {
  final MonitoringRepository repository;

  GetRecentEvents(this.repository);

  @override
  Future<List<SystemEvent>> execute(String ownerId, {int limit = 20}) =>
      repository.getRecentEvents(ownerId, limit: limit);
}




