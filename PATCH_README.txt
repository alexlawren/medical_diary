PATCH ДЛЯ СУЩЕСТВУЮЩЕГО medical_diary

1. Сделайте резервную копию текущей папки проекта.
2. Распакуйте содержимое этого архива В КОРЕНЬ текущего проекта medical_diary с заменой файлов.
3. НЕ удаляйте android, .dart_tool, build или локальные кэши вручную.
4. В терминале VS Code из корня проекта выполните:
   flutter pub get
   flutter run

Будут заменены только:
- lib/services/ocr_parser_service.dart
- lib/viewmodels/health_viewmodel.dart
- lib/views/scan_report_screen.dart
- pubspec.yaml

Будут добавлены:
- assets/tessdata/rus.traineddata
- assets/tessdata/eng.traineddata
- assets/tessdata_config.json

flutter pub get переиспользует уже существующий кэш и скачает только недостающие зависимости для нового OCR.
