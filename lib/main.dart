import 'package:flutter/material.dart';
import 'package:iptv_app/screens/saved_playlists_page.dart';
import 'package:iptv_app/widgets/network_alert_listener.dart';

void main() {
  runApp(const IptvApp());
}

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IPTV Preview',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1020),
      ),
      home: const NetworkAlertListener(
        child: SavedPlaylistsPage(),
      ),
    );
  }
}
