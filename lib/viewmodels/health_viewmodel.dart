import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/activity_point.dart';
import '../models/health_entry.dart';
import '../models/lab_report.dart';
import '../models/reactive_health_snapshot.dart';
import '../services/activity_data_service.dart';
import '../services/local_database_service.dart';
import '../services/reactive_health_pipeline.dart';
import '../services/reference_realm_service.dart';

/// Слой VIEWMODEL: бизнес-логика дневника и лабораторных исследований.
///
/// Лабораторная работа №3 добавляет два долговременных хранилища:
/// - SQLite (основные пользовательские данные);
/// - Realm (вспомогательный справочник референсных значений).
class HealthViewModel extends ChangeNotifier {
  final LocalDatabaseService _databaseService = LocalDatabaseService();
  final ReferenceRealmService _referenceService = ReferenceRealmService();
  final ActivityDataService _activityDataService = ActivityDataService();
  final ReactiveHealthPipeline _reactivePipeline = ReactiveHealthPipeline();

  StreamSubscription<List<ActivityPoint>>? _activitySubscription;
  StreamSubscription<ReactiveHealthSnapshot>? _snapshotSubscription;

  final List<String> availableSymptoms = [
    'Головная боль',
    'Слабость',
    'Тошнота',
    'Головокружение',
    'Кашель',
    'Одышка',
    'Бессонница',
  ];

  final Set<String> _selectedSymptoms = {};
  Set<String> get selectedSymptoms => _selectedSymptoms;

  double _currentSeverity = 3.0;
  double get currentSeverity => _currentSeverity;

  double _currentPulse = 72.0;
  double get currentPulse => _currentPulse;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  int _realmReferenceCount = 0;
  int get realmReferenceCount => _realmReferenceCount;

  final List<ActivityPoint> _activityPoints = [];
  List<ActivityPoint> get activityPoints => List.unmodifiable(_activityPoints);

  ReactiveHealthSnapshot? _reactiveSnapshot;
  ReactiveHealthSnapshot? get reactiveSnapshot => _reactiveSnapshot;

  bool _isActivityRefreshing = false;
  bool get isActivityRefreshing => _isActivityRefreshing;

  String _referenceSex = 'female';
  String get referenceSex => _referenceSex;

  int _referenceAge = 34;
  int get referenceAge => _referenceAge;

  int _lastMatchedReferenceCount = 0;
  int get lastMatchedReferenceCount => _lastMatchedReferenceCount;

  String _pipelineStatus = 'Ожидает первого лабораторного исследования';
  String get pipelineStatus => _pipelineStatus;

  String get activitySourceDescription => _activityDataService.sourceDescription;

  final List<HealthEntry> _history = [];
  List<HealthEntry> get history => List.unmodifiable(_history);

  final List<LabReport> _labReports = [];
  List<LabReport> get labReports => List.unmodifiable(_labReports);

  int get sqliteHealthEntryCount => _history.length;
  int get sqliteLabReportCount => _labReports.length;

  /// Инициализация долговременных хранилищ при старте приложения.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _databaseService.init();
    await _referenceService.init();

    // При самом первом запуске заполняем основную БД демонстрационными данными,
    // которые раньше были просто захардкожены в ViewModel.
    if (await _databaseService.healthEntryCount() == 0) {
      for (final entry in _initialHealthEntries()) {
        await _databaseService.insertHealthEntry(entry);
      }
    }

    if (await _databaseService.labReportCount() == 0) {
      for (final report in _initialLabReports()) {
        await _databaseService.insertLabReport(report);
      }
    }

    _history
      ..clear()
      ..addAll(await _databaseService.loadHealthEntries());

    _labReports
      ..clear()
      ..addAll(await _databaseService.loadLabReports());

    _realmReferenceCount = _referenceService.count;

    // ЛР №4: подписываем ViewModel на два независимых потока и объединяем их
    // через ReactiveHealthPipeline (аналог CombineLatest на Dart Streams).
    _activitySubscription = _activityDataService.activityStream.listen((points) {
      _activityPoints
        ..clear()
        ..addAll(points);
      _reactivePipeline.addActivity(points);
      notifyListeners();
    });

    _snapshotSubscription = _reactivePipeline.snapshots.listen((snapshot) {
      _reactiveSnapshot = snapshot;
      _pipelineStatus =
          'Объединено: анализ + ${snapshot.activity.length} точек активности';
      notifyListeners();
    });

    await _activityDataService.start();
    if (_labReports.isNotEmpty) {
      _reactivePipeline.addReport(_labReports.first);
    }

    _isInitialized = true;
    notifyListeners();
  }

  void toggleSymptom(String symptom) {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
    notifyListeners();
  }

  void updateSeverity(double value) {
    _currentSeverity = value;
    notifyListeners();
  }

  void updatePulse(double value) {
    _currentPulse = value;
    notifyListeners();
  }

  /// Добавление записи теперь не только меняет список в памяти,
  /// но и сохраняет ее в SQLite.
  Future<void> addNewEntry() async {
    final entry = HealthEntry(
      date: DateTime.now(),
      pulse: _currentPulse.round(),
      temperature: 36.6,
      symptoms: _selectedSymptoms.toList(),
      severity: _currentSeverity.round(),
    );

    await _databaseService.insertHealthEntry(entry);

    _history
      ..clear()
      ..addAll(await _databaseService.loadHealthEntries());

    _selectedSymptoms.clear();
    _currentSeverity = 3.0;
    notifyListeners();
  }

  /// Распознанный OCR-отчет сохраняется в SQLite вместе со всеми маркерами.
  Future<void> addParsedReport(LabReport report) async {
    await _databaseService.insertLabReport(report);

    _labReports
      ..clear()
      ..addAll(await _databaseService.loadLabReports());

    notifyListeners();
  }

  /// ЛР №4: OCR -> сверка с Realm -> SQLite -> реактивный поток.
  /// Возвращает уже нормализованный отчет, который нужно открыть в UI.
  Future<LabReport> processScannedReport(LabReport report) async {
    final comparison = _referenceService.applyReferencesToReport(
      report: report,
      sex: _referenceSex,
      age: _referenceAge,
    );

    _lastMatchedReferenceCount = comparison.matchedCount;
    await addParsedReport(comparison.report);

    _pipelineStatus =
        'OCR обработан: Realm ${comparison.matchedCount}/${comparison.report.markers.length}';
    _reactivePipeline.addReport(comparison.report);
    notifyListeners();

    return comparison.report;
  }

  void updateReferenceSex(String value) {
    _referenceSex = value;
    notifyListeners();
  }

  void updateReferenceAge(double value) {
    _referenceAge = value.round();
    notifyListeners();
  }

  Future<void> refreshActivity() async {
    if (_isActivityRefreshing) return;
    _isActivityRefreshing = true;
    notifyListeners();

    try {
      await _activityDataService.refresh();
    } finally {
      _isActivityRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshStorageInfo() async {
    _history
      ..clear()
      ..addAll(await _databaseService.loadHealthEntries());

    _labReports
      ..clear()
      ..addAll(await _databaseService.loadLabReports());

    _realmReferenceCount = _referenceService.count;
    notifyListeners();
  }

  List<HealthEntry> _initialHealthEntries() {
    return [
      HealthEntry(
        date: DateTime.now().subtract(const Duration(days: 3)),
        pulse: 70,
        temperature: 36.6,
        symptoms: ['Слабость'],
        severity: 3,
      ),
      HealthEntry(
        date: DateTime.now().subtract(const Duration(days: 2)),
        pulse: 82,
        temperature: 37.1,
        symptoms: ['Головная боль', 'Слабость'],
        severity: 6,
      ),
      HealthEntry(
        date: DateTime.now().subtract(const Duration(days: 1)),
        pulse: 76,
        temperature: 36.7,
        symptoms: ['Бессонница'],
        severity: 4,
      ),
    ];
  }

  List<LabReport> _initialLabReports() {
    return [
      LabReport(
        id: 'demo_blood_1',
        title: 'Общий анализ крови (ОАК)',
        date: DateTime.now().subtract(const Duration(days: 2)),
        laboratory: 'Лаборатория Хеликс',
        markers: [
          LabMarker(
            name: 'Гемоглобин',
            value: 142.0,
            unit: 'г/л',
            minNormal: 120.0,
            maxNormal: 160.0,
          ),
          LabMarker(
            name: 'Эритроциты',
            value: 4.7,
            unit: '10^12/л',
            minNormal: 3.8,
            maxNormal: 5.1,
          ),
          LabMarker(
            name: 'Лейкоциты',
            value: 11.8,
            unit: '10^9/л',
            minNormal: 4.0,
            maxNormal: 9.0,
          ),
          LabMarker(
            name: 'Тромбоциты',
            value: 240.0,
            unit: '10^9/л',
            minNormal: 150.0,
            maxNormal: 400.0,
          ),
          LabMarker(
            name: 'СОЭ (по Вестергрену)',
            value: 22.0,
            unit: 'мм/ч',
            minNormal: 2.0,
            maxNormal: 15.0,
          ),
        ],
      ),
      LabReport(
        id: 'demo_biochemistry_1',
        title: 'Биохимический профиль',
        date: DateTime.now().subtract(const Duration(days: 5)),
        laboratory: 'Инвитро',
        markers: [
          LabMarker(
            name: 'Глюкоза',
            value: 5.1,
            unit: 'ммоль/л',
            minNormal: 4.1,
            maxNormal: 5.9,
          ),
          LabMarker(
            name: 'АЛТ',
            value: 24.0,
            unit: 'Ед/л',
            minNormal: 0.0,
            maxNormal: 41.0,
          ),
          LabMarker(
            name: 'АСТ',
            value: 21.0,
            unit: 'Ед/л',
            minNormal: 0.0,
            maxNormal: 37.0,
          ),
          LabMarker(
            name: 'Билирубин общий',
            value: 14.5,
            unit: 'мкмоль/л',
            minNormal: 3.4,
            maxNormal: 20.5,
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    _snapshotSubscription?.cancel();
    _activityDataService.dispose();
    _reactivePipeline.dispose();
    _referenceService.close();
    _databaseService.close();
    super.dispose();
  }
}
