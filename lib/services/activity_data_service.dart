import 'dart:async';

import '../models/activity_point.dart';

/// Источник потока физической активности для лабораторной №4.
///
/// В исходном iOS-задании данные должны поступать из HealthKit. Проект
/// тестируется на Huawei/Android, где HealthKit отсутствует как платформа.
/// Поэтому здесь используется изолированный учебный адаптер: он имеет тот же
/// асинхронный Stream-интерфейс, что и реальный системный источник, и позволяет
/// проверить реактивную архитектуру без установки дополнительных системных
/// приложений на телефон.
class ActivityDataService {
  final StreamController<List<ActivityPoint>> _controller =
      StreamController<List<ActivityPoint>>.broadcast();

  int _refreshIndex = 0;
  List<ActivityPoint> _latest = const [];

  Stream<List<ActivityPoint>> get activityStream => _controller.stream;
  List<ActivityPoint> get latest => List.unmodifiable(_latest);

  String get sourceDescription =>
      'ActivityDataService: локальный Android-адаптер системной активности';

  Future<void> start() async {
    if (_latest.isNotEmpty) {
      _controller.add(_latest);
      return;
    }
    await refresh();
  }

  /// Имитирует асинхронное обновление системного источника активности.
  /// Значения детерминированы, чтобы демонстрация на защите повторялась
  /// одинаково. При каждом обновлении слегка меняется только текущий день.
  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    _refreshIndex += 1;
    final today = DateTime.now();
    const baseSteps = [4300, 6100, 7900, 5200, 8800, 7200, 6400];
    const baseMinutes = [28, 36, 51, 31, 58, 44, 39];

    _latest = List<ActivityPoint>.generate(7, (index) {
      final daysAgo = 6 - index;
      final isToday = index == 6;
      return ActivityPoint(
        date: DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: daysAgo)),
        steps: baseSteps[index] + (isToday ? (_refreshIndex - 1) * 180 : 0),
        activeMinutes:
            baseMinutes[index] + (isToday ? (_refreshIndex - 1) * 2 : 0),
      );
    });

    _controller.add(_latest);
  }

  void dispose() {
    _controller.close();
  }
}
