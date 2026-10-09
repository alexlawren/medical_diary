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

                // 3. ЛР №4: реактивное объединение лабораторных данных и активности
                _buildReactiveLab4Card(context),

                const SizedBox(height: 24),

                // 4. Лабораторные исследования (Лабораторная работа №2)
                _buildLabReportsSection(context),

                const SizedBox(height: 24),

                // 5. Статус долговременных хранилищ (Лабораторная работа №3)
                _buildStorageStatusCard(context),

                const SizedBox(height: 24),

                // 6. Хронологическая лента самочувствия
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

  Widget _buildStorageStatusCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage_rounded, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Хранилища данных',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _storageLine(
              icon: Icons.table_chart_outlined,
              title: 'SQLite',
              value:
                  '${viewModel.sqliteHealthEntryCount} записей дневника, '
                  '${viewModel.sqliteLabReportCount} исследований',
            ),
            const SizedBox(height: 8),
            _storageLine(
              icon: Icons.dataset_outlined,
              title: 'Realm',
              value: '${viewModel.realmReferenceCount} референсных записей',
            ),
            const SizedBox(height: 10),
            const Text(
              'Данные сохраняются локально и восстанавливаются после перезапуска приложения.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await viewModel.refreshStorageInfo();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Состояние хранилищ обновлено')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Проверить БД'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storageLine({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.indigo),
        const SizedBox(width: 8),
        SizedBox(
          width: 58,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildReactiveLab4Card(BuildContext context) {
    final points = viewModel.activityPoints;
    final snapshot = viewModel.reactiveSnapshot;
    final maxSteps = points.isEmpty
        ? 10000.0
        : points
                .map((point) => point.steps)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() *
            1.15;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hub_outlined, color: Colors.deepPurple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Реактивная обработка • ЛР №4',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'OCR → нормы Realm → Stream → объединение с физической активностью',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: viewModel.referenceSex,
                    decoration: const InputDecoration(
                      labelText: 'Пол для норм',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'female',
                        child: Text('Женский'),
                      ),
                      DropdownMenuItem(
                        value: 'male',
                        child: Text('Мужской'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) viewModel.updateReferenceSex(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Возраст: ${viewModel.referenceAge}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Slider(
              value: viewModel.referenceAge.toDouble(),
              min: 18,
              max: 90,
              divisions: 72,
              label: '${viewModel.referenceAge}',
              activeColor: Colors.deepPurple,
              onChanged: viewModel.updateReferenceAge,
            ),

            _lab4StatusLine(
              icon: Icons.dataset_outlined,
              label: 'Realm',
              value: viewModel.lastMatchedReferenceCount == 0
                  ? 'справочник готов (${viewModel.realmReferenceCount} записей)'
                  : 'сверено показателей: ${viewModel.lastMatchedReferenceCount}',
            ),
            const SizedBox(height: 6),
            _lab4StatusLine(
              icon: Icons.sync_alt_rounded,
              label: 'Stream',
              value: viewModel.pipelineStatus,
            ),
            const SizedBox(height: 6),
            _lab4StatusLine(
              icon: Icons.directions_walk_rounded,
              label: 'Активность',
              value: viewModel.activitySourceDescription,
            ),

            const SizedBox(height: 14),
            const Text(
              'Физическая активность за 7 дней',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (points.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (points.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxSteps,
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.steps.toDouble(),
                          );
                        }).toList(),
                        isCurved: true,
                        color: Colors.deepPurple,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.deepPurple.withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: points.map((point) {
                  return Expanded(
                    child: Text(
                      DateFormat('dd.MM').format(point.date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
            if (snapshot != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Объединенный снимок: ${snapshot.report.title}\n'
                  'Отклонений: ${snapshot.report.abnormalCount} • '
                  'Среднее шагов/день: ${snapshot.averageSteps} • '
                  'Активных минут: ${snapshot.totalActiveMinutes}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),

            const SizedBox(height: 10),
            const Text(
              'На Huawei используется локальный учебный адаптер активности: '
              'Apple HealthKit существует только на iOS. Реактивный слой отделен '
              'от источника данных, поэтому на iPhone адаптер можно заменить на HealthKit.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: viewModel.isActivityRefreshing
                    ? null
                    : () async {
                        await viewModel.refreshActivity();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Поток физической активности обновлен'),
                          ),
                        );
                      },
                icon: viewModel.isActivityRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                label: const Text('Обновить поток'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lab4StatusLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(width: 7),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12)),
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
                onPressed: () async {
                  await viewModel.addNewEntry();
                  if (!context.mounted) return;
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
