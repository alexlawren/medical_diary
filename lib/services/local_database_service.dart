import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/health_entry.dart';
import '../models/lab_report.dart';

/// Основное долговременное РЕЛЯЦИОННОЕ хранилище приложения.
///
/// Для Flutter используется SQLite через sqflite как аналог реляционного слоя,
/// который в исходном iOS-варианте задания реализовывался бы через SwiftData.
class LocalDatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await init();
    return _database!;
  }

  Future<void> init() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'medical_diary.db');

    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE health_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            pulse INTEGER NOT NULL,
            temperature REAL NOT NULL,
            severity INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE health_entry_symptoms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            symptom TEXT NOT NULL,
            FOREIGN KEY(entry_id) REFERENCES health_entries(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE lab_reports (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            laboratory TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE lab_markers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            report_id TEXT NOT NULL,
            name TEXT NOT NULL,
            value REAL NOT NULL,
            unit TEXT NOT NULL,
            min_normal REAL NOT NULL,
            max_normal REAL NOT NULL,
            FOREIGN KEY(report_id) REFERENCES lab_reports(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<int> healthEntryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM health_entries');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> labReportCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM lab_reports');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertHealthEntry(HealthEntry entry) async {
    final db = await database;

    return db.transaction((txn) async {
      final entryId = await txn.insert('health_entries', {
        'date': entry.date.toIso8601String(),
        'pulse': entry.pulse,
        'temperature': entry.temperature,
        'severity': entry.severity,
      });

      final batch = txn.batch();
      for (final symptom in entry.symptoms) {
        batch.insert('health_entry_symptoms', {
          'entry_id': entryId,
          'symptom': symptom,
        });
      }
      await batch.commit(noResult: true);

      return entryId;
    });
  }

  Future<void> insertLabReport(LabReport report) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert(
        'lab_reports',
        {
          'id': report.id,
          'title': report.title,
          'date': report.date.toIso8601String(),
          'laboratory': report.laboratory,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // При повторной записи отчета обновляем его маркеры целиком.
      await txn.delete(
        'lab_markers',
        where: 'report_id = ?',
        whereArgs: [report.id],
      );

      final batch = txn.batch();
      for (final marker in report.markers) {
        batch.insert('lab_markers', {
          'report_id': report.id,
          'name': marker.name,
          'value': marker.value,
          'unit': marker.unit,
          'min_normal': marker.minNormal,
          'max_normal': marker.maxNormal,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<HealthEntry>> loadHealthEntries() async {
    final db = await database;
    final rows = await db.query('health_entries', orderBy: 'date DESC');

    final result = <HealthEntry>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final symptomRows = await db.query(
        'health_entry_symptoms',
        columns: ['symptom'],
        where: 'entry_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );

      result.add(
        HealthEntry(
          id: id,
          date: DateTime.parse(row['date'] as String),
          pulse: row['pulse'] as int,
          temperature: (row['temperature'] as num).toDouble(),
          symptoms: symptomRows.map((e) => e['symptom'] as String).toList(),
          severity: row['severity'] as int,
        ),
      );
    }

    return result;
  }

  Future<List<LabReport>> loadLabReports() async {
    final db = await database;
    final reportRows = await db.query('lab_reports', orderBy: 'date DESC');

    final result = <LabReport>[];
    for (final row in reportRows) {
      final reportId = row['id'] as String;
      final markerRows = await db.query(
        'lab_markers',
        where: 'report_id = ?',
        whereArgs: [reportId],
        orderBy: 'id ASC',
      );

      final markers = markerRows
          .map(
            (marker) => LabMarker(
              name: marker['name'] as String,
              value: (marker['value'] as num).toDouble(),
              unit: marker['unit'] as String,
              minNormal: (marker['min_normal'] as num).toDouble(),
              maxNormal: (marker['max_normal'] as num).toDouble(),
            ),
          )
          .toList();

      result.add(
        LabReport(
          id: reportId,
          title: row['title'] as String,
          date: DateTime.parse(row['date'] as String),
          laboratory: row['laboratory'] as String,
          markers: markers,
        ),
      );
    }

    return result;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
