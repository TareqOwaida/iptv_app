import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:iptv_app/models/iptv_channel.dart';
import 'package:iptv_app/utils/stream_http_headers.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:video_player/video_player.dart';

class ChannelPlayerPage extends StatefulWidget {
  const ChannelPlayerPage({super.key, required this.channel});

  final IptvChannel channel;

  @override
  State<ChannelPlayerPage> createState() => _ChannelPlayerPageState();
}

class _ChannelPlayerPageState extends State<ChannelPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String _errorText = '';
  bool _keepScreenForcedOn = false;

  @override
  void initState() {
    super.initState();
    _openStream();
  }

  Future<void> _openStream() async {
    final VideoPlayerController controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.channel.url),
      httpHeaders: streamRequestHeaders(widget.channel),
      formatHint: formatHintForStreamUrl(widget.channel.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await controller.initialize();
      controller.addListener(_onVideoTick);

      final ChewieController chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        showControlsOnInitialize: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        allowMuting: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.redAccent,
          handleColor: Colors.redAccent,
          bufferedColor: Colors.white38,
          backgroundColor: Colors.white24,
        ),
      );

      controller.play();
      if (!mounted) {
        chewieController.dispose();
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _chewieController = chewieController;
        _errorText = '';
      });
      unawaited(_syncKeepScreenOnState());
    } catch (error) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Cannot open this stream: $error';
      });
    }
  }

  void _onVideoTick() {
    final VideoPlayerController? c = _videoController;
    if (c != null && c.value.hasError) {
      final String? desc = c.value.errorDescription;
      if (mounted && _errorText.isEmpty) {
        setState(() {
          _errorText =
              'Playback failed${desc != null && desc.isNotEmpty ? ': $desc' : ''}';
        });
      }
    }
    unawaited(_syncKeepScreenOnState());
  }

  double _dynamicAspectRatio(BuildContext context) {
    final VideoPlayerController? controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      final double ratio = controller.value.aspectRatio;
      if (ratio > 0) {
        return ratio;
      }
    }
    final Size size = MediaQuery.of(context).size;
    return size.width / size.height;
  }

  bool get _shouldKeepScreenOn {
    final VideoPlayerController? controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return false;
    }
    return controller.value.isPlaying && !controller.value.hasError;
  }

  Future<void> _syncKeepScreenOnState() async {
    final bool shouldKeepScreenOn = _shouldKeepScreenOn;
    if (shouldKeepScreenOn == _keepScreenForcedOn) {
      return;
    }
    final bool success = shouldKeepScreenOn
        ? await KeepScreenOn.turnOn()
        : await KeepScreenOn.turnOff();
    if (success) {
      _keepScreenForcedOn = shouldKeepScreenOn;
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoTick);
    _chewieController?.dispose();
    _videoController?.dispose();
    unawaited(KeepScreenOn.turnOff());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.channel.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _errorText.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          : _buildPlayer(context),
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final ChewieController? chewieController = _chewieController;
    if (chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF0B1020), Color(0xFF141E39)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: _dynamicAspectRatio(context),
          child: Chewie(controller: chewieController),
        ),
      ),
    );
  }
}
