import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

class HotftpRawFtpClient {
  static int parsePassivePort(String response) {
    final epsv = RegExp(r'\(\|\|\|(\d+)\|\)').firstMatch(response);
    if (epsv != null) {
      return int.parse(epsv.group(1)!);
    }

    final pasv = RegExp(
      r'\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)',
    ).firstMatch(response);
    if (pasv != null) {
      final p1 = int.parse(pasv.group(5)!);
      final p2 = int.parse(pasv.group(6)!);
      return p1 * 256 + p2;
    }
    throw FormatException('Invalid passive response: $response');
  }

  static String decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  static List<Map<String, dynamic>> parseDirectoryListing(
    String text,
    bool mlsd,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final rawLine in text.split('\n')) {
      final line = rawLine.replaceAll('\r', '').trim();
      if (line.isEmpty) continue;
      final parsed = mlsd
          ? _RawFtpSession._parseMlsdLine(line)
          : _RawFtpSession._parseListLine(line);
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }

  Future<bool> testConnection(Map<String, dynamic> config) async {
    final session = await _openSession(config);
    try {
      await session.disconnect();
      return true;
    } catch (_) {
      try {
        await session.disconnect();
      } catch (_) {}
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async {
    final session = await _openSession(config);
    try {
      await session.changeDirectory(path);
      final entries = await session.listDirectory();
      await session.disconnect();
      return entries;
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> uploadFile(
    String localFilePath,
    String remoteDirectory,
    Map<String, dynamic> config,
  ) async {
    final session = await _openSession(config);
    try {
      await session.changeDirectory(remoteDirectory);
      await session.uploadFile(localFilePath);
      await session.disconnect();
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config,
  ) async {
    final session = await _openSession(config);
    try {
      await session.changeDirectory(remoteDirectory);
      await session.downloadFile(remoteFileName, targetLocalPath);
      await session.disconnect();
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> deleteRemoteFile(
    String remoteFileName,
    String remoteDirectory,
    Map<String, dynamic> config,
  ) async {
    final session = await _openSession(config);
    try {
      await session.changeDirectory(remoteDirectory);
      await session.deleteFile(remoteFileName);
      await session.disconnect();
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<String> currentDirectory(Map<String, dynamic> config) async {
    final session = await _openSession(config);
    try {
      final current = await session.currentDirectory();
      await session.disconnect();
      return current;
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<bool> makeDirectory(
    String directoryName,
    Map<String, dynamic> config,
  ) async {
    final session = await _openSession(config);
    try {
      final created = await session.makeDirectory(directoryName);
      await session.disconnect();
      return created;
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<bool> deleteEmptyDirectory(
    String directoryName,
    Map<String, dynamic> config,
  ) async {
    final session = await _openSession(config);
    try {
      final deleted = await session.deleteEmptyDirectory(directoryName);
      await session.disconnect();
      return deleted;
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<bool> rename(
    String oldName,
    String newName,
    Map<String, dynamic> config,
  ) async {
    final session = await _openSession(config);
    try {
      final renamed = await session.rename(oldName, newName);
      await session.disconnect();
      return renamed;
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<int> sizeFile(String fileName, Map<String, dynamic> config) async {
    final session = await _openSession(config);
    try {
      final size = await session.sizeFile(fileName);
      await session.disconnect();
      return size;
    } catch (e) {
      try {
        await session.disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  Future<_RawFtpSession> _openSession(Map<String, dynamic> config) async {
    String host = config['host'] ?? '';
    final port = config['port'] ?? 21;
    final user = config['username'] ?? '';
    final password = config['password'] ?? '';
    final protocol = '${config['protocol'] ?? ''}'.toLowerCase();
    final useFTPS = config['useFTPS'] == true || protocol == 'ftps';
    final passive = config['passiveMode'] ?? true;

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (host == '127.0.0.1' || host == 'localhost')) {
      debugPrint("HOTFTP: Remapping $host to 10.0.2.2 for Android Emulator");
      host = '10.0.2.2';
    }

    final session = _RawFtpSession(
      host: host,
      port: port,
      user: user,
      password: password,
      useFTPS: useFTPS,
      passiveMode: passive,
    );
    await session.connect();
    return session;
  }
}

class _RawFtpSession {
  final String host;
  final int port;
  final String user;
  final String password;
  final bool useFTPS;
  final bool passiveMode;
  final int timeoutSeconds = 30;
  bool _encryptDataChannel = false;

  Socket? _socket;
  StreamSubscription<List<int>>? _controlSubscription;
  bool _connected = false;
  bool _loggedIn = false;
  String _controlPendingLine = '';
  String? _controlReplyCode;
  Object? _pendingControlError;
  final List<String> _controlReplyLines = [];
  final Queue<FTPReplyData> _receivedReplies = Queue<FTPReplyData>();
  final Queue<Completer<FTPReplyData>> _waitingReplies =
      Queue<Completer<FTPReplyData>>();

  _RawFtpSession({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.useFTPS,
    required this.passiveMode,
  });

  Future<void> connect() async {
    final timeout = Duration(seconds: timeoutSeconds);
    if (useFTPS && port == 990) {
      try {
        await _connectAndLogin(
          connectPort: port,
          timeout: timeout,
          implicitFtps: true,
        );
        return;
      } catch (e) {
        debugPrint(
          'HOTFTP: FTPS implicit handshake failed on $host:$port, retrying explicit 21 -> $e',
        );
        await _disposeSocket();
        await _connectAndLogin(
          connectPort: 21,
          timeout: timeout,
          implicitFtps: false,
        );
        return;
      }
    }

    await _connectAndLogin(
      connectPort: port,
      timeout: timeout,
      implicitFtps: false,
    );
  }

  Future<void> _connectAndLogin({
    required int connectPort,
    required Duration timeout,
    required bool implicitFtps,
  }) async {
    try {
      if (useFTPS && implicitFtps) {
        _socket = await SecureSocket.connect(
          host,
          connectPort,
          timeout: timeout,
          onBadCertificate: (_) => true,
        );
      } else {
        _socket = await Socket.connect(host, connectPort, timeout: timeout);
      }
    } catch (e) {
      throw SocketException('Could not connect to $host:$connectPort: $e');
    }

    _startControlListener();
    await _readReply();
    _connected = true;

    if (useFTPS && !implicitFtps) {
      var authReply = await _send('AUTH TLS');
      if (!authReply.isSuccess) {
        authReply = await _send('AUTH SSL');
        if (!authReply.isSuccess) {
          throw FormatException('FTPS negotiation failed: ${authReply.message}');
        }
      }

      await _controlSubscription?.cancel();
      _controlSubscription = null;
      _controlPendingLine = '';
      _controlReplyCode = null;
      _controlReplyLines.clear();
      _receivedReplies.clear();

      final securedSocket = await SecureSocket.secure(
        _socket!,
        onBadCertificate: (_) => true,
      );
      _socket = securedSocket;
      _startControlListener();
    }

    final userReply = await _send('USER $user');
    if (!userReply.isSuccess && userReply.code != 331) {
      throw FormatException('FTP login failed: ${userReply.message}');
    }

    if (userReply.code == 331) {
      final loginReply = await _send('PASS $password');
      if (!loginReply.isSuccess) {
        throw FormatException('FTP login failed: ${loginReply.message}');
      }
    } else if (!userReply.isSuccess) {
      throw FormatException('FTP login failed: ${userReply.message}');
    }

    if (useFTPS) {
      final pbszReply = await _send('PBSZ 0');
      if (!pbszReply.isSuccess) {
        throw FormatException('FTPS PBSZ failed: ${pbszReply.message}');
      }
      // Rebex requires TLS session resumption for PROT P, which Dart's TLS
      // client does not provide here. PROT C keeps the control channel secure
      // and allows the data channel to work reliably.
      final protReply = await _send('PROT C');
      if (!protReply.isSuccess) {
        throw FormatException('FTPS PROT failed: ${protReply.message}');
      }
      _encryptDataChannel = false;
    }

    _loggedIn = true;
  }

  Future<void> _disposeSocket() async {
    try {
      await _controlSubscription?.cancel();
    } catch (_) {}
    _controlSubscription = null;
    _controlPendingLine = '';
    _controlReplyCode = null;
    _pendingControlError = null;
    _controlReplyLines.clear();
    _receivedReplies.clear();
    _waitingReplies.clear();
    _connected = false;
    _loggedIn = false;
    _encryptDataChannel = false;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {}
    }
  }

  Future<void> changeDirectory(String path) async {
    _ensureReady();
    final reply = await _send('CWD $path');
    if (!reply.isSuccess) {
      throw FormatException(
        'Cannot change directory to $path: ${reply.message}',
      );
    }
  }

  Future<String> currentDirectory() async {
    _ensureReady();
    final reply = await _send('PWD');
    if (!reply.isSuccess) {
      throw FormatException('Cannot read current directory');
    }
    final match = RegExp(r'"([^"]+)"').firstMatch(reply.message);
    return match?.group(1) ?? '/';
  }

  Future<List<Map<String, dynamic>>> listDirectory() async {
    _ensureReady();

    final supportsMlsd = await _supportsMlsd();
    final primary = await _listDirectoryWithCommand(
      supportsMlsd ? 'MLSD' : 'LIST',
      supportsMlsd,
    );
    if (primary.isNotEmpty || !supportsMlsd) {
      return primary;
    }

    final fallback = await _listDirectoryWithCommand('LIST', false);
    return fallback;
  }

  Future<void> uploadFile(String localFilePath) async {
    _ensureReady();
    final file = File(localFilePath);
    if (!await file.exists()) {
      throw FileSystemException('Local file not found', localFilePath);
    }

    final transfer = await _openDataTransferChannel(
      'STOR ${file.uri.pathSegments.last}',
    );
    final dataSocket = transfer.dataSocket;
    final firstReply = transfer.firstReply;
    if (!firstReply.isPreliminary && !firstReply.isSuccess) {
      throw FormatException('Connection refused for upload');
    }

    await dataSocket.addStream(file.openRead());
    await dataSocket.flush();
    await dataSocket.close();

    if (!firstReply.isSuccess) {
      final completion = await _readReply();
      if (!completion.isSuccess) {
        throw FormatException('Upload failed');
      }
    }
  }

  Future<void> downloadFile(
    String remoteFileName,
    String targetLocalPath,
  ) async {
    _ensureReady();

    final transfer = await _openDataTransferChannel('RETR $remoteFileName');
    final dataSocket = transfer.dataSocket;
    final firstReply = transfer.firstReply;
    if (!firstReply.isPreliminary && !firstReply.isSuccess) {
      throw FormatException('Connection refused for download');
    }

    final sink = File(targetLocalPath).openWrite(mode: FileMode.writeOnly);
    await dataSocket.listen((Uint8List chunk) {
      sink.add(chunk);
    }).asFuture<void>();
    await dataSocket.close();
    await sink.flush();
    await sink.close();

    if (!firstReply.isSuccess) {
      final completion = await _readReply();
      if (!completion.isSuccess) {
        throw FormatException('Download failed');
      }
    }
  }

  Future<void> deleteFile(String remoteFileName) async {
    _ensureReady();
    final reply = await _send('DELE $remoteFileName');
    if (!reply.isSuccess) {
      throw FormatException('Delete failed for $remoteFileName');
    }
  }

  Future<bool> makeDirectory(String directoryName) async {
    _ensureReady();
    final reply = await _send('MKD $directoryName');
    return reply.isSuccess;
  }

  Future<bool> deleteEmptyDirectory(String directoryName) async {
    _ensureReady();
    final reply = await _send('RMD $directoryName');
    return reply.isSuccess;
  }

  Future<bool> rename(String oldName, String newName) async {
    _ensureReady();
    final first = await _send('RNFR $oldName');
    if (first.code != 350) {
      return false;
    }
    final second = await _send('RNTO $newName');
    return second.isSuccess;
  }

  Future<int> sizeFile(String fileName) async {
    _ensureReady();
    final reply = await _send('SIZE $fileName');
    if (!reply.isSuccess) {
      return -1;
    }
    final value = reply.message.replaceFirst(RegExp(r'^213\s+'), '').trim();
    return int.tryParse(value) ?? -1;
  }

  Future<bool> existsFile(String fileName) async =>
      await sizeFile(fileName) != -1;

  Future<bool> createFolderIfNotExist(String directoryName) async {
    if (await sizeFile(directoryName) == -1) {
      return makeDirectory(directoryName);
    }
    return true;
  }

  Future<void> disconnect() async {
    if (!_connected || _socket == null) return;
    try {
      await _send('QUIT');
    } catch (_) {}
    await _controlSubscription?.cancel();
    _controlSubscription = null;
    await _socket!.close();
    _socket = null;
    _connected = false;
    _loggedIn = false;
    _controlPendingLine = '';
    _controlReplyCode = null;
    _pendingControlError = null;
    _controlReplyLines.clear();
    _receivedReplies.clear();
    while (_waitingReplies.isNotEmpty) {
      _waitingReplies.removeFirst().completeError(
        StateError('FTP session closed'),
      );
    }
  }

  void _ensureReady() {
    if (!_connected || !_loggedIn || _socket == null) {
      throw StateError('FTP session is not ready');
    }
  }

  Future<bool> _supportsMlsd() async {
    try {
      final reply = await _send('FEAT');
      return reply.message.toUpperCase().contains('MLSD');
    } catch (_) {
      return false;
    }
  }

  Future<_DataReply> _openDataChannel(String command) async {
    final passiveReply = await _send('EPSV');
    FTPReplyData parsedPassive = passiveReply;
    if (!passiveReply.isSuccess) {
      parsedPassive = await _send('PASV');
      if (!parsedPassive.isSuccess) {
        throw FormatException('Could not start passive mode');
      }
    }

    final port = HotftpRawFtpClient.parsePassivePort(parsedPassive.message);
    final dataSocket = await _connectDataSocket(port);

    await _send(command, waitForReply: false);
    final firstReply = await _readReply();
    return _DataReply(dataSocket: dataSocket, firstReply: firstReply);
  }

  Future<_DataReply> _openDataTransferChannel(String command) async {
    final reply = await _openDataChannel(command);
    return reply;
  }

  Future<List<Map<String, dynamic>>> _listDirectoryWithCommand(
    String command,
    bool mlsd,
  ) async {
    final reply = await _openDataChannel(command);
    final dataSocket = reply.dataSocket;
    final firstReply = reply.firstReply;
    if (!firstReply.isPreliminary && !firstReply.isSuccess) {
      throw FormatException('Connection refused for directory listing');
    }

    final data = await _readData(dataSocket);
    await dataSocket.close();

    if (!firstReply.isSuccess) {
      final completion = await _readReply();
      if (!completion.isSuccess) {
        throw FormatException('Transfer error');
      }
    }

    final text = HotftpRawFtpClient.decodeBytes(data);
    return HotftpRawFtpClient.parseDirectoryListing(text, mlsd);
  }

  Future<Socket> _connectDataSocket(int port) async {
    final timeout = Duration(seconds: timeoutSeconds);
    if (useFTPS && _encryptDataChannel) {
      final socket = await Socket.connect(host, port, timeout: timeout);
      return SecureSocket.secure(
        socket,
        onBadCertificate: (_) => true,
      );
    }
    return Socket.connect(host, port, timeout: timeout);
  }

  Future<FTPReplyData> _send(String command, {bool waitForReply = true}) async {
    _socket!.add(utf8.encode('$command\r\n'));
    await _socket!.flush();
    if (!waitForReply) {
      return FTPReplyData(code: 200, message: '');
    }
    return _readReply();
  }

  Future<FTPReplyData> _readReply() async {
    final pendingError = _pendingControlError;
    if (pendingError != null) {
      _pendingControlError = null;
      throw pendingError;
    }

    if (_receivedReplies.isNotEmpty) {
      return _receivedReplies.removeFirst();
    }

    final completer = Completer<FTPReplyData>();
    _waitingReplies.addLast(completer);
    return completer.future.timeout(Duration(seconds: timeoutSeconds));
  }

  Future<List<int>> _readData(Socket dataSocket) async {
    final buffer = <int>[];
    await for (final chunk in dataSocket) {
      buffer.addAll(chunk);
    }
    return buffer;
  }

  void _startControlListener() {
    _controlSubscription?.cancel();
    _controlSubscription = _socket!.listen(
      (chunk) {
        _controlPendingLine += HotftpRawFtpClient.decodeBytes(chunk);
        _drainControlLines();
      },
      onError: (Object error, StackTrace stackTrace) {
        _failPendingReplies(error, stackTrace);
      },
      onDone: () {
        _failPendingReplies(
          StateError('FTP control connection closed'),
          StackTrace.current,
        );
      },
      cancelOnError: true,
    );
  }

  void _drainControlLines() {
    final normalized = _controlPendingLine.replaceAll('\r', '');
    final lines = normalized.split('\n');
    if (lines.isEmpty) return;

    final hasTrailingPartial = !normalized.endsWith('\n');
    final completeLines = hasTrailingPartial ? lines.sublist(0, lines.length - 1) : lines;
    _controlPendingLine = hasTrailingPartial ? lines.last : '';

    for (final rawLine in completeLines) {
      final line = rawLine.trimRight();
      if (line.isEmpty) continue;
      _consumeControlLine(line);
    }
  }

  void _consumeControlLine(String line) {
    if (_controlReplyLines.isEmpty) {
      if (line.length < 3) {
        _queueControlReplyError(FormatException('Invalid FTP reply: $line'));
        return;
      }
      final code = int.tryParse(line.substring(0, 3));
      if (code == null) {
        _queueControlReplyError(FormatException('Invalid FTP reply: $line'));
        return;
      }
      _controlReplyCode = code.toString();
      _controlReplyLines.add(line);
      if (line.length >= 4 && line[3] == ' ') {
        _completeControlReply();
      }
      return;
    }

    _controlReplyLines.add(line);
    final code = _controlReplyCode;
    if (code != null && line.length >= 4 && line.startsWith(code) && line[3] == ' ') {
      _completeControlReply();
    }
  }

  void _completeControlReply() {
    final first = _controlReplyLines.first;
    final code = int.tryParse(first.substring(0, 3));
    if (code == null) {
      _queueControlReplyError(FormatException('Invalid FTP reply: $first'));
      return;
    }

    final message = _controlReplyLines.join('\n');
    final reply = FTPReplyData(code: code, message: message);
    _controlReplyLines.clear();
    _controlReplyCode = null;
    _deliverReply(reply);
  }

  void _deliverReply(FTPReplyData reply) {
    _pendingControlError = null;
    if (_waitingReplies.isNotEmpty) {
      _waitingReplies.removeFirst().complete(reply);
      return;
    }
    _receivedReplies.addLast(reply);
  }

  void _queueControlReplyError(Object error) {
    final replyError = error is FormatException
        ? error
        : FormatException('Invalid FTP reply: $error');
    while (_waitingReplies.isNotEmpty) {
      _waitingReplies.removeFirst().completeError(replyError);
    }
    _controlReplyLines.clear();
    _controlReplyCode = null;
    _receivedReplies.clear();
    _pendingControlError = replyError;
  }

  void _failPendingReplies(Object error, StackTrace stackTrace) {
    while (_waitingReplies.isNotEmpty) {
      _waitingReplies.removeFirst().completeError(error, stackTrace);
    }
    if (_receivedReplies.isEmpty) {
      _pendingControlError = error;
    }
  }

  static Map<String, dynamic>? _parseMlsdLine(String line) {
    final parts = line.split(';');
    if (parts.isEmpty) return null;

    final data = <String, dynamic>{};
    var name = '';
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      if (!trimmed.contains('=')) {
        name = trimmed;
        continue;
      }
      final idx = trimmed.indexOf('=');
      final key = trimmed.substring(0, idx).toLowerCase();
      final value = trimmed.substring(idx + 1);
      switch (key) {
        case 'type':
          data['isDir'] = value == 'dir';
          break;
        case 'size':
          data['size'] = int.tryParse(value) ?? 0;
          break;
        case 'modify':
          data['modifyTime'] = DateTime.tryParse(
            value.length >= 14
                ? '${value.substring(0, 8)}T${value.substring(8)}'
                : value,
          )?.toIso8601String();
          break;
      }
    }
    data['name'] = name;
    data['size'] ??= 0;
    data['isDir'] ??= false;
    return data;
  }

  static Map<String, dynamic>? _parseListLine(String line) {
    final dosMatch = RegExp(
      r'^(\d{2}-\d{2}-\d{2})\s+(\d{2}:\d{2}[AP]M)\s+(<DIR>|\d+)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (dosMatch != null) {
      final sizeToken = dosMatch.group(3)!;
      return {
        'name': dosMatch.group(4)!,
        'size': sizeToken == '<DIR>' ? 0 : int.tryParse(sizeToken) ?? 0,
        'isDir': sizeToken == '<DIR>',
        'modifyTime': null,
      };
    }

    final reg = RegExp(
      r'^([\-ld])([\-rwxs]{9})\s+(\d+)\s+(\w+)\s+(\w+)\s+(\d+)\s+(\w{3}\s+\d{1,2}\s+(?:\d{1,2}:\d{1,2}|\d{4}))\s+(.+)$',
    );
    final match = reg.firstMatch(line);
    if (match != null) {
      return {
        'name': match.group(8)!,
        'size': int.tryParse(match.group(6)!) ?? 0,
        'isDir': match.group(1) == 'd',
        'modifyTime': null,
      };
    }

    final tokens = line
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.length < 9) return null;
    final typeToken = tokens.first;
    final sizeToken = tokens[4];
    final name = tokens.sublist(8).join(' ');
    return {
      'name': name,
      'size': int.tryParse(sizeToken) ?? 0,
      'isDir': typeToken == 'd',
      'modifyTime': null,
    };
  }
}

class _DataReply {
  final Socket dataSocket;
  final FTPReplyData firstReply;

  _DataReply({required this.dataSocket, required this.firstReply});
}

class FTPReplyData {
  final int code;
  final String message;

  FTPReplyData({required this.code, required this.message});

  bool get isSuccess => code >= 200 && code < 400;
  bool get isPreliminary => code == 125 || code == 150;
}
