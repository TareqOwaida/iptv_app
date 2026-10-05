import 'dart:convert';
import 'dart:io';

import 'package:iptv_app/models/saved_playlist.dart';
import 'package:path_provider/path_provider.dart';

class PlaylistStorageService {
  static const String _libraryFolderName = 'playlists';
  static const String _indexFileName = 'playlists_index.json';

  Future<Directory> _libraryDirectory() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory libraryDir = Directory(
      '${dir.path}${Platform.pathSeparator}$_libraryFolderName',
    );
    if (!await libraryDir.exists()) {
      await libraryDir.create(recursive: true);
    }
    return libraryDir;
  }

  Future<File> _indexFile() async {
    final Directory libraryDir = await _libraryDirectory();
    return File('${libraryDir.path}${Platform.pathSeparator}$_indexFileName');
  }

  Future<File> _playlistFileByName(String fileName) async {
    final Directory libraryDir = await _libraryDirectory();
    return File('${libraryDir.path}${Platform.pathSeparator}$fileName');
  }

  Future<List<SavedPlaylist>> loadAllPlaylists() async {
    final File file = await _indexFile();
    if (!await file.exists()) return <SavedPlaylist>[];
    final String content = await file.readAsString();
    if (content.trim().isEmpty) return <SavedPlaylist>[];
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
    final File file = await _indexFile();
    await file.writeAsString(
      jsonEncode(playlists.map((playlist) => playlist.toJson()).toList()),
      flush: true,
    );
  }

  Future<SavedPlaylist> savePlaylist({
    required String content,
    required String name,
  }) async {
    final current = await loadAllPlaylists();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = '${id}_${_safeFileName(name)}.m3u';
    final playlistFile = await _playlistFileByName(fileName);
    await playlistFile.writeAsString(content, flush: true);
    final saved = SavedPlaylist(id: id, name: name, fileName: fileName);
    await _saveIndex(<SavedPlaylist>[saved, ...current]);
    return saved;
  }

  Future<String?> loadPlaylistById(String id) async {
    final playlists = await loadAllPlaylists();
    final matches = playlists.where((playlist) => playlist.id == id);
    if (matches.isEmpty) return null;
    final file = await _playlistFileByName(matches.first.fileName);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  String _safeFileName(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 'playlist';
    return trimmed
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
