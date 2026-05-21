import '../entities/ftp_profile.dart';
import '../entities/system_usage_stats.dart';
import '../entities/sync_record.dart';
abstract class IAnalyzeSystemUsageUseCase {
  SystemUsageStats execute({
    required List<SyncRecord> syncs,
    required List<FtpProfile> profiles,
  });
}





