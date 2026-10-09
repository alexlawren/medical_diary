import 'package:flutter/material.dart';

import 'viewmodels/health_viewmodel.dart';
import 'views/main_health_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final healthViewModel = HealthViewModel();
  await healthViewModel.initialize();

  runApp(MedicalDiaryApp(viewModel: healthViewModel));
}

class MedicalDiaryApp extends StatelessWidget {
  final HealthViewModel viewModel;

  const MedicalDiaryApp({
    super.key,
    required this.viewModel,
  });

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
      home: MainHealthScreen(viewModel: viewModel),
    );
  }
}
