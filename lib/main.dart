import 'package:flutter/material.dart';
import 'viewmodels/health_viewmodel.dart';
import 'views/main_health_screen.dart';

void main() {
  runApp(const MedicalDiaryApp());
}

class MedicalDiaryApp extends StatelessWidget {
  const MedicalDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Создаем экземпляр ViewModel и передаем его в экран
    final healthViewModel = HealthViewModel();

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
      home: MainHealthScreen(viewModel: healthViewModel),
    );
  }
}
