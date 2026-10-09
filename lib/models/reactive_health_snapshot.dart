import 'activity_point.dart';
import 'lab_report.dart';

/// Результат реактивного объединения двух независимых потоков:
/// 1) последнего распознанного лабораторного исследования;
/// 2) графика физической активности.
class ReactiveHealthSnapshot {
  final LabReport report;
  final List<ActivityPoint> activity;
  final DateTime updatedAt;

  ReactiveHealthSnapshot({
    required this.report,
    required List<ActivityPoint> activity,
    required this.updatedAt,
  }) : activity = List.unmodifiable(activity);

  int get totalSteps => activity.fold(0, (sum, point) => sum + point.steps);

  int get averageSteps {
    if (activity.isEmpty) return 0;
    return (totalSteps / activity.length).round();
  }

  int get totalActiveMinutes =>
      activity.fold(0, (sum, point) => sum + point.activeMinutes);
}
