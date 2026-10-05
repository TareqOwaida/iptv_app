import 'dart:convert';

import 'package:iptv_app/models/iptv_channel.dart';
import 'package:iptv_app/models/playlist_data.dart';

PlaylistData parseM3uChannels(String content) {
  final List<String> lines = LineSplitter.split(content)
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList();

  final List<IptvChannel> channels = <IptvChannel>[];
  final Set<String> categories = <String>{};

  String pendingName = 'Unknown Channel';
  String? pendingCategory;
  final Map<String, String> pendingHttpHeaders = <String, String>{};
  int unnamedCounter = 1;

  for (final String line in lines) {
    if (line.startsWith('#EXTINF')) {
      final int commaIndex = line.lastIndexOf(',');
      if (commaIndex != -1 && commaIndex < line.length - 1) {
        pendingName = line.substring(commaIndex + 1).trim();
      } else {
        pendingName = 'Channel $unnamedCounter';
        unnamedCounter++;
      }

      pendingCategory =
          _extractAttribute(line, 'group-title') ??
          _extractAttribute(line, 'tvg-group');
      pendingHttpHeaders.clear();
      continue;
    }

    if (_isExtVlcOptLine(line)) {
      _mergeVlcOptLine(line, pendingHttpHeaders);
      continue;
    }

    if (line.startsWith('#')) {
      continue;
    }

    if (_isSupportedStreamScheme(line)) {
      final IptvChannel channel = IptvChannel(
        name: pendingName.isEmpty ? 'Channel $unnamedCounter' : pendingName,
        url: line,
        category: pendingCategory?.trim().isEmpty ?? true
            ? null
            : pendingCategory?.trim(),
        httpHeaders: pendingHttpHeaders.isEmpty
            ? null
            : Map<String, String>.from(pendingHttpHeaders),
      );
      channels.add(channel);

      if (channel.category != null) {
        categories.add(channel.category!);
      }

      pendingName = 'Unknown Channel';
      pendingCategory = null;
    }
  }

  final List<String> orderedCategories = categories.toList()..sort();
  return PlaylistData(channels: channels, categories: orderedCategories);
}

bool _isSupportedStreamScheme(String line) {
  return line.startsWith('http://') ||
      line.startsWith('https://') ||
      line.startsWith('rtmp://') ||
      line.startsWith('rtsp://');
}

String? _extractAttribute(String line, String attributeName) {
  final RegExp regExp = RegExp('$attributeName="([^"]+)"');
  final RegExpMatch? match = regExp.firstMatch(line);
  return match?.group(1);
}

bool _isExtVlcOptLine(String line) {
  return line.length > 11 &&
      line.substring(0, 11).toUpperCase() == '#EXTVLCOPT:';
}

void _mergeVlcOptLine(String line, Map<String, String> out) {
  final int firstColon = line.indexOf(':');
  if (firstColon == -1 || firstColon >= line.length - 1) {
    return;
  }
  final String rest = line.substring(firstColon + 1).trim();
  final int eq = rest.indexOf('=');
  if (eq <= 0) {
    return;
  }
  String value = rest.substring(eq + 1).trim();
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    value = value.substring(1, value.length - 1);
  }
  final String key = rest.substring(0, eq).trim().toLowerCase();
  if (key == 'http-user-agent') {
    out['User-Agent'] = value;
  } else if (key == 'http-referrer' || key == 'http-referer') {
    out['Referer'] = value;
  } else if (key == 'http-origin') {
    out['Origin'] = value;
  }
}
