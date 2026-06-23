import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over the device connectivity so the rest of the app never
/// depends on `connectivity_plus` directly. This keeps the offline strategy
/// testable (the implementation is mocked in unit tests).
abstract class NetworkInfo {
  /// Whether the device currently has a network interface that could reach the
  /// internet. Note this is a *best-effort* signal, not a guarantee of
  /// reachability — the repository still treats remote calls defensively.
  Future<bool> get isConnected;

  /// Emits `true`/`false` as connectivity is gained/lost. Drives the automatic
  /// background sync when the connection returns.
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
