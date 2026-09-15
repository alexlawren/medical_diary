import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/health_viewmodel.dart';

/// Слой VIEW: модуль сканирования печатного бланка анализов
class ScanReportScreen extends StatefulWidget {
  final HealthViewModel viewModel;

  const ScanReportScreen({super.key, required this.viewModel});

  @override
  State<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends State<ScanReportScreen> {
  File? _scannedImage;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  // Захват изображения с камеры
  Future<void> _captureFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _processScannedDocument(File(pickedFile.path), isCamera: true);
    }
  }

  // Загрузка фото из галереи
  Future<void> _pickFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _processScannedDocument(File(pickedFile.path), isCamera: false);
    }
  }

  // Обработка бланка (автоматическое извлечение данных)
  void _processScannedDocument(
    File? imageFile, {
    required bool isCamera,
    String? mockType,
  }) {
    setState(() {
      _scannedImage = imageFile;
      _isProcessing = true;
    });

    // Имитация оптического распознавания текста (OCR)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      widget.viewModel.addScannedReport(
        type: mockType ?? (isCamera ? 'Камера (ОАК)' : 'Галерея (Биохимия)'),
      );

      setState(() {
        _isProcessing = false;
      });

      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Бланк успешно распознан!'),
              content: const Text(
                'Таблица маркеров оцифрована. Показатели сопоставлены с медицинскими нормами и сохранены в дневник.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // закрываем диалог
                    Navigator.of(
                      context,
                    ).pop(); // возвращаемся на главный экран
                  },
                  child: const Text('Перейти к анализам'),
                ),
              ],
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование бланка'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Окно предварительного просмотра камеры/бланка
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.teal,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child:
                    _isProcessing
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.teal),
                              SizedBox(height: 16),
                              Text(
                                'Распознавание таблицы и маркеров...',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                        : _scannedImage != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_scannedImage!, fit: BoxFit.cover),
                        )
                        : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              size: 70,
                              color: Colors.teal,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Наведите камеру на печатный лист анализа\nили выберите готовый бланк',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 20),

            // Кнопки реальной камеры
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Снимок камеры'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Из галереи'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 6),

            // Программный mock для быстрой демонстрации преподавателю
            const Text(
              'Программный Mock (для демонстрации):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        () => _processScannedDocument(
                          null,
                          isCamera: false,
                          mockType: 'Бланк ОАК (Инвитро)',
                        ),
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('Бланк ОАК'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        () => _processScannedDocument(
                          null,
                          isCamera: false,
                          mockType: 'Биохимия (Гемотест)',
                        ),
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('Биохимия'),
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
