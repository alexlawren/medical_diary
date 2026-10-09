// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_reference.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class MedicalReference extends _MedicalReference
    with RealmEntity, RealmObjectBase, RealmObject {
  MedicalReference(
    String id,
    String markerKey,
    String displayName,
    String sex,
    int minAge,
    int maxAge,
    double minValue,
    double maxValue,
    String unit,
    String source,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'markerKey', markerKey);
    RealmObjectBase.set(this, 'displayName', displayName);
    RealmObjectBase.set(this, 'sex', sex);
    RealmObjectBase.set(this, 'minAge', minAge);
    RealmObjectBase.set(this, 'maxAge', maxAge);
    RealmObjectBase.set(this, 'minValue', minValue);
    RealmObjectBase.set(this, 'maxValue', maxValue);
    RealmObjectBase.set(this, 'unit', unit);
    RealmObjectBase.set(this, 'source', source);
  }

  MedicalReference._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get markerKey =>
      RealmObjectBase.get<String>(this, 'markerKey') as String;
  @override
  set markerKey(String value) => RealmObjectBase.set(this, 'markerKey', value);

  @override
  String get displayName =>
      RealmObjectBase.get<String>(this, 'displayName') as String;
  @override
  set displayName(String value) =>
      RealmObjectBase.set(this, 'displayName', value);

  @override
  String get sex => RealmObjectBase.get<String>(this, 'sex') as String;
  @override
  set sex(String value) => RealmObjectBase.set(this, 'sex', value);

  @override
  int get minAge => RealmObjectBase.get<int>(this, 'minAge') as int;
  @override
  set minAge(int value) => RealmObjectBase.set(this, 'minAge', value);

  @override
  int get maxAge => RealmObjectBase.get<int>(this, 'maxAge') as int;
  @override
  set maxAge(int value) => RealmObjectBase.set(this, 'maxAge', value);

  @override
  double get minValue =>
      RealmObjectBase.get<double>(this, 'minValue') as double;
  @override
  set minValue(double value) => RealmObjectBase.set(this, 'minValue', value);

  @override
  double get maxValue =>
      RealmObjectBase.get<double>(this, 'maxValue') as double;
  @override
  set maxValue(double value) => RealmObjectBase.set(this, 'maxValue', value);

  @override
  String get unit => RealmObjectBase.get<String>(this, 'unit') as String;
  @override
  set unit(String value) => RealmObjectBase.set(this, 'unit', value);

  @override
  String get source => RealmObjectBase.get<String>(this, 'source') as String;
  @override
  set source(String value) => RealmObjectBase.set(this, 'source', value);

  @override
  Stream<RealmObjectChanges<MedicalReference>> get changes =>
      RealmObjectBase.getChanges<MedicalReference>(this);

  @override
  Stream<RealmObjectChanges<MedicalReference>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<MedicalReference>(this, keyPaths);

  @override
  MedicalReference freeze() =>
      RealmObjectBase.freezeObject<MedicalReference>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'markerKey': markerKey.toEJson(),
      'displayName': displayName.toEJson(),
      'sex': sex.toEJson(),
      'minAge': minAge.toEJson(),
      'maxAge': maxAge.toEJson(),
      'minValue': minValue.toEJson(),
      'maxValue': maxValue.toEJson(),
      'unit': unit.toEJson(),
      'source': source.toEJson(),
    };
  }

  static EJsonValue _toEJson(MedicalReference value) => value.toEJson();
  static MedicalReference _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'markerKey': EJsonValue markerKey,
        'displayName': EJsonValue displayName,
        'sex': EJsonValue sex,
        'minAge': EJsonValue minAge,
        'maxAge': EJsonValue maxAge,
        'minValue': EJsonValue minValue,
        'maxValue': EJsonValue maxValue,
        'unit': EJsonValue unit,
        'source': EJsonValue source,
      } =>
        MedicalReference(
          fromEJson(id),
          fromEJson(markerKey),
          fromEJson(displayName),
          fromEJson(sex),
          fromEJson(minAge),
          fromEJson(maxAge),
          fromEJson(minValue),
          fromEJson(maxValue),
          fromEJson(unit),
          fromEJson(source),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(MedicalReference._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      MedicalReference,
      'MedicalReference',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('markerKey', RealmPropertyType.string),
        SchemaProperty('displayName', RealmPropertyType.string),
        SchemaProperty('sex', RealmPropertyType.string),
        SchemaProperty('minAge', RealmPropertyType.int),
        SchemaProperty('maxAge', RealmPropertyType.int),
        SchemaProperty('minValue', RealmPropertyType.double),
        SchemaProperty('maxValue', RealmPropertyType.double),
        SchemaProperty('unit', RealmPropertyType.string),
        SchemaProperty('source', RealmPropertyType.string),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
