import 'package:flutter/material.dart';
import 'package:iptv_app/models/iptv_channel.dart';

class ChannelList extends StatelessWidget {
  const ChannelList({
    super.key,
    required this.channels,
    required this.selectedChannel,
    required this.onSelect,
    required this.isLoading,
  });

  final List<IptvChannel> channels;
  final IptvChannel? selectedChannel;
  final ValueChanged<IptvChannel> onSelect;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (channels.isEmpty) {
      return Center(
        child: Text(
          'No channels to display',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return Card(
      elevation: 0,
      color: const Color(0xFF131A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF2A355A)),
      ),
      child: ListView.separated(
        itemCount: channels.length,
        separatorBuilder: (_, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final IptvChannel channel = channels[index];
          final bool isSelected = selectedChannel?.url == channel.url;

          return ListTile(
            selected: isSelected,
            selectedTileColor: const Color(0xFF233156),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(channel.name),
            subtitle: Text(
              channel.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSelect(channel),
          );
        },
      ),
    );
  }
}
