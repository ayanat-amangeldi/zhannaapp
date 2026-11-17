import 'package:flutter/material.dart';
import '../language.dart';
import '../content.dart';
import 'lesson_video.dart';
import 'whatsapp_contact.dart';

class SectionTile extends StatelessWidget {
  const SectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: const Color(0xFFFFFCF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5D9D0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1DFE3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF75354A)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    ),
  );
}

void openDraftSection(
  BuildContext context,
  LocalizedText title, {
  Set<String>? videoIds,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => title.ru == healthSection.ru
          ? _HealthSectionScreen(videoIds: videoIds)
          : Scaffold(
              appBar: AppBar(
                title: Text(title.resolve(context)),
                actions: const [LanguageSwitch()],
              ),
              body: title == helpSection
                  ? SafeArea(
                      child: Column(
                        children: [
                          const WhatsAppContactButton(),
                          Expanded(
                            child: _SectionMaterials(
                              title: title,
                              videoIds: videoIds,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _SectionMaterials(title: title, videoIds: videoIds),
            ),
    ),
  );
}

class _HealthSectionScreen extends StatefulWidget {
  const _HealthSectionScreen({this.videoIds});
  final Set<String>? videoIds;

  @override
  State<_HealthSectionScreen> createState() => _HealthSectionScreenState();
}

class _HealthSectionScreenState extends State<_HealthSectionScreen> {
  LocalizedText _selected = analysesSection;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(healthSection.resolve(context)),
      actions: const [LanguageSwitch()],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              for (final section in [analysesSection, vitaminsSection])
                Expanded(
                  child: Semantics(
                    selected: _selected == section,
                    child: TextButton(
                      key: ValueKey('health-${section.ru}'),
                      onPressed: () => setState(() => _selected = section),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 12,
                        ),
                        backgroundColor: _selected == section
                            ? const Color(0xFFF1DFE3)
                            : Colors.transparent,
                        foregroundColor: _selected == section
                            ? const Color(0xFF75354A)
                            : const Color(0xFF806D65),
                      ),
                      child: Text(
                        section.resolve(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selected == section
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _SectionMaterials(
            key: ValueKey(_selected.ru),
            title: _selected,
            videoIds: widget.videoIds,
          ),
        ),
      ],
    ),
  );
}

class _SectionMaterials extends StatelessWidget {
  const _SectionMaterials({super.key, required this.title, this.videoIds});
  final LocalizedText title;
  final Set<String>? videoIds;

  @override
  Widget build(BuildContext context) {
    final lessons = ContentScope.of(context).lessons
        .where(
          (lesson) =>
              lesson.section == title.ru &&
              (!lesson.hasVideo || (videoIds?.contains(lesson.id) ?? true)),
        )
        .toList();
    if (lessons.isEmpty && title == helpSection) return const SizedBox.shrink();
    if (lessons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                size: 56,
                color: Color(0xFF75354A),
              ),
              const SizedBox(height: 20),
              Text(
                title.resolve(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Материалы этого раздела появятся здесь.',
                  'Бұл бөлімнің материалдары осында пайда болады.',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final (index, lesson) in lessons.indexed)
          SectionTile(
            icon: lesson.hasVideo
                ? Icons.play_circle_outline
                : Icons.article_outlined,
            title: lesson.title.resolve(context),
            subtitle: lesson.hasVideo
                ? _videoLabel(context, _videoFor(lesson, context).language)
                : context.tr('Текст', 'Мәтін'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _LessonDetailScreen(
                  lessons: lessons,
                  initialIndex: index,
                  showNavigation:
                      title.ru == 'Психологические уроки' ||
                      title.ru == 'Тренировки',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LessonDetailScreen extends StatefulWidget {
  const _LessonDetailScreen({
    required this.lessons,
    required this.initialIndex,
    required this.showNavigation,
  });

  final List<Lesson> lessons;
  final int initialIndex;
  final bool showNavigation;

  @override
  State<_LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<_LessonDetailScreen> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lessons[_index];
    final video = _videoFor(lesson, context);
    final description = lesson.description.resolve(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title.resolve(context)),
        actions: const [LanguageSwitch()],
      ),
      body: ListView(
        key: ValueKey(lesson.id),
        padding: const EdgeInsets.all(20),
        children: [
          if (video.path.isNotEmpty) ...[
            Text(_videoLabel(context, video.language)),
            const SizedBox(height: 10),
            LessonVideo(key: ValueKey(video.path), path: video.path),
            const SizedBox(height: 16),
          ],
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(fontSize: 16, height: 1.55),
            ),
        ],
      ),
      bottomNavigationBar: widget.showNavigation
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index == 0
                            ? null
                            : () => setState(() => _index--),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(context.tr('Назад', 'Артқа')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _index + 1 == widget.lessons.length
                            ? null
                            : () => setState(() => _index++),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(context.tr('Вперёд', 'Алға')),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

({String path, AppLocale language}) _videoFor(
  Lesson lesson,
  BuildContext context,
) {
  final selected = LanguageScope.of(context).value;
  if (selected == AppLocale.ru && lesson.video.ru.isNotEmpty ||
      selected == AppLocale.kk && lesson.video.kk.isEmpty) {
    return (path: lesson.video.ru, language: AppLocale.ru);
  }
  return (path: lesson.video.kk, language: AppLocale.kk);
}

String _videoLabel(BuildContext context, AppLocale language) =>
    language == AppLocale.kk
    ? context.tr('Видео на казахском', 'Бейне қазақ тілінде')
    : context.tr('Видео на русском', 'Бейне орыс тілінде');
