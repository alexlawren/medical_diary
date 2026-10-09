import 'dart:async';

import '../models/activity_point.dart';
import '../models/lab_report.dart';
import '../models/reactive_health_snapshot.dart';

/// Аналог CombineLatest для Flutter/Dart Streams.
///
/// Общие требования допускают Flutter и Streams как альтернативу Combine.
/// Сервис хранит последние значения двух независимых потоков и публикует новый
/// ReactiveHealthSnapshot всякий раз, когда обновился один из них и оба уже
/// имеют данные.
class ReactiveHealthPipeline {
  final StreamController<ReactiveHealthSnapshot> _snapshotController =
      StreamController<ReactiveHealthSnapshot>.broadcast();

  LabReport? _latestReport;
  List<ActivityPoint> _latestActivity = const [];

  Stream<ReactiveHealthSnapshot> get snapshots => _snapshotController.stream;

  void addReport(LabReport report) {
    _latestReport = report;
    _emitIfReady();
  }

  void addActivity(List<ActivityPoint> activity) {
    _latestActivity = List.unmodifiable(activity);
    _emitIfReady();
  }

  void _emitIfReady() {
    final report = _latestReport;
    if (report == null || _latestActivity.isEmpty) return;

    _snapshotController.add(
      ReactiveHealthSnapshot(
        report: report,
        activity: _latestActivity,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _snapshotController.close();
  }
}
