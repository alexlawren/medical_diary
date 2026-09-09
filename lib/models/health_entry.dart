/// Слой MODEL: чистые данные о состоянии здоровья
class HealthEntry {
  final DateTime date;
  final int pulse;
  final double temperature;
  final List<String> symptoms;
  final int severity; // Уровень выраженности от 1 до 10

  HealthEntry({
    required this.date,
    required this.pulse,
    required this.temperature,
    required this.symptoms,
    required this.severity,
  });
}
