import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/services.dart';

class MediaViewerScreen extends StatelessWidget {
  final String url;
  final String type;

  const MediaViewerScreen({super.key, required this.url, required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == 'photo') {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(244, 225, 102, 1.0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("Photo Viewer"),
        ),
        body: Center(
          child: Image.network(
            url,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator();
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, size: 80);
            },
          ),
        ),
      );
    } else if (type == 'video') {
      return BetterPlayerScreen(videoUrl: url);
    } else {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(244, 225, 102, 1.0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("File Viewer"),
        ),
        body: const Center(
          child: Text(
            "Preview not supported.\nDownload or open in browser.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}

class BetterPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const BetterPlayerScreen({super.key, required this.videoUrl});

  @override
  State<BetterPlayerScreen> createState() => _BetterPlayerScreenState();
}

class _BetterPlayerScreenState extends State<BetterPlayerScreen> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.videoUrl,
      notificationConfiguration: BetterPlayerNotificationConfiguration(
        showNotification: true,
        title: "Video Playing",
        author: "Zerolimit App",
      ),
    );

    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: false,
        fit: BoxFit.contain,
        allowedScreenSleep: false,
        autoDetectFullscreenDeviceOrientation: false,
        handleLifecycle: true,
        fullScreenByDefault: false,
        expandToFill: false,
        useRootNavigator: true,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          enableFullscreen: true,
          enableMute: true,
          enablePlaybackSpeed: true,
          enableSubtitles: false,
        ),
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
        deviceOrientationsOnFullScreen: [
          DeviceOrientation.portraitUp,
        ],
      ),
    );

    _betterPlayerController.setupDataSource(dataSource).then((_) {
      final videoSize = _betterPlayerController.videoPlayerController?.value.size;
      if (videoSize != null && videoSize.width > 0 && videoSize.height > 0) {
        final dynamicAspectRatio = videoSize.width / videoSize.height;
        _betterPlayerController.setOverriddenAspectRatio(dynamicAspectRatio);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Video Viewer"),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _betterPlayerController.videoPlayerController?.value.aspectRatio ?? 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
        ],
      ),
    );
  }
}
