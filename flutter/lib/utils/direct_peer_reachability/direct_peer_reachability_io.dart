import 'dart:io';

const int _defaultDirectPort = 21118;

class DirectPeerEndpoint {
  final String host;
  final int port;

  const DirectPeerEndpoint(this.host, this.port);

  @override
  String toString() => '$host:$port';
}

DirectPeerEndpoint? parseDirectPeerEndpoint(String peerId) {
  final value = peerId.trim();
  if (value.isEmpty) return null;

  if (value.startsWith('[')) {
    final end = value.indexOf(']');
    if (end <= 1) return null;
    final host = value.substring(1, end);
    final address = InternetAddress.tryParse(host);
    if (address == null || address.type != InternetAddressType.IPv6) {
      return null;
    }

    final rest = value.substring(end + 1);
    if (rest.isEmpty) {
      return DirectPeerEndpoint(host, _defaultDirectPort);
    }
    if (!rest.startsWith(':')) return null;
    final port = int.tryParse(rest.substring(1));
    if (port == null || port < 1 || port > 65535) return null;
    return DirectPeerEndpoint(host, port);
  }

  final directAddress = InternetAddress.tryParse(value);
  if (directAddress != null) {
    return DirectPeerEndpoint(value, _defaultDirectPort);
  }

  final firstColon = value.indexOf(':');
  final lastColon = value.lastIndexOf(':');
  if (firstColon > 0 && firstColon == lastColon) {
    final host = value.substring(0, firstColon);
    final port = int.tryParse(value.substring(firstColon + 1));
    final address = InternetAddress.tryParse(host);
    if (address == null ||
        address.type != InternetAddressType.IPv4 ||
        port == null ||
        port < 1 ||
        port > 65535) {
      return null;
    }
    return DirectPeerEndpoint(host, port);
  }

  return null;
}

bool isDirectPeerAddress(String peerId) =>
    parseDirectPeerEndpoint(peerId) != null;

Future<bool> probeDirectPeerReachability(
  String peerId, {
  Duration timeout = const Duration(milliseconds: 1500),
}) async {
  final endpoint = parseDirectPeerEndpoint(peerId);
  if (endpoint == null) return false;

  Socket? socket;
  try {
    socket = await Socket.connect(
      endpoint.host,
      endpoint.port,
      timeout: timeout,
    );
    return true;
  } catch (_) {
    return false;
  } finally {
    socket?.destroy();
  }
}
