class FtpProfile {
  final int? id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useFTPS;
  final bool passiveMode;

  FtpProfile({
    this.id,
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
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'useFTPS': useFTPS ? 1 : 0,
        'passiveMode': passiveMode ? 1 : 0,
      };

  factory FtpProfile.fromMap(Map<String, dynamic> map) => FtpProfile(
        id: map['id'],
        name: map['name'],
        host: map['host'],
        port: map['port'],
        username: map['username'],
        password: map['password'],
        useFTPS: map['useFTPS'] == 1,
        passiveMode: map['passiveMode'] == 1,
      );
}
