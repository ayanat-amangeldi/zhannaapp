import 'package:flutter/material.dart';

import '../content.dart';
import '../language.dart';
import '../marathon_streams.dart';
import '../widgets/section_tile.dart';
import 'streams_screen.dart';

const _burgundy = Color(0xFF75354A);
const _surface = Color(0xFFFFFCF8);
const _outline = Color(0xFFE5D9D0);

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.name,
    required this.onMenu,
    this.stream,
  });

  final String name;
  final MarathonStream? stream;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final flow = stream;
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text(
            context.tr('Привет, $name', 'Сәлем, $name'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            flow == null
                ? context.tr('Пробный поток', 'Сынақ тобы')
                : context.tr(
                    '${flow.name} · до ${streamDateTime(context, flow.endsAt)}',
                    '${flow.name} · ${streamDateTime(context, flow.endsAt)} дейін',
                  ),
            style: const TextStyle(color: Color(0xFF675953), height: 1.35),
          ),
          const SizedBox(height: 16),
          _MenuCard(onTap: onMenu),
          const SizedBox(height: 12),
          for (final section in _homeSections) ...[
            _SectionCard(
              title: section.title.resolve(context),
              image: section.image,
              onTap: () => openDraftSection(
                context,
                section.title,
                videoIds: stream?.videoIds,
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () => openDraftSection(
              context,
              helpSection,
              videoIds: stream?.videoIds,
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _outline),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            child: Text(
              helpSection.resolve(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _burgundy,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Моё меню', 'Менің мәзірім'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.tr(
                        'Выбрать блюда на неделю',
                        'Аптаға тағам таңдау',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFFFF4F6),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1.1,
                child: _HomeThumbnail(
                  image: 'assets/images/home_menu.jpg',
                  radius: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.image,
    required this.onTap,
  });
  final String title;
  final String? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(21),
      side: const BorderSide(color: _outline),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 46,
              child: _HomeThumbnail(image: image, radius: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 22, color: _burgundy),
          ],
        ),
      ),
    ),
  );
}

class _HomeThumbnail extends StatelessWidget {
  const _HomeThumbnail({required this.image, required this.radius});
  final String? image;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: image == null
        ? const ColoredBox(
            color: Color(0xFFF1DFE3),
            child: Icon(Icons.assignment_outlined, size: 26, color: _burgundy),
          )
        : Image.asset(image!, fit: BoxFit.cover, excludeFromSemantics: true),
  );
}

const _homeSections = <({LocalizedText title, String? image})>[
  (
    title: LocalizedText('О марафоне', 'Марафон туралы'),
    image: 'assets/images/home_marathon.jpg',
  ),
  (
    title: LocalizedText('Вакуум', 'Вакуум'),
    image: 'assets/images/home_vacuum.jpg',
  ),
  (
    title: LocalizedText('Психологические уроки', 'Психологиялық сабақтар'),
    image: 'assets/images/home_psychology.jpg',
  ),
  (
    title: LocalizedText('Тренировки', 'Жаттығулар'),
    image: 'assets/images/home_workout.jpg',
  ),
  (title: healthSection, image: null),
];
