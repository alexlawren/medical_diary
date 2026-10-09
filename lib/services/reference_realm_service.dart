import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:realm/realm.dart';

import '../models/lab_report.dart';
import '../models/medical_reference.dart';

/// Результат сверки распознанного исследования со справочником Realm.
class ReferenceApplyResult {
  final LabReport report;
  final int matchedCount;

  const ReferenceApplyResult({
    required this.report,
    required this.matchedCount,
  });
}

/// Вспомогательное НЕРЕЛЯЦИОННОЕ хранилище медицинских норм на Realm.
class ReferenceRealmService {
  Realm? _realm;

  Realm get realm {
    final value = _realm;
    if (value == null) {
      throw StateError('Realm еще не инициализирован');
    }
    return value;
  }

  Future<void> init() async {
    if (_realm != null) return;

    final config = Configuration.local(
      [MedicalReference.schema],
      schemaVersion: 1,
    );
    _realm = Realm(config);

    if (realm.all<MedicalReference>().isEmpty) {
      await _seedFromAsset();
    }
  }

  Future<void> _seedFromAsset() async {
    final jsonText = await rootBundle.loadString(
      'assets/reference_ranges.json',
    );
    final decoded = jsonDecode(jsonText) as List<dynamic>;

    final references = decoded.map((raw) {
      final map = raw as Map<String, dynamic>;
      return MedicalReference(
        map['id'] as String,
        map['markerKey'] as String,
        map['displayName'] as String,
        map['sex'] as String,
        (map['minAge'] as num).toInt(),
        (map['maxAge'] as num).toInt(),
        (map['minValue'] as num).toDouble(),
        (map['maxValue'] as num).toDouble(),
        map['unit'] as String,
        map['source'] as String,
      );
    }).toList();

    realm.write(() {
      realm.addAll(references);
    });
  }

  int get count => realm.all<MedicalReference>().length;

  List<MedicalReference> getAll() {
    return realm.all<MedicalReference>().toList(growable: false);
  }

  MedicalReference? findReference({
    required String markerKey,
    required String sex,
    required int age,
  }) {
    final all = realm.all<MedicalReference>();

    final exact = all.where(
      (item) =>
          item.markerKey == markerKey &&
          item.sex == sex &&
          item.minAge <= age &&
          item.maxAge >= age,
    );
    if (exact.isNotEmpty) return exact.first;

    final universal = all.where(
      (item) =>
          item.markerKey == markerKey &&
          item.sex == 'all' &&
          item.minAge <= age &&
          item.maxAge >= age,
    );
    if (universal.isNotEmpty) return universal.first;

    // Учебный fallback: если для конкретного пола диапазон еще не заполнен,
    // используем любую запись того же показателя и возрастной группы.
    final byAge = all.where(
      (item) =>
          item.markerKey == markerKey &&
          item.minAge <= age &&
          item.maxAge >= age,
    );
    return byAge.isEmpty ? null : byAge.first;
  }

  /// Лабораторная №4: заменяет нормы, пришедшие с OCR/бланка, нормами из Realm.
  /// Значение самого анализа при этом остается тем, которое реально распознано.
  ReferenceApplyResult applyReferencesToReport({
    required LabReport report,
    required String sex,
    required int age,
  }) {
    var matched = 0;

    final markers = report.markers.map((marker) {
      final key = _markerKey(report.title, marker.name);
      if (key == null) return marker;

      final reference = findReference(
        markerKey: key,
        sex: sex,
        age: age,
      );
      if (reference == null) return marker;

      matched += 1;
      return LabMarker(
        name: marker.name,
        value: marker.value,
        unit: reference.unit.isEmpty ? marker.unit : reference.unit,
        minNormal: reference.minValue,
        maxNormal: reference.maxValue,
      );
    }).toList();

    return ReferenceApplyResult(
      matchedCount: matched,
      report: LabReport(
        id: report.id,
        title: report.title,
        date: report.date,
        laboratory: report.laboratory,
        markers: markers,
      ),
    );
  }

  String? _markerKey(String reportTitle, String markerName) {
    final report = _normalize(reportTitle);
    final marker = _normalize(markerName);

    if (marker.contains('удельный вес')) return 'urine_specific_gravity';
    if (marker.contains('реакция') && marker.contains('ph')) return 'urine_ph';
    if (marker == 'белок' || marker.contains('белок')) return 'urine_protein';
    if (marker.contains('лейкоцит') && report.contains('мочи')) {
      return 'urine_leukocytes';
    }
    if (marker.contains('гемоглобин')) return 'hemoglobin';

    return null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void close() {
    _realm?.close();
    _realm = null;
  }
}
