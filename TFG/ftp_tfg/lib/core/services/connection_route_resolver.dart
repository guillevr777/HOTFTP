import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

import '../../domain/entities/ftp_profile.dart';

class ConnectionRouteResolver {
  const ConnectionRouteResolver();

  FtpTransportType resolveTransportType(String host) {
    if (kIsWeb) return FtpTransportType.api;

    final normalized = host.trim().toLowerCase();
    if (normalized.isEmpty) return FtpTransportType.api;
    if (normalized == 'localhost') return FtpTransportType.direct;

    final address = InternetAddress.tryParse(normalized);
    if (address == null) {
      return FtpTransportType.api;
    }

    return _isPrivateOrLocal(address)
        ? FtpTransportType.direct
        : FtpTransportType.api;
  }

  bool _isPrivateOrLocal(InternetAddress address) {
    final host = address.address;

    if (address.type == InternetAddressType.IPv4) {
      final parts = host.split('.').map((part) => int.tryParse(part) ?? -1).toList();
      if (parts.length != 4 || parts.any((part) => part < 0)) return false;
      final a = parts[0];
      final b = parts[1];
      if (a == 10) return true;
      if (a == 127) return true;
      if (a == 169 && b == 254) return true;
      if (a == 172 && b >= 16 && b <= 31) return true;
      if (a == 192 && b == 168) return true;
      return false;
    }

    if (address.type == InternetAddressType.IPv6) {
      if (host == '::1' || host == '0:0:0:0:0:0:0:1') return true;
      if (host.startsWith('fe80:')) return true;
      if (host.startsWith('fc') || host.startsWith('fd')) return true;
    }

    return false;
  }
}
