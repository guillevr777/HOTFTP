enum FtpTransportType { local, remote }

class FtpProfile {
  final int? id;
  final String? ownerId;
  final FtpTransportType transportType;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useFTPS;
  final bool passiveMode;

  FtpProfile({
    this.id,
    this.ownerId,
    this.transportType = FtpTransportType.remote,
    required this.name,
    required this.host,
    this.port = 21,
    required this.username,
    required this.password,
    this.useFTPS = false,
    this.passiveMode = true,
  });

  FtpProfile copyWith({
    int? id,
    String? ownerId,
    FtpTransportType? transportType,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? useFTPS,
    bool? passiveMode,
  }) {
    return FtpProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      transportType: transportType ?? this.transportType,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      useFTPS: useFTPS ?? this.useFTPS,
      passiveMode: passiveMode ?? this.passiveMode,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'transportType': transportType.name,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'useFTPS': useFTPS ? 1 : 0,
        'passiveMode': passiveMode ? 1 : 0,
      };

  factory FtpProfile.fromMap(
    Map<String, dynamic> map, {
    FtpTransportType defaultTransportType = FtpTransportType.remote,
  }) =>
      FtpProfile(
        id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
        ownerId: map['ownerId'] as String?,
        transportType: FtpTransportType.values.firstWhere(
          (value) => value.name == map['transportType'],
          orElse: () => defaultTransportType,
        ),
        name: map['name'],
        host: map['host'],
        port: map['port'],
        username: map['username'],
        password: map['password'],
        useFTPS: map['useFTPS'] == 1,
        passiveMode: map['passiveMode'] == 1,
      );
}
