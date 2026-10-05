import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

class NetworkStatusService {
  NetworkStatusService._();

  static final NetworkStatusService instance = NetworkStatusService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _fallbackTimer;
  bool _started = false;
  bool _lastOnline = true;

  Stream<bool> get statusStream => _controller.stream;
  bool get lastOnline => _lastOnline;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    _lastOnline = await _hasInternetConnection();
    _controller.add(_lastOnline);

    try {
      _subscription = _connectivity.onConnectivityChanged.listen(
        (_) async {
          await _refreshStatus();
        },
        onError: (Object _) {
          _subscription?.cancel();
          _subscription = null;
          _startFallbackPolling();
        },
      );
    } on MissingPluginException {
      _startFallbackPolling();
    } on PlatformException {
      _startFallbackPolling();
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _started = false;
  }

  Future<void> _refreshStatus() async {
    final bool current = await _hasInternetConnection();
    if (current == _lastOnline) {
      return;
    }
    _lastOnline = current;
    _controller.add(current);
  }

  void _startFallbackPolling() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _refreshStatus();
    });
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(
        'example.com',
      );
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
