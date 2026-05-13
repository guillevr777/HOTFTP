import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import '../../core/config/api_config.dart';

class HotftpApiClient {
  HotftpApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse(baseUrl).replace(
      path: '${Uri.parse(baseUrl).path}$path',
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> listRemoteFiles({
    required String ownerId,
    required int profileId,
    required String path,
  }) async {
    final response = await http.get(
      _uri('/api/v1/files/remote', {
        'ownerId': ownerId,
        'profileId': profileId,
        'path': path,
      }),
    );
    _ensureSuccess(response);
    return _decodeList(response.body);
  }

  Future<List<Map<String, dynamic>>> getProfiles(String ownerId) async {
    final response = await http.get(
      _uri('/api/v1/profiles', {'ownerId': ownerId}),
    );
    _ensureSuccess(response);
    return _decodeList(response.body);
  }

  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) async {
    final response = await http.post(
      _uri('/api/v1/profiles'),
      headers: _jsonHeaders,
      body: jsonEncode(profile),
    );
    _ensureSuccess(response, expectedStatusCodes: {200, 201});
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteProfile({
    required String ownerId,
    required int profileId,
  }) async {
    final response = await http.delete(
      _uri('/api/v1/profiles/$profileId', {'ownerId': ownerId}),
    );
    _ensureSuccess(response, expectedStatusCodes: {204});
  }

  Future<bool> testConnection(Map<String, dynamic> profile) async {
    final response = await http.post(
      _uri('/api/v1/profiles/test-connection'),
      headers: _jsonHeaders,
      body: jsonEncode(profile),
    );
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['ok'] == true;
  }

  Future<void> uploadFile({
    required String ownerId,
    required int profileId,
    required String remotePath,
    required String localFilePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/v1/files/upload'),
    );
    request.fields['ownerId'] = ownerId;
    request.fields['profileId'] = profileId.toString();
    request.fields['remotePath'] = remotePath;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        localFilePath,
        filename: p.basename(localFilePath),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
  }

  Future<void> downloadFileToPath({
    required String ownerId,
    required int profileId,
    required String remotePath,
    required String fileName,
    required String targetLocalPath,
  }) async {
    final response = await http.get(
      _uri('/api/v1/files/download', {
        'ownerId': ownerId,
        'profileId': profileId,
        'remotePath': remotePath,
        'fileName': fileName,
      }),
    );
    _ensureSuccess(response);
    final file = File(targetLocalPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes);
  }

  Future<void> deleteRemoteFile({
    required String ownerId,
    required int profileId,
    required String remotePath,
    required String fileName,
  }) async {
    final response = await http.delete(
      _uri('/api/v1/files/remote', {
        'ownerId': ownerId,
        'profileId': profileId,
        'remotePath': remotePath,
        'fileName': fileName,
      }),
    );
    _ensureSuccess(response, expectedStatusCodes: {204});
  }

  Future<List<Map<String, dynamic>>> getSyncHistory(String ownerId) async {
    final response = await http.get(
      _uri('/api/v1/sync/history', {'ownerId': ownerId}),
    );
    _ensureSuccess(response);
    return _decodeList(response.body);
  }

  Future<List<Map<String, dynamic>>> getRecentEvents(
    String ownerId, {
    int limit = 20,
  }) async {
    final response = await http.get(
      _uri('/api/v1/monitoring/events', {
        'ownerId': ownerId,
        'limit': limit,
      }),
    );
    _ensureSuccess(response);
    return _decodeList(response.body);
  }

  Future<List<Map<String, dynamic>>> getActiveAlerts(
    String ownerId, {
    int limit = 10,
  }) async {
    final response = await http.get(
      _uri('/api/v1/monitoring/alerts/active', {
        'ownerId': ownerId,
        'limit': limit,
      }),
    );
    _ensureSuccess(response);
    return _decodeList(response.body);
  }

  Future<Map<String, dynamic>> createAlert(
    Map<String, dynamic> alert,
  ) async {
    final response = await http.post(
      _uri('/api/v1/monitoring/alerts'),
      headers: _jsonHeaders,
      body: jsonEncode(alert),
    );
    _ensureSuccess(response, expectedStatusCodes: {200, 201});
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> acknowledgeAlert({
    required String ownerId,
    required int alertId,
  }) async {
    final response = await http.post(
      _uri('/api/v1/monitoring/alerts/$alertId/acknowledge', {
        'ownerId': ownerId,
      }),
    );
    _ensureSuccess(response, expectedStatusCodes: {204});
  }

  Future<void> recordEvent(Map<String, dynamic> event) async {
    final response = await http.post(
      _uri('/api/v1/monitoring/events'),
      headers: _jsonHeaders,
      body: jsonEncode(event),
    );
    _ensureSuccess(response, expectedStatusCodes: {200, 201});
  }

  Future<List<Map<String, dynamic>>> getRecentFileVersions(
    String ownerId, {
    int limit = 12,
  }) async {
    final response = await http.get(
      _uri('/api/v1/monitoring/file-versions/recent', {
        'ownerId': ownerId,
        'limit': limit,
      }),
    );
    _ensureSuccess(response);
    return _decodeList(response.body);
  }

  Future<Map<String, dynamic>?> getLatestFileVersion({
    required String ownerId,
    required int profileId,
    required String filePath,
  }) async {
    final response = await http.get(
      _uri('/api/v1/monitoring/file-versions/latest', {
        'ownerId': ownerId,
        'profileId': profileId,
        'filePath': filePath,
      }),
    );
    _ensureSuccess(response);
    if (response.body.isEmpty || response.body == 'null') return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getFileVersionHistory({
    required String ownerId,
    required int profileId,
    required String filePath,
    int limit = 20,
  }) async {
    final response = await http.get(
      _uri('/api/v1/monitoring/file-versions/history', {
        'ownerId': ownerId,
        'profileId': profileId,
        'filePath': filePath,
        'limit': limit,
      }),
    );
    _ensureSuccess(response);
    return _decodeList(response.body);
  }

  Future<Map<String, dynamic>> recordFileVersion(
    Map<String, dynamic> version,
  ) async {
    final response = await http.post(
      _uri('/api/v1/monitoring/file-versions'),
      headers: _jsonHeaders,
      body: jsonEncode(version),
    );
    _ensureSuccess(response, expectedStatusCodes: {200, 201});
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> saveSyncRecord(Map<String, dynamic> record) async {
    final response = await http.post(
      _uri('/api/v1/sync/records'),
      headers: _jsonHeaders,
      body: jsonEncode(record),
    );
    _ensureSuccess(response, expectedStatusCodes: {200, 201});
  }

  Future<Map<String, dynamic>> getHealthSummary(String ownerId) async {
    final response = await http.get(
      _uri('/api/v1/monitoring/summary', {'ownerId': ownerId}),
    );
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getDumpScheduleForProfile({
    required String ownerId,
    required int profileId,
  }) async {
    final response = await http.get(
      _uri('/api/v1/schedules/profile', {
        'ownerId': ownerId,
        'profileId': profileId,
      }),
    );
    _ensureSuccess(response);
    if (response.body.isEmpty || response.body == 'null') return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveDumpSchedule(
    Map<String, dynamic> schedule,
  ) async {
    final response = await http.post(
      _uri('/api/v1/schedules'),
      headers: _jsonHeaders,
      body: jsonEncode(schedule),
    );
    _ensureSuccess(response, expectedStatusCodes: {200, 201});
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json; charset=utf-8',
      };

  static List<Map<String, dynamic>> _decodeList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) return [];
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  static void _ensureSuccess(
    http.Response response, {
    Set<int> expectedStatusCodes = const {200},
  }) {
    if (expectedStatusCodes.contains(response.statusCode)) return;
    throw HttpException(
      'API request failed with ${response.statusCode}: ${response.body}',
      uri: response.request?.url,
    );
  }
}
