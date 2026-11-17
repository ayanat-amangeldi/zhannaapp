# KEZEK SENDE

Мобильный Flutter-прототип марафона на русском и казахском. Данные прототипа хранятся локально.

## Запуск на Mac

1. Установите Flutter SDK и добавьте его в PATH. Для запуска на iOS установите Xcode и симулятор iOS, для Android настройте эмулятор через Device Manager в Android Studio.
2. Откройте симулятор командой `open -a Simulator` или запустите Android-эмулятор.
3. Из корня проекта выполните:

   ```sh
   flutter doctor
   flutter pub get
   flutter devices
   flutter run
   ```

В VS Code можно открыть корень проекта, выбрать устройство и нажать F5 с расширением Flutter.

## Видео уроков

Видео передаются отдельно. Интерфейс и список уроков доступны после клонирования. Для воспроизведения скопируйте оригинальные MP4 в `assets/videos/` и перезапустите сборку. Ожидаемые имена файлов перечислены в `lib/data/bundled_lessons.dart`.

## Проверки

```sh
flutter analyze
flutter test
```
