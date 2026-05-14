enum FtpTransportType { direct, api }

enum FtpProtocolType { ftp, sftp, ftps }

class FtpProfile {
  final int? id;
  final String? ownerId;
  final FtpTransportType transportType;
  final FtpProtocolType protocol;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool passiveMode;

  FtpProfile({
    this.id,
    this.ownerId,
    this.transportType = FtpTransportType.direct,
    this.protocol = FtpProtocolType.ftp,
    required this.name,
    required this.host,
    this.port = 21,
    required this.username,
    required this.password,
    this.passiveMode = true,
  });

  FtpProfile copyWith({
    int? id,
    String? ownerId,
    FtpTransportType? transportType,
    FtpProtocolType? protocol,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? passiveMode,
  }) {
    return FtpProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      transportType: transportType ?? this.transportType,
      protocol: protocol ?? this.protocol,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      passiveMode: passiveMode ?? this.passiveMode,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'transportType': transportType.name,
        'protocol': protocol.name,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'useFTPS': protocol == FtpProtocolType.ftps ? 1 : 0,
        'passiveMode': passiveMode ? 1 : 0,
      };

  factory FtpProfile.fromMap(
    Map<String, dynamic> map, {
    FtpTransportType defaultTransportType = FtpTransportType.direct,
  }) =>
      FtpProfile(
        id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
        ownerId: map['ownerId'] as String?,
        transportType: _transportTypeFromValue(
          map['transportType'],
          defaultTransportType,
        ),
        protocol: FtpProtocolType.values.firstWhere(
          (value) => value.name == map['protocol'],
          orElse: () => _asBool(map['useFTPS'])
              ? FtpProtocolType.ftps
              : FtpProtocolType.ftp,
        ),
        name: map['name'],
        host: map['host'],
        port: map['port'],
        username: map['username'],
        password: map['password'],
        passiveMode: _asBool(map['passiveMode']),
      );

  bool get useFTPS => protocol == FtpProtocolType.ftps;

  static FtpTransportType _transportTypeFromValue(
    Object? value,
    FtpTransportType fallback,
  ) {
    final raw = '${value ?? ''}'.toLowerCase();
    return switch (raw) {
      'direct' || 'local' => FtpTransportType.direct,
      'api' || 'remote' => FtpTransportType.api,
      _ => fallback,
    };
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return '${value ?? ''}'.toLowerCase() == 'true';
  }
}
