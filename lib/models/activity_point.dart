/// Точка графика физической активности.
///
/// В лабораторной №4 этот тип является моделью данных, которые в iOS
/// поступали бы из HealthKit. На Android/Huawei используется локальный
/// учебный адаптер с тем же интерфейсом потока.
class ActivityPoint {
  final DateTime date;
  final int steps;
  final int activeMinutes;

  const ActivityPoint({
    required this.date,
    required this.steps,
    required this.activeMinutes,
  });
}
