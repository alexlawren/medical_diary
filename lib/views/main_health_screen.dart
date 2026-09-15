import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../viewmodels/health_viewmodel.dart';
import '../models/health_entry.dart';
import 'lab_details_screen.dart';
import 'scan_report_screen.dart';

/// Слой VIEW: главный экран дневника и список исследований
class MainHealthScreen extends StatelessWidget {
  final HealthViewModel viewModel;

  const MainHealthScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Медицинский дневник'),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          // Кнопка быстрого перехода к сканированию бланка (Камера)
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanReportScreen(viewModel: viewModel),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Скан бланка'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Блок ввода симптомов
                _buildSymptomInputCard(context),

                const SizedBox(height: 20),

                // 2. Блок графика показателей
                _buildChartCard(),

                const SizedBox(height: 24),

                // 3. НОВЫЙ БЛОК: Лабораторные исследования (Лабораторная работа №2)
                _buildLabReportsSection(context),

                const SizedBox(height: 24),

                // 4. Хронологическая лента самочувствия
                const Text(
                  'Хроника самочувствия',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildTimelineList(viewModel.history),
                const SizedBox(height: 60), // Отступ под FAB
              ],
            ),
          ),
        );
      },
    );
  }

  // Раздел карточек исследований
  Widget _buildLabReportsSection(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Лабораторные анализы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Всего: ${viewModel.labReports.length}',
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.labReports.length,
          itemBuilder: (context, index) {
            final report = viewModel.labReports[index];
            final hasAbnormal = report.abnormalCount > 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color:
                      hasAbnormal
                          ? Colors.red.withOpacity(0.4)
                          : Colors.transparent,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      hasAbnormal ? Colors.red[50] : Colors.teal[50],
                  child: Icon(
                    Icons.biotech_rounded,
                    color: hasAbnormal ? Colors.red : Colors.teal,
                  ),
                ),
                title: Text(
                  report.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${report.laboratory} • ${dateFormat.format(report.date)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasAbnormal
                          ? '⚠️ Отклонений от нормы: ${report.abnormalCount}'
                          : '✓ Все показатели в норме',
                      style: TextStyle(
                        color:
                            hasAbnormal ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  // Переход на детальный экран карточки исследования
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabDetailsScreen(report: report),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSymptomInputCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add_alert_rounded, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Фиксация симптомов',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              children:
                  viewModel.availableSymptoms.map((symptom) {
                    final isSelected = viewModel.selectedSymptoms.contains(
                      symptom,
                    );
                    return FilterChip(
                      label: Text(symptom),
                      selected: isSelected,
                      onSelected: (_) => viewModel.toggleSymptom(symptom),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'Тяжесть симптомов: ${viewModel.currentSeverity.round()} из 10',
            ),
            Slider(
              value: viewModel.currentSeverity,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Colors.teal,
              onChanged: (val) => viewModel.updateSeverity(val),
            ),
            Text('Текущий пульс: ${viewModel.currentPulse.round()} уд/мин'),
            Slider(
              value: viewModel.currentPulse,
              min: 50,
              max: 140,
              divisions: 90,
              activeColor: Colors.redAccent,
              onChanged: (val) => viewModel.updatePulse(val),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  viewModel.addNewEntry();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Запись успешно добавлена в дневник!'),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Сохранить запись'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, color: Colors.redAccent),
                SizedBox(width: 8),
                Text(
                  'Динамика пульса (уд/мин)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          viewModel.history.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              e.value.pulse.toDouble(),
                            );
                          }).toList(),
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.redAccent.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList(List<HealthEntry> history) {
    if (history.isEmpty) {
      return const Center(child: Text('Записей пока нет'));
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  entry.severity > 5 ? Colors.red[100] : Colors.teal[100],
              child: Icon(
                Icons.favorite,
                color: entry.severity > 5 ? Colors.red : Colors.teal,
              ),
            ),
            title: Text(
              dateFormat.format(entry.date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Пульс: ${entry.pulse} уд/мин | Тяжесть: ${entry.severity}/10',
                ),
                if (entry.symptoms.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Симптомы: ${entry.symptoms.join(", ")}'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
