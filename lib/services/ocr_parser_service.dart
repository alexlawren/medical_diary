import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

import '../models/lab_report.dart';

/// Ошибка, когда OCR отработал, но полезные показатели из бланка извлечь не удалось.
class OcrParsingException implements Exception {
  final String message;

  const OcrParsingException(this.message);

  @override
  String toString() => message;
}

/// Сервис OCR + разбора печатного лабораторного бланка.
///
/// Для Android используется локальный Tesseract и языковые модели rus+eng,
/// лежащие в assets/tessdata. Интернет и Google Play Services не требуются.
class OcrParserService {
  String _lastRecognizedText = '';

  String get lastRecognizedText => _lastRecognizedText;

  Future<LabReport> processImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw const OcrParsingException('Файл фотографии не найден.');
    }

    // PSM 6 хорошо подходит для одного печатного документа/таблицы.
    final rawText = await FlutterTesseractOcr.extractText(
      imageFile.path,
      language: 'rus+eng',
      args: const {
        'psm': '6',
        'preserve_interword_spaces': '1',
      },
    );

    _lastRecognizedText = rawText;

    if (kDebugMode) {
      debugPrint('===== OCR RAW TEXT =====');
      debugPrint(rawText);
      debugPrint('===== /OCR RAW TEXT =====');
    }

    if (rawText.trim().isEmpty) {
      throw const OcrParsingException(
        'Текст на фотографии не распознан. Сделайте снимок ближе, без бликов и смазывания.',
      );
    }

    final normalizedText = _normalize(rawText);
    final laboratory = _detectLaboratory(normalizedText);
    final title = _detectReportTitle(normalizedText);
    final date = _detectReportDate(normalizedText) ?? DateTime.now();
    final markers = _extractMarkers(rawText);

    // В старой версии здесь подставлялись фиксированные «демо»-значения,
    // из-за чего любое фото давало один и тот же результат. Теперь данные
    // никогда не выдумываются: если таблицу разобрать не удалось — показываем ошибку.
    if (markers.isEmpty) {
      throw const OcrParsingException(
        'Текст распознан, но лабораторные показатели не найдены. '
        'Сфотографируйте таблицу крупнее и убедитесь, что названия и значения читаемы.',
      );
    }

    return LabReport(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      date: date,
      laboratory: laboratory,
      markers: markers,
    );
  }

  String _detectLaboratory(String text) {
    if (text.contains('хеликс') || text.contains('helix')) {
      return 'Лабораторная служба Хеликс';
    }
    if (text.contains('инвитро') || text.contains('invitro')) {
      return 'Независимая лаборатория Инвитро';
    }
    if (text.contains('гемотест') || text.contains('gemotest')) {
      return 'Лаборатория Гемотест';
    }
    return 'Лаборатория (по фото)';
  }

  String _detectReportTitle(String text) {
    if (text.contains('общий анализ мочи') ||
        (text.contains('анализ') && text.contains('мочи'))) {
      return 'Общий анализ мочи';
    }
    if (text.contains('биохим')) {
      return 'Биохимический анализ крови';
    }
    if (text.contains('общий анализ крови') ||
        text.contains('клинический анализ крови') ||
        text.contains('оак')) {
      return 'Клинический анализ крови (ОАК)';
    }
    return 'Лабораторное исследование';
  }

  DateTime? _detectReportDate(String text) {
    // В первую очередь ищем дату рядом с фразой о выполнении исследования.
    final preferredPatterns = <RegExp>[
      RegExp(
        r'(?:дата\s+выполнения\s+исследования|исследование\s+выполнено)[^\n]{0,80}?(\d{2}[.\-/]\d{2}[.\-/]\d{4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:регистрац\w*|дата\s+забора)[^\n]{0,50}?(\d{2}[.\-/]\d{2}[.\-/]\d{4})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in preferredPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final parsed = _parseDate(match.group(1)!);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  DateTime? _parseDate(String value) {
    final parts = value.split(RegExp(r'[.\-/]'));
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  List<LabMarker> _extractMarkers(String rawText) {
    final markerDefinitions = <Map<String, Object>>[
      {
        'aliases': ['удельный вес', 'удельн'],
        'name': 'Удельный вес',
        'unit': '',
        'min': 1.003,
        'max': 1.030,
      },
      {
        'aliases': ['реакция (ph)', 'реакция ph', 'реакци'],
        'name': 'Реакция (pH)',
        'unit': 'pH',
        'min': 5.0,
        'max': 7.5,
      },
      {
        'aliases': ['белок'],
        'name': 'Белок',
        'unit': 'г/л',
        'min': 0.0,
        'max': 0.1,
      },
      {
        'aliases': ['лейкоцит'],
        'name': 'Лейкоциты',
        'unit': '',
        'min': 0.0,
        'max': 5.0,
      },
      {
        'aliases': ['гемоглобин'],
        'name': 'Гемоглобин',
        'unit': 'г/л',
        'min': 120.0,
        'max': 160.0,
      },
      {
        'aliases': ['эритроцит'],
        'name': 'Эритроциты',
        'unit': '10^12/л',
        'min': 3.8,
        'max': 5.1,
      },
      {
        'aliases': ['тромбоцит'],
        'name': 'Тромбоциты',
        'unit': '10^9/л',
        'min': 150.0,
        'max': 400.0,
      },
      {
        'aliases': ['соэ'],
        'name': 'СОЭ',
        'unit': 'мм/ч',
        'min': 2.0,
        'max': 15.0,
      },
      {
        'aliases': ['глюкоз'],
        'name': 'Глюкоза',
        'unit': 'ммоль/л',
        'min': 4.1,
        'max': 5.9,
      },
      {
        'aliases': ['билирубин'],
        'name': 'Билирубин',
        'unit': 'мкмоль/л',
        'min': 3.4,
        'max': 20.5,
      },
    ];

    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_cleanLine)
        .where((line) => line.isNotEmpty)
        .toList();

    final detected = <LabMarker>[];

    for (final definition in markerDefinitions) {
      final aliases = (definition['aliases'] as List<String>);
      final name = definition['name'] as String;
      final defaultUnit = definition['unit'] as String;
      final defaultMin = definition['min'] as double;
      final defaultMax = definition['max'] as double;

      for (var i = 0; i < lines.length; i++) {
        final normalizedLine = _normalize(lines[i]);
        String? alias;
        for (final candidate in aliases) {
          if (normalizedLine.contains(candidate)) {
            alias = candidate;
            break;
          }
        }

        if (alias == null) continue;

        // Сначала разбираем только текущую строку таблицы.
        // Следующую строку используем только если OCR отделил значение
        // от названия показателя и в текущей строке чисел вообще нет.
        final normalizedCurrent = _normalize(lines[i]);
        final aliasIndex = normalizedCurrent.indexOf(alias);
        var sourceAfterName = aliasIndex >= 0
            ? normalizedCurrent.substring(aliasIndex + alias.length)
            : normalizedCurrent;

        var numbers = _extractNumbers(sourceAfterName);
        if (numbers.isEmpty && i + 1 < lines.length) {
          sourceAfterName = _normalize(lines[i + 1]);
          numbers = _extractNumbers(sourceAfterName);
        }

        if (numbers.isEmpty) continue;

        final value = numbers.first;

        var minNormal = defaultMin;
        var maxNormal = defaultMax;

        // Если на самом бланке распознана колонка «Норма», используем ее.
        // Для строки вида «Белок 0.15 г/л 0.0-0.1» числа: 0.15, 0.0, 0.1.
        if (numbers.length >= 3) {
          final possibleMin = numbers[numbers.length - 2];
          final possibleMax = numbers.last;
          if (possibleMin <= possibleMax) {
            minNormal = possibleMin;
            maxNormal = possibleMax;
          }
        }

        detected.add(
          LabMarker(
            name: name,
            value: value,
            unit: _detectUnit(lines[i], defaultUnit),
            minNormal: minNormal,
            maxNormal: maxNormal,
          ),
        );
        break;
      }
    }

    return detected;
  }

  List<double> _extractNumbers(String text) {
    final matches = RegExp(r'\d+(?:[.,]\d+)?').allMatches(text);
    return matches
        .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.')))
        .whereType<double>()
        .toList();
  }

  String _detectUnit(String originalLine, String fallback) {
    final line = _normalize(originalLine);

    if (line.contains('в п/зр') || line.contains('вп/зр')) return 'в п/зр';
    if (line.contains('г/л')) return 'г/л';
    if (line.contains('ммоль/л')) return 'ммоль/л';
    if (line.contains('мкмоль/л')) return 'мкмоль/л';
    if (line.contains('мм/ч')) return 'мм/ч';

    return fallback;
  }

  String _cleanLine(String line) {
    return line
        .replaceAll('|', ' ')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll('|', ' ')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
