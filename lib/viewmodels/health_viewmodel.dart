import 'package:flutter/foundation.dart';
import '../models/health_entry.dart';
import '../models/lab_report.dart';

/// Слой VIEWMODEL: бизнес-логика дневника и лабораторных исследований
class HealthViewModel extends ChangeNotifier {
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

  // Хронологическая лента симптомов
  final List<HealthEntry> _history = [
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
  List<HealthEntry> get history => List.unmodifiable(_history);

  // --- ЛАБОРАТОРНЫЕ ИССЛЕДОВАНИЯ (Лабораторная работа №2) ---
  final List<LabReport> _labReports = [
    LabReport(
      id: '1',
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
        ), // Выше нормы!
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
        ), // Выше нормы!
      ],
    ),
    LabReport(
      id: '2',
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
  List<LabReport> get labReports => List.unmodifiable(_labReports);

  // --- МЕТОДЫ УПРАВЛЕНИЯ ---

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

  void addNewEntry() {
    _history.insert(
      0,
      HealthEntry(
        date: DateTime.now(),
        pulse: _currentPulse.round(),
        temperature: 36.6,
        symptoms: _selectedSymptoms.toList(),
        severity: _currentSeverity.round(),
      ),
    );
    _selectedSymptoms.clear();
    _currentSeverity = 3.0;
    notifyListeners();
  }

  void addScannedReport({required String type}) {
    final isUrine =
        type.contains('Хеликс') ||
        type.contains('мочи') ||
        type.contains('Камера');

    final newReport =
        isUrine
            ? LabReport(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Общий анализ мочи',
              date: DateTime.now(),
              laboratory: 'Лабораторная служба Хеликс',
              markers: [
                LabMarker(
                  name: 'Удельный вес',
                  value: 1.019,
                  unit: '',
                  minNormal: 1.003,
                  maxNormal: 1.030,
                ), // В норме!
                LabMarker(
                  name: 'Реакция (pH)',
                  value: 6.5,
                  unit: 'pH',
                  minNormal: 5.0,
                  maxNormal: 7.5,
                ), // В норме!
                LabMarker(
                  name: 'Белок',
                  value: 0.15,
                  unit: 'г/л',
                  minNormal: 0.0,
                  maxNormal: 0.1,
                ), // Выше нормы! (для наглядности)
                LabMarker(
                  name: 'Лейкоциты',
                  value: 2.0,
                  unit: 'в п/зр',
                  minNormal: 0.0,
                  maxNormal: 5.0,
                ), // В норме!
              ],
            )
            : LabReport(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Биохимический анализ крови',
              date: DateTime.now(),
              laboratory: 'Инвитро',
              markers: [
                LabMarker(
                  name: 'Глюкоза',
                  value: 6.4,
                  unit: 'ммоль/л',
                  minNormal: 4.1,
                  maxNormal: 5.9,
                ), // Выше нормы!
                LabMarker(
                  name: 'Гемоглобин',
                  value: 115.0,
                  unit: 'г/л',
                  minNormal: 120.0,
                  maxNormal: 160.0,
                ), // Ниже нормы!
                LabMarker(
                  name: 'СОЭ',
                  value: 8.0,
                  unit: 'мм/ч',
                  minNormal: 2.0,
                  maxNormal: 15.0,
                ),
              ],
            );

    _labReports.insert(0, newReport);
    notifyListeners();
  }
}
