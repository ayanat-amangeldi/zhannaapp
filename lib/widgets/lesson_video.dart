import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../content.dart';
import '../language.dart';

class LessonVideo extends StatefulWidget {
  const LessonVideo({super.key, required this.path});
  final String path;

  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  VideoPlayerController? player;
  late final ready = _initialize();

  Future<void> _initialize() async {
    final controller = widget.path.startsWith('assets/')
        ? VideoPlayerController.asset(widget.path)
        : VideoPlayerController.file(await localMedia(widget.path));
    if (!mounted) {
      await controller.dispose();
      return;
    }
    player = controller;
    await controller.initialize();
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: ready,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text(
          context.tr(
            'Не удалось открыть видео.',
            'Бейнені ашу мүмкін болмады.',
          ),
        );
      }
      if (snapshot.connectionState != ConnectionState.done || player == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final controller = player!;
      return ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) => Column(
          children: [
            if (value.hasError)
              Text(context.tr('Ошибка воспроизведения.', 'Ойнату қатесі.'))
            else ...[
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .65,
                  ),
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              VideoProgressIndicator(controller, allowScrubbing: true),
              IconButton(
                tooltip: value.isPlaying
                    ? context.tr('Пауза', 'Кідірту')
                    : context.tr('Смотреть', 'Көру'),
                onPressed: value.isPlaying ? controller.pause : controller.play,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
            ],
          ],
        ),
      );
    },
  );
}
