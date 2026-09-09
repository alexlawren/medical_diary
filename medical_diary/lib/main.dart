import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MedicalDiaryApp());
}

class MedicalDiaryApp extends StatelessWidget {
  const MedicalDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Медицинский дневник',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainHealthScreen(),
    );
  }
}

// Модель записи дневника
class HealthEntry {
  final DateTime date;
  final int pulse;
  final double temperature;
  final List<String> symptoms;
  final int severity; // от 1 до 10

  HealthEntry({
    required this.date,
    required this.pulse,
    required this.temperature,
    required this.symptoms,
    required this.severity,
  });
}

class MainHealthScreen extends StatefulWidget {
  const MainHealthScreen({super.key});

  @override
  State<MainHealthScreen> createState() => _MainHealthScreenState();
}

class _MainHealthScreenState extends State<MainHealthScreen> {
  // Список доступных симптомов для интерактивного выбора
  final List<String> _availableSymptoms = [
    'Головная боль',
    'Слабость',
    'Тошнота',
    'Головокружение',
    'Кашель',
    'Одышка',
    'Бессонница',
  ];

  // Состояние интерактивного ввода
  final Set<String> _selectedSymptoms = {};
  double _currentSeverity = 3.0;
  double _currentPulse = 72.0;

  // Хронологическая лента (начальные мок-данные для демонстрации)
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

  // Добавление новой записи
  void _addNewEntry() {
    setState(() {
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
      _selectedSymptoms.clear();
      _currentSeverity = 3.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Запись успешно добавлена в ленту!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Медицинский дневник'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- БЛОК 1: ИНТЕРАКТИВНЫЙ ВВОД СИМПТОМОВ ---
            _buildSymptomInputCard(),

            const SizedBox(height: 20),

            // --- БЛОК 2: ГРАФИК ФИЗИОЛОГИЧЕСКИХ ПОКАЗАТЕЛЕЙ ---
            _buildChartCard(),

            const SizedBox(height: 20),

            // --- БЛОК 3: ХРОНОЛОГИЧЕСКАЯ ЛЕНТА ЗДОРОВЬЯ ---
            const Text(
              'Хроника самочувствия',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTimelineList(),
          ],
        ),
      ),
    );
  }

  // Виджет интерактивного ввода симптомов
  Widget _buildSymptomInputCard() {
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
            const Text('Выберите текущие симптомы:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children:
                  _availableSymptoms.map((symptom) {
                    final isSelected = _selectedSymptoms.contains(symptom);
                    return FilterChip(
                      label: Text(symptom),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSymptoms.add(symptom);
                          } else {
                            _selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Тяжесть симптомов: ${_currentSeverity.round()} из 10'),
            Slider(
              value: _currentSeverity,
              min: 1,
              max: 10,
              divisions: 9,
              label: _currentSeverity.round().toString(),
              activeColor: Colors.teal,
              onChanged: (val) => setState(() => _currentSeverity = val),
            ),
            Text('Текущий пульс: ${_currentPulse.round()} уд/мин'),
            Slider(
              value: _currentPulse,
              min: 50,
              max: 140,
              divisions: 90,
              label: _currentPulse.round().toString(),
              activeColor: Colors.redAccent,
              onChanged: (val) => setState(() => _currentPulse = val),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addNewEntry,
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

  // Виджет графика пульса
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
                          _history.asMap().entries.map((e) {
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

  // Виджет хронологической ленты
  Widget _buildTimelineList() {
    if (_history.isEmpty) {
      return const Center(child: Text('Записей пока нет'));
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
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
                    child: Text(
                      'Симптомы: ${entry.symptoms.join(", ")}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
