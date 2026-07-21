class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'HOTFTP_API_BASE_URL',
    defaultValue: 'https://hotftp-api.onrender.com',
  );
}

