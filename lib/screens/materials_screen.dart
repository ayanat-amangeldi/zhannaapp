import 'package:flutter/material.dart';
import '../widgets/section_tile.dart';
import '../language.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key, this.videoIds});
  final Set<String>? videoIds;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.tr('Уроки', 'Сабақтар'),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('Выберите раздел', 'Бөлімді таңдаңыз'),
          style: const TextStyle(color: Color(0xFF675953)),
        ),
        const SizedBox(height: 28),
        for (final section in const [
          (
            'assets/images/home_workout.jpg',
            LocalizedText('Тренировки', 'Жаттығулар'),
            LocalizedText('Видео занятий', 'Бейнесабақтар'),
          ),
          (
            'assets/images/home_vacuum.jpg',
            LocalizedText('Вакуум', 'Вакуум'),
            LocalizedText('Техника и видео', 'Техника және бейне'),
          ),
          (
            'assets/images/home_psychology.jpg',
            LocalizedText('Психологические уроки', 'Психологиялық сабақтар'),
            LocalizedText('Уроки марафона', 'Марафон сабақтары'),
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFE5D9D0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    openDraftSection(context, section.$2, videoIds: videoIds),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 4,
                        fit: FlexFit.tight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            section.$1,
                            height: 100,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.$2.resolve(context),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              section.$3.resolve(context),
                              style: const TextStyle(color: Color(0xFF675953)),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
