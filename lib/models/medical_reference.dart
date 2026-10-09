import 'package:realm/realm.dart';

part 'medical_reference.realm.dart';

/// Запись вспомогательного справочника медицинских референсных значений.
///
/// В лабораторной работе №3 этот объект хранится в Realm. Поля sex/minAge/maxAge
/// позволяют хранить отдельные диапазоны по полу и возрастной группе.
@RealmModel()
class _MedicalReference {
  @PrimaryKey()
  late String id;

  /// Нормализованный ключ показателя, например urine_protein.
  late String markerKey;

  /// Отображаемое название показателя.
  late String displayName;

  /// all / male / female.
  late String sex;

  late int minAge;
  late int maxAge;
  late double minValue;
  late double maxValue;
  late String unit;

  /// Источник/примечание к диапазону.
  late String source;
}
