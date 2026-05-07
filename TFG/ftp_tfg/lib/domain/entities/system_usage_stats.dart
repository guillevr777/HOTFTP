class SystemUsageStats {
  final int totalSyncs;
  final int successfulSyncs;
  final int failedSyncs;
  final double successRate;
  final double averageFilesTransferred;
  final int? peakHour;
  final int peakHourCount;
  final int? topProfileId;
  final String? topProfileName;
  final int topProfileSyncs;

  const SystemUsageStats({
    required this.totalSyncs,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.successRate,
    required this.averageFilesTransferred,
    required this.peakHour,
    required this.peakHourCount,
    required this.topProfileId,
    required this.topProfileName,
    required this.topProfileSyncs,
  });
}
