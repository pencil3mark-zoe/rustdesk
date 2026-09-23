import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/utils/direct_peer_reachability/direct_peer_reachability_io.dart';

void main() {
  group('parseDirectPeerEndpoint', () {
    test('IPv4 uses RustDesk direct default port', () {
      final endpoint = parseDirectPeerEndpoint('10.144.144.8');
      expect(endpoint, isNotNull);
      expect(endpoint!.host, '10.144.144.8');
      expect(endpoint.port, 21118);
    });

    test('IPv4 explicit port is preserved', () {
      final endpoint = parseDirectPeerEndpoint('10.144.144.8:21118');
      expect(endpoint, isNotNull);
      expect(endpoint!.host, '10.144.144.8');
      expect(endpoint.port, 21118);
    });

    test('raw IPv6 uses RustDesk direct default port', () {
      final endpoint =
          parseDirectPeerEndpoint('240e:878:e2a:a05c:1132:3b5c:592c:beed');
      expect(endpoint, isNotNull);
      expect(endpoint!.host, '240e:878:e2a:a05c:1132:3b5c:592c:beed');
      expect(endpoint.port, 21118);
    });

    test('bracketed IPv6 explicit port is preserved', () {
      final endpoint = parseDirectPeerEndpoint(
          '[240e:878:e2a:a05c:1132:3b5c:592c:beed]:21118');
      expect(endpoint, isNotNull);
      expect(endpoint!.host, '240e:878:e2a:a05c:1132:3b5c:592c:beed');
      expect(endpoint.port, 21118);
    });

    test('normal RustDesk numeric IDs are not Direct IPs', () {
      expect(parseDirectPeerEndpoint('135 585 120'), isNull);
      expect(parseDirectPeerEndpoint('30 994 932'), isNull);
      expect(parseDirectPeerEndpoint('3099432'), isNull);
    });

    test('invalid endpoints are rejected', () {
      expect(parseDirectPeerEndpoint('10.144.144.999'), isNull);
      expect(parseDirectPeerEndpoint('10.144.144.8:99999'), isNull);
      expect(parseDirectPeerEndpoint('[not-an-ip]:21118'), isNull);
    });
  });

  group('probeDirectPeerReachability', () {
    test('reports a listening TCP endpoint as reachable', () async {
      final server =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      try {
        final endpoint = '127.0.0.1:' + server.port.toString();
        expect(
          await probeDirectPeerReachability(endpoint),
          isTrue,
        );
      } finally {
        await server.close();
      }
    });

    test('reports a closed TCP endpoint as unreachable', () async {
      final server =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close();

      expect(
        await probeDirectPeerReachability(
          '127.0.0.1:' + port.toString(),
          timeout: const Duration(milliseconds: 300),
        ),
        isFalse,
      );
    });
  });
}
