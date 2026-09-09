import 'package:flutter/foundation.dart';
import '../models/health_entry.dart';

/// Слой VIEWMODEL: бизнес-логика, хранение состояния и реактивные уведомления
class HealthViewModel extends ChangeNotifier {
  // Список доступных симптомов для выбора
  final List<String> availableSymptoms = [
    'Головная боль',
    'Слабость',
    'Тошнота',
    'Головокружение',
    'Кашель',
    'Одышка',
    'Бессонница',
  ];

  // Выбранные симптомы
  final Set<String> _selectedSymptoms = {};
  Set<String> get selectedSymptoms => _selectedSymptoms;

  // Значения слайдеров интерактивного ввода
  double _currentSeverity = 3.0;
  double get currentSeverity => _currentSeverity;

  double _currentPulse = 72.0;
  double get currentPulse => _currentPulse;

  // Хронологическая лента (начальные мок-данные)
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

  // --- МЕТОДЫ УПРАВЛЕНИЯ СОСТОЯНИЕМ ---

  void toggleSymptom(String symptom) {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
    notifyListeners(); // Уведомляем интерфейс о перерисовке
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

    // Сброс формы после добавления
    _selectedSymptoms.clear();
    _currentSeverity = 3.0;

    notifyListeners();
  }
}
