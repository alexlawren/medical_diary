/// Слой MODEL: отдельный маркер лабораторного анализа
class LabMarker {
  final String name; // Название показателя (например, "Гемоглобин")
  final double value; // Полученное значение
  final String unit; // Единица измерения (г/л, ммоль/л и т.д.)
  final double minNormal; // Нижняя граница нормы
  final double maxNormal; // Верхняя граница нормы

  LabMarker({
    required this.name,
    required this.value,
    required this.unit,
    required this.minNormal,
    required this.maxNormal,
  });

  // Вспомогательные геттеры для визуализации нормы
  bool get isHigh => value > maxNormal;
  bool get isLow => value < minNormal;
  bool get isNormal => !isHigh && !isLow;
}

/// Слой MODEL: карточка лабораторного исследования
class LabReport {
  final String id;
  final String title; // Например, "Общий анализ крови (ОАК)"
  final DateTime date;
  final String laboratory; // Название лаборатории
  final List<LabMarker> markers;

  LabReport({
    required this.id,
    required this.title,
    required this.date,
    required this.laboratory,
    required this.markers,
  });

  // Количество маркеров, вышедших за границы нормы
  int get abnormalCount => markers.where((m) => !m.isNormal).length;
}
