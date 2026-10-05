import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iptv_app/services/network_status_service.dart';

class NetworkAlertListener extends StatefulWidget {
  const NetworkAlertListener({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkAlertListener> createState() => _NetworkAlertListenerState();
}

class _NetworkAlertListenerState extends State<NetworkAlertListener> {
  StreamSubscription<bool>? _subscription;
  bool _offlineBannerVisible = false;

  @override
  void initState() {
    super.initState();
    _initMonitoring();
  }

  Future<void> _initMonitoring() async {
    await NetworkStatusService.instance.start();

    if (!mounted) {
      return;
    }
    _applyStatus(NetworkStatusService.instance.lastOnline, showBackOnlineSnack: false);

    _subscription = NetworkStatusService.instance.statusStream.listen((bool online) {
      if (!mounted) {
        return;
      }
      _applyStatus(online, showBackOnlineSnack: true);
    });
  }

  void _applyStatus(bool online, {required bool showBackOnlineSnack}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!online) {
      if (_offlineBannerVisible) {
        return;
      }
      messenger.clearSnackBars();
      messenger.showMaterialBanner(
        MaterialBanner(
          content: const Text('No internet connection. Some features may not work.'),
          leading: const Icon(Icons.wifi_off),
          backgroundColor: const Color(0xFF4B1D1D),
          actions: <Widget>[
            TextButton(
              onPressed: () {},
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _offlineBannerVisible = true;
      return;
    }

    if (_offlineBannerVisible) {
      messenger.hideCurrentMaterialBanner();
      _offlineBannerVisible = false;
    }
    if (showBackOnlineSnack) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Back online'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
