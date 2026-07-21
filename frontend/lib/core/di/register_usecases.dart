import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../domain/interfaces/i_acknowledge_alert_use_case.dart';
import '../../domain/interfaces/i_analyze_system_usage_use_case.dart';
import '../../domain/interfaces/i_build_system_health_report_use_case.dart';
import '../../domain/interfaces/i_create_alert_use_case.dart';
import '../../domain/interfaces/i_delete_local_file_use_case.dart';
import '../../domain/interfaces/i_delete_profile_use_case.dart';
import '../../domain/interfaces/i_delete_remote_file_use_case.dart';
import '../../domain/interfaces/i_detect_conflicts_use_case.dart';
import '../../domain/interfaces/i_download_file_use_case.dart';
import '../../domain/interfaces/i_download_thumbnail_use_case.dart';
import '../../domain/interfaces/i_evaluate_sync_rules_use_case.dart';
import '../../domain/interfaces/i_generate_system_recommendations_use_case.dart';
import '../../domain/interfaces/i_get_active_alerts_use_case.dart';
import '../../domain/interfaces/i_get_dump_schedule_for_profile_use_case.dart';
import '../../domain/interfaces/i_get_file_version_history_use_case.dart';
import '../../domain/interfaces/i_get_health_summary_use_case.dart';
import '../../domain/interfaces/i_get_latest_file_version_use_case.dart';
import '../../domain/interfaces/i_get_local_file_details_use_case.dart';
import '../../domain/interfaces/i_get_local_files_use_case.dart';
import '../../domain/interfaces/i_get_profiles_use_case.dart';
import '../../domain/interfaces/i_get_recent_events_use_case.dart';
import '../../domain/interfaces/i_get_recent_file_versions_use_case.dart';
import '../../domain/interfaces/i_get_recent_syncs_use_case.dart';
import '../../domain/interfaces/i_get_remote_files_use_case.dart';
import '../../domain/interfaces/i_get_sync_history_use_case.dart';
import '../../domain/interfaces/i_link_email_password_use_case.dart';
import '../../domain/interfaces/i_login_user_use_case.dart';
import '../../domain/interfaces/i_logout_user_use_case.dart';
import '../../domain/interfaces/i_observe_auth_state_use_case.dart';
import '../../domain/interfaces/i_record_event_use_case.dart';
import '../../domain/interfaces/i_record_file_version_use_case.dart';
import '../../domain/interfaces/i_register_user_use_case.dart';
import '../../domain/interfaces/i_request_password_reset_use_case.dart';
import '../../domain/interfaces/i_restore_session_use_case.dart';
import '../../domain/interfaces/i_save_dump_schedule_use_case.dart';
import '../../domain/interfaces/i_save_profile_use_case.dart';
import '../../domain/interfaces/i_save_sync_record_use_case.dart';
import '../../domain/interfaces/i_sign_in_with_google_use_case.dart';
import '../../domain/interfaces/i_test_connection_use_case.dart';
import '../../domain/interfaces/i_update_display_name_use_case.dart';
import '../../domain/interfaces/i_upload_file_use_case.dart';
import '../../domain/usecases/acknowledge_alert.dart';
import '../../domain/usecases/analyze_system_usage.dart';
import '../../domain/usecases/build_system_health_report.dart';
import '../../domain/usecases/create_alert.dart';
import '../../domain/usecases/delete_local_file.dart';
import '../../domain/usecases/delete_profile.dart';
import '../../domain/usecases/delete_remote_file.dart';
import '../../domain/usecases/detect_conflicts.dart';
import '../../domain/usecases/download_file.dart';
import '../../domain/usecases/download_thumbnail.dart';
import '../../domain/usecases/evaluate_sync_rules.dart';
import '../../domain/usecases/generate_system_recommendations.dart';
import '../../domain/usecases/get_active_alerts.dart';
import '../../domain/usecases/get_dump_schedule_for_profile.dart';
import '../../domain/usecases/get_file_version_history.dart';
import '../../domain/usecases/get_health_summary.dart';
import '../../domain/usecases/get_latest_file_version.dart';
import '../../domain/usecases/get_local_files.dart';
import '../../domain/usecases/get_profiles.dart';
import '../../domain/usecases/get_recent_events.dart';
import '../../domain/usecases/get_recent_file_versions.dart';
import '../../domain/usecases/get_recent_syncs.dart';
import '../../domain/usecases/get_remote_files.dart';
import '../../domain/usecases/get_sync_history.dart';
import '../../domain/usecases/record_event.dart';
import '../../domain/usecases/record_file_version.dart';
import '../../domain/usecases/save_dump_schedule.dart';
import '../../domain/usecases/save_profile.dart';
import '../../domain/usecases/save_sync_record.dart';
import '../../domain/usecases/test_connection.dart';
import '../../domain/usecases/upload_file.dart';
import '../../domain/usecases/auth/link_email_password.dart';
import '../../domain/usecases/auth/login_user.dart';
import '../../domain/usecases/auth/logout_user.dart';
import '../../domain/usecases/auth/observe_auth_state.dart';
import '../../domain/usecases/auth/register_user.dart';
import '../../domain/usecases/auth/request_password_reset.dart';
import '../../domain/usecases/auth/restore_session.dart';
import '../../domain/usecases/auth/sign_in_with_google.dart';
import '../../domain/usecases/auth/update_display_name.dart';
import 'register_repositories.dart';

class AppUseCases {
  final ILoginUserUseCase loginUser;
  final IRegisterUserUseCase registerUser;
  final ISignInWithGoogleUseCase signInWithGoogle;
  final ILogoutUserUseCase logoutUser;
  final IRestoreSessionUseCase restoreSession;
  final IObserveAuthStateUseCase observeAuthState;
  final ILinkEmailPasswordUseCase linkEmailPassword;
  final IRequestPasswordResetUseCase requestPasswordReset;
  final IUpdateDisplayNameUseCase updateDisplayName;
  final IEvaluateSyncRulesUseCase evaluateSyncRules;
  final IBuildSystemHealthReportUseCase buildSystemHealthReport;
  final IGenerateSystemRecommendationsUseCase generateSystemRecommendations;
  final IAnalyzeSystemUsageUseCase analyzeSystemUsage;
  final IGetProfilesUseCase getProfiles;
  final ISaveProfileUseCase saveProfile;
  final IDeleteProfileUseCase deleteProfile;
  final IDeleteRemoteFileUseCase deleteRemoteFile;
  final IDeleteLocalFileUseCase deleteLocalFile;
  final ITestConnectionUseCase testConnection;
  final IGetRemoteFilesUseCase getRemoteFiles;
  final IGetLocalFilesUseCase getLocalFiles;
  final IUploadFileUseCase uploadFile;
  final IDownloadFileUseCase downloadFile;
  final IDownloadThumbnailUseCase downloadThumbnail;
  final IDetectConflictsUseCase detectConflicts;
  final IGetSyncHistoryUseCase getSyncHistory;
  final ISaveSyncRecordUseCase saveSyncRecord;
  final IGetDumpScheduleForProfileUseCase getDumpScheduleForProfile;
  final ISaveDumpScheduleUseCase saveDumpSchedule;
  final IGetFileVersionHistoryUseCase getFileVersionHistory;
  final IGetLatestFileVersionUseCase getLatestFileVersion;
  final IGetLocalFileDetailsUseCase getLocalFileDetails;
  final IRecordFileVersionUseCase recordFileVersion;
  final IGetHealthSummaryUseCase getHealthSummary;
  final IGetRecentEventsUseCase getRecentEvents;
  final IGetActiveAlertsUseCase getActiveAlerts;
  final IGetRecentSyncsUseCase getRecentSyncs;
  final IGetRecentFileVersionsUseCase getRecentFileVersions;
  final IAcknowledgeAlertUseCase acknowledgeAlert;
  final IRecordEventUseCase recordEvent;
  final ICreateAlertUseCase createAlert;

  AppUseCases({
    required this.loginUser,
    required this.registerUser,
    required this.signInWithGoogle,
    required this.logoutUser,
    required this.restoreSession,
    required this.observeAuthState,
    required this.linkEmailPassword,
    required this.requestPasswordReset,
    required this.updateDisplayName,
    required this.evaluateSyncRules,
    required this.buildSystemHealthReport,
    required this.generateSystemRecommendations,
    required this.analyzeSystemUsage,
    required this.getProfiles,
    required this.saveProfile,
    required this.deleteProfile,
    required this.deleteRemoteFile,
    required this.deleteLocalFile,
    required this.testConnection,
    required this.getRemoteFiles,
    required this.getLocalFiles,
    required this.uploadFile,
    required this.downloadFile,
    required this.downloadThumbnail,
    required this.detectConflicts,
    required this.getSyncHistory,
    required this.saveSyncRecord,
    required this.getDumpScheduleForProfile,
    required this.saveDumpSchedule,
    required this.getFileVersionHistory,
    required this.getLatestFileVersion,
    required this.getLocalFileDetails,
    required this.recordFileVersion,
    required this.getHealthSummary,
    required this.getRecentEvents,
    required this.getActiveAlerts,
    required this.getRecentSyncs,
    required this.getRecentFileVersions,
    required this.acknowledgeAlert,
    required this.recordEvent,
    required this.createAlert,
  });
}

AppUseCases createUseCases(AppRepositories repositories) {
  final authRepository = repositories.authRepository;
  final ftpRepository = repositories.ftpRepository;
  final monitoringRepository = repositories.monitoringRepository;

  return AppUseCases(
    loginUser: LoginUser(authRepository),
    registerUser: RegisterUser(authRepository),
    signInWithGoogle: SignInWithGoogle(authRepository),
    logoutUser: LogoutUser(authRepository),
    restoreSession: RestoreSession(authRepository),
    observeAuthState: ObserveAuthState(authRepository),
    linkEmailPassword: LinkEmailPassword(authRepository),
    requestPasswordReset: RequestPasswordReset(authRepository),
    updateDisplayName: UpdateDisplayName(authRepository),
    evaluateSyncRules: const EvaluateSyncRules(),
    buildSystemHealthReport: const BuildSystemHealthReport(),
    generateSystemRecommendations: const GenerateSystemRecommendations(),
    analyzeSystemUsage: const AnalyzeSystemUsage(),
    getProfiles: GetProfiles(ftpRepository),
    saveProfile: SaveProfile(ftpRepository),
    deleteProfile: DeleteProfile(ftpRepository),
    deleteRemoteFile: DeleteRemoteFile(ftpRepository),
    deleteLocalFile: DeleteLocalFile(ftpRepository),
    testConnection: TestConnection(ftpRepository),
    getRemoteFiles: GetRemoteFiles(ftpRepository),
    getLocalFiles: GetLocalFiles(ftpRepository),
    uploadFile: UploadFile(ftpRepository),
    downloadFile: DownloadFile(ftpRepository),
    downloadThumbnail: DownloadThumbnail(ftpRepository),
    detectConflicts: DetectConflicts(ftpRepository),
    getSyncHistory: GetSyncHistory(ftpRepository),
    saveSyncRecord: SaveSyncRecord(ftpRepository),
    getDumpScheduleForProfile: GetDumpScheduleForProfile(ftpRepository),
    saveDumpSchedule: SaveDumpSchedule(ftpRepository),
    getFileVersionHistory: GetFileVersionHistory(monitoringRepository),
    getLatestFileVersion: GetLatestFileVersion(monitoringRepository),
    getLocalFileDetails: GetLocalFileDetails(ftpRepository),
    recordFileVersion: RecordFileVersion(monitoringRepository),
    getHealthSummary: GetHealthSummary(monitoringRepository),
    getRecentEvents: GetRecentEvents(monitoringRepository),
    getActiveAlerts: GetActiveAlerts(monitoringRepository),
    getRecentSyncs: GetRecentSyncs(monitoringRepository),
    getRecentFileVersions: GetRecentFileVersions(monitoringRepository),
    acknowledgeAlert: AcknowledgeAlert(monitoringRepository),
    recordEvent: RecordEvent(monitoringRepository),
    createAlert: CreateAlert(monitoringRepository),
  );
}

List<SingleChildWidget> createUseCaseProviders(AppUseCases useCases) {
  return [
    Provider<ILoginUserUseCase>.value(value: useCases.loginUser),
    Provider<IRegisterUserUseCase>.value(value: useCases.registerUser),
    Provider<ISignInWithGoogleUseCase>.value(value: useCases.signInWithGoogle),
    Provider<ILogoutUserUseCase>.value(value: useCases.logoutUser),
    Provider<IRestoreSessionUseCase>.value(value: useCases.restoreSession),
    Provider<IObserveAuthStateUseCase>.value(value: useCases.observeAuthState),
    Provider<ILinkEmailPasswordUseCase>.value(
      value: useCases.linkEmailPassword,
    ),
    Provider<IRequestPasswordResetUseCase>.value(
      value: useCases.requestPasswordReset,
    ),
    Provider<IUpdateDisplayNameUseCase>.value(
      value: useCases.updateDisplayName,
    ),
    Provider<IEvaluateSyncRulesUseCase>.value(
      value: useCases.evaluateSyncRules,
    ),
    Provider<IBuildSystemHealthReportUseCase>.value(
      value: useCases.buildSystemHealthReport,
    ),
    Provider<IGenerateSystemRecommendationsUseCase>.value(
      value: useCases.generateSystemRecommendations,
    ),
    Provider<IAnalyzeSystemUsageUseCase>.value(
      value: useCases.analyzeSystemUsage,
    ),
    Provider<IGetProfilesUseCase>.value(value: useCases.getProfiles),
    Provider<ISaveProfileUseCase>.value(value: useCases.saveProfile),
    Provider<IDeleteProfileUseCase>.value(value: useCases.deleteProfile),
    Provider<IDeleteRemoteFileUseCase>.value(value: useCases.deleteRemoteFile),
    Provider<IDeleteLocalFileUseCase>.value(value: useCases.deleteLocalFile),
    Provider<ITestConnectionUseCase>.value(value: useCases.testConnection),
    Provider<IGetRemoteFilesUseCase>.value(value: useCases.getRemoteFiles),
    Provider<IGetLocalFilesUseCase>.value(value: useCases.getLocalFiles),
    Provider<IUploadFileUseCase>.value(value: useCases.uploadFile),
    Provider<IDownloadFileUseCase>.value(value: useCases.downloadFile),
    Provider<IDownloadThumbnailUseCase>.value(
      value: useCases.downloadThumbnail,
    ),
    Provider<IDetectConflictsUseCase>.value(value: useCases.detectConflicts),
    Provider<IGetSyncHistoryUseCase>.value(value: useCases.getSyncHistory),
    Provider<ISaveSyncRecordUseCase>.value(value: useCases.saveSyncRecord),
    Provider<IGetDumpScheduleForProfileUseCase>.value(
      value: useCases.getDumpScheduleForProfile,
    ),
    Provider<ISaveDumpScheduleUseCase>.value(value: useCases.saveDumpSchedule),
    Provider<IGetFileVersionHistoryUseCase>.value(
      value: useCases.getFileVersionHistory,
    ),
    Provider<IGetLatestFileVersionUseCase>.value(
      value: useCases.getLatestFileVersion,
    ),
    Provider<IGetLocalFileDetailsUseCase>.value(
      value: useCases.getLocalFileDetails,
    ),
    Provider<IRecordFileVersionUseCase>.value(
      value: useCases.recordFileVersion,
    ),
    Provider<IGetHealthSummaryUseCase>.value(value: useCases.getHealthSummary),
    Provider<IGetRecentEventsUseCase>.value(value: useCases.getRecentEvents),
    Provider<IGetActiveAlertsUseCase>.value(value: useCases.getActiveAlerts),
    Provider<IGetRecentSyncsUseCase>.value(value: useCases.getRecentSyncs),
    Provider<IGetRecentFileVersionsUseCase>.value(
      value: useCases.getRecentFileVersions,
    ),
    Provider<IAcknowledgeAlertUseCase>.value(value: useCases.acknowledgeAlert),
    Provider<IRecordEventUseCase>.value(value: useCases.recordEvent),
    Provider<ICreateAlertUseCase>.value(value: useCases.createAlert),
  ];
}
