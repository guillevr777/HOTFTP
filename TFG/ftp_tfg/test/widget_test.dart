import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Firebase options are available for the current platform', () {
    final options = DefaultFirebaseOptions.currentPlatform;
    expect(options.projectId, isNotEmpty);
    expect(options.appId, isNotEmpty);
  });
}
