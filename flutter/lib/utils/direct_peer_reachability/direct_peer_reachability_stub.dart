class DirectPeerEndpoint {
  final String host;
  final int port;

  const DirectPeerEndpoint(this.host, this.port);
}

DirectPeerEndpoint? parseDirectPeerEndpoint(String peerId) => null;

bool isDirectPeerAddress(String peerId) => false;

Future<bool> probeDirectPeerReachability(
  String peerId, {
  Duration timeout = const Duration(milliseconds: 1500),
}) async =>
    false;
