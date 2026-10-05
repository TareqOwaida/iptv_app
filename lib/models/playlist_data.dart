import 'package:iptv_app/models/iptv_channel.dart';

class PlaylistData {
  const PlaylistData({
    required this.channels,
    required this.categories,
  });

  final List<IptvChannel> channels;
  final List<String> categories;
}
