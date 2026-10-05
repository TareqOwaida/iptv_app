import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class PlaylistImportResult {
  const PlaylistImportResult({required this.content, required this.sourceName});

  final String content;
  final String sourceName;
}

class PlaylistImportService {
  Future<PlaylistImportResult?> pickLocalFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['m3u', 'm3u8', 'txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final PlatformFile file = result.files.first;
    final String? content = _decodeBytes(file.bytes);
    if (content == null || content.trim().isEmpty) {
      throw Exception('Could not read content from selected file.');
    }

    return PlaylistImportResult(content: content, sourceName: file.name);
  }

  Future<PlaylistImportResult> importFromUrl(String rawUrl) async {
    final Uri url = Uri.parse(rawUrl.trim());
    final http.Response response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download playlist (HTTP ${response.statusCode}).',
      );
    }

    final String content = utf8.decode(
      response.bodyBytes,
      allowMalformed: true,
    );
    if (content.trim().isEmpty) {
      throw Exception('Downloaded file is empty.');
    }

    return PlaylistImportResult(content: content, sourceName: url.host);
  }

  String? _decodeBytes(Uint8List? bytes) {
    if (bytes == null) {
      return null;
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
