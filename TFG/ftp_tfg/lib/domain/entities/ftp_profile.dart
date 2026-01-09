class FtpProfile {
  final String id;
  final String host;
  final int port;
  final String username;
  final String password;

  const FtpProfile({
    required this.id,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });
}
