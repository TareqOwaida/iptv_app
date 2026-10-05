import 'package:flutter/material.dart';
import 'package:iptv_app/models/iptv_channel.dart';
import 'package:iptv_app/models/playlist_data.dart';
import 'package:iptv_app/models/saved_playlist.dart';
import 'package:iptv_app/services/playlist_parser.dart';
import 'package:iptv_app/services/playlist_storage_service.dart';
import 'package:iptv_app/screens/channel_player_page.dart';

class IptvHomePage extends StatefulWidget {
  const IptvHomePage({super.key, required this.playlist});

  final SavedPlaylist playlist;

  @override
  State<IptvHomePage> createState() => _IptvHomePageState();
}

class _IptvHomePageState extends State<IptvHomePage> {
  final TextEditingController _searchController = TextEditingController();

  final PlaylistStorageService _storageService = PlaylistStorageService();

  List<IptvChannel> _channels = <IptvChannel>[];
  List<String> _categories = <String>[];
  String? _selectedCategory;
  String _sourceFileName = '';
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sourceFileName = widget.playlist.name;
    _loadPlaylist();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasCategories => _categories.isNotEmpty;

  List<IptvChannel> get _visibleChannels {
    final String query = _searchController.text.trim().toLowerCase();

    Iterable<IptvChannel> channels = _channels;
    if (_hasCategories && _selectedCategory != null) {
      channels = channels.where(
        (IptvChannel c) => c.category == _selectedCategory,
      );
    }
    if (query.isNotEmpty) {
      channels = channels.where(
        (IptvChannel c) =>
            c.name.toLowerCase().contains(query) ||
            c.url.toLowerCase().contains(query),
      );
    }
    return channels.toList();
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final String? content = await _storageService.loadPlaylistById(
        widget.playlist.id,
      );
      if (content == null || content.trim().isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Saved playlist file not found.';
        });
        return;
      }
      _applyPlaylist(content: content, sourceName: widget.playlist.name);
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load playlist: $error';
      });
    }
  }

  void _applyPlaylist({required String content, required String sourceName}) {
    final PlaylistData parsed = parseM3uChannels(content);
    setState(() {
      _channels = parsed.channels;
      _categories = parsed.categories;
      _selectedCategory = parsed.categories.isNotEmpty
          ? parsed.categories.first
          : null;
      _sourceFileName = sourceName;
      _isLoading = false;
      _errorMessage = parsed.channels.isEmpty
          ? 'No channels found. Please select a valid M3U playlist.'
          : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<IptvChannel> channels = _visibleChannels;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryFixedVariant,
        title: const Text('IPTV Playlist Preview'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reload from saved file',
            onPressed: _isLoading ? null : _loadPlaylist,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      drawer: _hasCategories ? _buildCategoryDrawer() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF0B1020), Color(0xFF141E39)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.playlist_play),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Source: $_sourceFileName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search channels...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFF1B2545),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              Expanded(child: _buildChannelGrid(context, channels)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelGrid(BuildContext context, List<IptvChannel> channels) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (channels.isEmpty) {
      return Center(
        child: Text(
          _channels.isEmpty
              ? 'No channels in this playlist.'
              : 'No channels match your search or category.',
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
          itemCount: channels.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.4 : 1.1,
          ),
          itemBuilder: (BuildContext context, int index) {
            final IptvChannel channel = channels[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChannelPlayerPage(channel: channel),
                  ),
                );
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
                          channel.name,
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

  Drawer _buildCategoryDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            ListTile(
              title: const Text('Categories'),
              subtitle: Text('${_categories.length} group(s)'),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (BuildContext context, int index) {
                  final String category = _categories[index];
                  final bool selected = category == _selectedCategory;
                  return ListTile(
                    selected: selected,
                    title: Text(category),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
