import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/core/services/connection_route_resolver.dart';
import 'package:ftp_tfg/domain/entities/ftp_profile.dart';

void main() {
  const resolver = ConnectionRouteResolver();

  test('resolves localhost and private IPs to direct', () {
    expect(resolver.resolveTransportType('localhost'), FtpTransportType.direct);
    expect(resolver.resolveTransportType('127.0.0.1'), FtpTransportType.direct);
    expect(resolver.resolveTransportType('192.168.1.50'), FtpTransportType.direct);
    expect(resolver.resolveTransportType('10.0.0.5'), FtpTransportType.direct);
  });

  test('resolves public IPs to api', () {
    expect(resolver.resolveTransportType('8.8.8.8'), FtpTransportType.api);
    expect(resolver.resolveTransportType('1.1.1.1'), FtpTransportType.api);
  });
}
