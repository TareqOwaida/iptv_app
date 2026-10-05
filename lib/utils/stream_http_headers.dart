import 'package:iptv_app/models/iptv_channel.dart';
import 'package:video_player/video_player.dart';

/// Many IPTV endpoints reject ExoPlayer's default User-Agent; VLC-style UA fixes
/// common `ExoPlaybackException: Source error` failures.
Map<String, String> streamRequestHeaders(IptvChannel channel) {
  return <String, String>{
    'User-Agent': 'VLC/3.0.20 (Linux; Android 12) LibVLC/3.0.20',
    'Accept': '*/*',
    ...?channel.httpHeaders,
  };
}

VideoFormat? formatHintForStreamUrl(String url) {
  final String u = url.toLowerCase();
  if (u.contains('.m3u8') ||
      u.contains('/playlist.m3u') ||
      u.contains('application/x-mpegurl') ||
      u.contains('type=m3u')) {
    return VideoFormat.hls;
  }
  if (u.contains('.mpd')) {
    return VideoFormat.dash;
  }
  return null;
}
