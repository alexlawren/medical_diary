import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/lab_report.dart';

/// Слой VIEW: детальный просмотр исследования с индикацией отклонений
class LabDetailsScreen extends StatelessWidget {
  final LabReport report;

  const LabDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(report.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Общая карточка исследования (исправлена ошибка переполнения)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.laboratory,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                report.abnormalCount > 0
                                    ? Colors.red[50]
                                    : Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  report.abnormalCount > 0
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                          child: Text(
                            report.abnormalCount > 0
                                ? 'Отклонений: ${report.abnormalCount}'
                                : 'Все в норме',
                            style: TextStyle(
                              color:
                                  report.abnormalCount > 0
                                      ? Colors.red[800]
                                      : Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Дата забора: ${dateFormat.format(report.date)}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Лабораторные маркеры',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Список всех маркеров с выделением отклонений
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.markers.length,
              itemBuilder: (context, index) {
                final marker = report.markers[index];
                return _buildMarkerCard(marker);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerCard(LabMarker marker) {
    Color statusColor = Colors.green;
    String statusText = 'В норме';
    IconData statusIcon = Icons.check_circle_outline;

    if (marker.isHigh) {
      statusColor = Colors.red;
      statusText = 'Выше нормы';
      statusIcon = Icons.arrow_upward_rounded;
    } else if (marker.isLow) {
      statusColor = Colors.orange;
      statusText = 'Ниже нормы';
      statusIcon = Icons.arrow_downward_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              marker.isNormal
                  ? Colors.transparent
                  : statusColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marker.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Норма: ${marker.minNormal} – ${marker.maxNormal} ${marker.unit}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${marker.value} ${marker.unit}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: marker.isNormal ? Colors.black87 : statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
