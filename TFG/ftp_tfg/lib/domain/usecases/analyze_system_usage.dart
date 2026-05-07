import '../entities/ftp_profile.dart';
import '../entities/system_usage_stats.dart';
import '../entities/sync_record.dart';

class AnalyzeSystemUsage {
  const AnalyzeSystemUsage();

  SystemUsageStats execute({
    required List<SyncRecord> syncs,
    required List<FtpProfile> profiles,
  }) {
    final totalSyncs = syncs.length;
    final successfulSyncs = syncs.where((sync) => sync.errorMessage == null).length;
    final failedSyncs = totalSyncs - successfulSyncs;
    final successRate = totalSyncs == 0 ? 0.0 : successfulSyncs / totalSyncs;
    final averageFilesTransferred = totalSyncs == 0
        ? 0.0
        : syncs.fold<int>(0, (sum, sync) => sum + sync.filesTransferred) /
            totalSyncs;

    final hourCounts = <int, int>{};
    for (final sync in syncs.where((sync) => sync.errorMessage == null)) {
      hourCounts[sync.date.hour] = (hourCounts[sync.date.hour] ?? 0) + 1;
    }
    final peakEntry = hourCounts.entries.fold<MapEntry<int, int>?>(
      null,
      (best, current) {
        if (best == null || current.value > best.value) return current;
        return best;
      },
    );

    final profileCounts = <int, int>{};
    for (final sync in syncs) {
      profileCounts[sync.profileId] = (profileCounts[sync.profileId] ?? 0) + 1;
    }
    final topProfileEntry = profileCounts.entries.fold<MapEntry<int, int>?>(
      null,
      (best, current) {
        if (best == null || current.value > best.value) return current;
        return best;
      },
    );
    FtpProfile? topProfile;
    if (topProfileEntry != null) {
      for (final profile in profiles) {
        if (profile.id == topProfileEntry.key) {
          topProfile = profile;
          break;
        }
      }
    }

    return SystemUsageStats(
      totalSyncs: totalSyncs,
      successfulSyncs: successfulSyncs,
      failedSyncs: failedSyncs,
      successRate: successRate,
      averageFilesTransferred: averageFilesTransferred,
      peakHour: peakEntry?.key,
      peakHourCount: peakEntry?.value ?? 0,
      topProfileId: topProfileEntry?.key,
      topProfileName: topProfile?.name,
      topProfileSyncs: topProfileEntry?.value ?? 0,
    );
  }
}
