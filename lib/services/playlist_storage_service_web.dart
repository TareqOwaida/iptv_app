// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'package:iptv_app/models/saved_playlist.dart';

class PlaylistStorageService {
  static const String _indexKey = 'iptv.playlists.index.v1';
  static const String _contentPrefix = 'iptv.playlists.content.';

  Future<List<SavedPlaylist>> loadAllPlaylists() async {
    final content = html.window.localStorage[_indexKey];
    if (content == null || content.trim().isEmpty) return <SavedPlaylist>[];
    final dynamic decoded = jsonDecode(content);
    if (decoded is! List<dynamic>) return <SavedPlaylist>[];
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(SavedPlaylist.fromJson)
        .where(
          (playlist) => playlist.id.isNotEmpty && playlist.fileName.isNotEmpty,
        )
        .toList();
  }

  Future<void> _saveIndex(List<SavedPlaylist> playlists) async {
    html.window.localStorage[_indexKey] = jsonEncode(
      playlists.map((playlist) => playlist.toJson()).toList(),
    );
  }

  Future<SavedPlaylist> savePlaylist({
    required String content,
    required String name,
  }) async {
    final current = await loadAllPlaylists();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = '${id}_${_safeFileName(name)}.m3u';
    html.window.localStorage['$_contentPrefix$fileName'] = content;
    final saved = SavedPlaylist(id: id, name: name, fileName: fileName);
    await _saveIndex(<SavedPlaylist>[saved, ...current]);
    return saved;
  }

  Future<String?> loadPlaylistById(String id) async {
    final playlists = await loadAllPlaylists();
    final matches = playlists.where((playlist) => playlist.id == id);
    if (matches.isEmpty) return null;
    return html.window.localStorage['$_contentPrefix${matches.first.fileName}'];
  }

  String _safeFileName(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 'playlist';
    return trimmed
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
