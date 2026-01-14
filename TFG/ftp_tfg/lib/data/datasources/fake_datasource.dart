class FakeFtpDatasource {
  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula carga

    return [
      {
        'name': 'Documents',
        'path': '/Documents',
        'isDirectory': true,
        'size': 0,
      },
      {
        'name': 'file.txt',
        'path': '/file.txt',
        'isDirectory': false,
        'size': 1200,
      },
    ];
  }
}
