import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a [Stream] (a Cubit's state stream) to the [Listenable] that
/// go_router's `refreshListenable` expects, so route guards re-run whenever
/// auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
