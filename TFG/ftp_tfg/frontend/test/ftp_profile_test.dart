import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/domain/entities/ftp_profile.dart';

void main() {
  test('parses legacy transport type and protocol values', () {
    final profile = FtpProfile.fromMap({
      'id': 7,
      'ownerId': 'demo',
      'transportType': 'remote',
      'protocol': 'ftps',
      'name': 'Legacy',
      'host': '8.8.8.8',
      'port': 21,
      'username': 'user',
      'password': 'pass',
      'passiveMode': 1,
    });

    expect(profile.transportType, FtpTransportType.api);
    expect(profile.protocol, FtpProtocolType.ftps);
    expect(profile.useFTPS, isTrue);
  });

  test('serializes the new protocol fields', () {
    final profile = FtpProfile(
      id: 3,
      ownerId: 'demo',
      transportType: FtpTransportType.direct,
      protocol: FtpProtocolType.sftp,
      name: 'SFTP',
      host: '192.168.1.10',
      username: 'user',
      password: 'pass',
    );

    final map = profile.toMap();
    expect(map['transportType'], 'direct');
    expect(map['protocol'], 'sftp');
    expect(map['useFTPS'], 0);
  });

  test('preserves empty passwords for passwordless servers', () {
    final profile = FtpProfile(
      name: 'No password',
      host: 'test.rebex.net',
      username: 'demo',
      password: '',
    );

    final map = profile.toMap();
    final roundTrip = FtpProfile.fromMap(map);

    expect(roundTrip.password, isEmpty);
    expect(roundTrip.username, 'demo');
  });

  test('parses legacy enum-style protocol values', () {
    final profile = FtpProfile.fromMap({
      'name': 'Legacy SFTP',
      'host': 'test.rebex.net',
      'port': 22,
      'username': 'demo',
      'password': 'password',
      'protocol': 'FtpProtocolType.sftp',
      'transportType': 'direct',
    });

    expect(profile.protocol, FtpProtocolType.sftp);
    expect(profile.toMap()['protocol'], 'sftp');
  });
}
