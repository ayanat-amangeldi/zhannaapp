import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { ru, kk }

class LocalizedText {
  const LocalizedText(this.ru, this.kk);
  final String ru;
  final String kk;
  String resolve(BuildContext context) => context.tr(ru, kk);
}

class LanguageController extends ChangeNotifier {
  LanguageController({this.preferences})
    : value = preferences?.getString('language') == 'kk'
          ? AppLocale.kk
          : AppLocale.ru;
  final SharedPreferences? preferences;
  AppLocale value;
  Future<void> select(AppLocale next) async {
    if (next == value) return;
    value = next;
    notifyListeners();
    await preferences?.setString('language', next.name);
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);
  static LanguageController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()!.notifier!;
}

extension Translation on BuildContext {
  String tr(String ru, String kk) =>
      LanguageScope.of(this).value == AppLocale.kk ? kk : ru;
}

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF1DFE3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final locale in [AppLocale.kk, AppLocale.ru])
              Semantics(
                selected: controller.value == locale,
                child: TextButton(
                  key: ValueKey('language-${locale.name}'),
                  onPressed: () => controller.select(locale),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(52, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: controller.value == locale
                        ? const Color(0xFF75354A)
                        : Colors.transparent,
                    foregroundColor: controller.value == locale
                        ? Colors.white
                        : const Color(0xFF75354A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    locale == AppLocale.kk ? 'ҚАЗ' : 'РУС',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
