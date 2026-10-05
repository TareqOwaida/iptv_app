import 'package:flutter/material.dart';
import 'package:iptv_app/models/saved_playlist.dart';
import 'package:iptv_app/screens/iptv_home_page.dart';
import 'package:iptv_app/services/playlist_import_service.dart';
import 'package:iptv_app/services/playlist_storage_service.dart';

class SavedPlaylistsPage extends StatefulWidget {
  const SavedPlaylistsPage({super.key});

  @override
  State<SavedPlaylistsPage> createState() => _SavedPlaylistsPageState();
}

class _SavedPlaylistsPageState extends State<SavedPlaylistsPage> {
  final PlaylistStorageService _storageService = PlaylistStorageService();
  final PlaylistImportService _importService = PlaylistImportService();

  List<SavedPlaylist> _playlists = <SavedPlaylist>[];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final List<SavedPlaylist> loaded = await _storageService
          .loadAllPlaylists();
      setState(() {
        _playlists = loaded;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load saved playlists: $error';
      });
    }
  }

  Future<void> _importLocalFile() async {
    try {
      final PlaylistImportResult? result = await _importService.pickLocalFile();
      if (result == null) {
        return;
      }
      await _storageService.savePlaylist(
        content: result.content,
        name: result.sourceName,
      );
      await _loadPlaylists();
    } catch (error) {
      setState(() {
        _error = 'Import failed: $error';
      });
    }
  }

  Future<void> _importFromCloudUrl() async {
    final TextEditingController controller = TextEditingController();
    final String? url = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 13, 13, 13),
          title: const Text('Import from online URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Playlist URL',
              hintText: 'https://example.com/playlist.m3u',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    if (url == null || url.isEmpty) {
      return;
    }

    try {
      final PlaylistImportResult result = await _importService.importFromUrl(
        url,
      );
      await _storageService.savePlaylist(
        content: result.content,
        name: 'Cloud ${result.sourceName}',
      );
      await _loadPlaylists();
    } catch (error) {
      setState(() {
        _error = 'URL import failed: $error';
      });
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Saved IPTV Playlists'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPlaylists,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: screenWidth - 32,
        child: Row(
          children: <Widget>[
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'saved_local_import',
                onPressed: _importLocalFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Local Import'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'saved_cloud_import',
                onPressed: _importFromCloudUrl,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Cloud Import'),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF0B1020), Color(0xFF141E39)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Text(_error, style: const TextStyle(color: Colors.redAccent)),
      );
    }

    if (_playlists.isEmpty) {
      return Center(
        child: Text(
          'No saved IPTV files yet.\nUse the bottom import buttons.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width >= 1100
            ? 5
            : width >= 760
            ? 4
            : width >= 460
            ? 3
            : 2;

        return GridView.builder(
          itemCount: _playlists.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.4 : 1.1,
          ),
          itemBuilder: (BuildContext context, int index) {
            final SavedPlaylist playlist = _playlists[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => IptvHomePage(playlist: playlist),
                  ),
                );
                _loadPlaylists();
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2A355A)),
                ),
                child: Card(
                  elevation: 0,
                  color: const Color(0xFF131A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFF2A355A)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.live_tv, size: 44),
                        const SizedBox(height: 10),
                        Text(
                          playlist.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
