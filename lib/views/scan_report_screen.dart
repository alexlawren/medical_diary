import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_parser_service.dart';
import '../viewmodels/health_viewmodel.dart';
import 'lab_details_screen.dart';

/// Слой VIEW: сканирование печатного лабораторного бланка камерой/из галереи.
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
  final OcrParserService _ocrService = OcrParserService();

  Future<void> _captureFromCamera() async {
    if (_isProcessing) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
      maxWidth: 3000,
      maxHeight: 4000,
    );

    if (pickedFile != null) {
      await _processImageWithOcr(File(pickedFile.path));
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      await _processImageWithOcr(File(pickedFile.path));
    }
  }

  Future<void> _processImageWithOcr(File imageFile) async {
    setState(() {
      _scannedImage = imageFile;
      _isProcessing = true;
    });

    try {
      final parsedReport = await _ocrService.processImage(imageFile);

      // ЛР №4: после OCR данные сверяются с Realm, сохраняются в SQLite
      // и публикуются в реактивный поток вместе с активностью.
      final processedReport =
          await widget.viewModel.processScannedReport(parsedReport);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Бланк распознан'),
          content: Text(
            'Исследование: ${processedReport.title}\n'
            'Лаборатория: ${processedReport.laboratory}\n'
            'Распознано показателей: ${processedReport.markers.length}\n'
            'Сверено с Realm: ${widget.viewModel.lastMatchedReferenceCount}\n'
            'Отклонений от нормы: ${processedReport.abnormalCount}\n'
            'Реактивный поток: ${widget.viewModel.pipelineStatus}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => LabDetailsScreen(report: processedReport),
                  ),
                );
              },
              child: const Text('Открыть карточку'),
            ),
          ],
        ),
      );
    } on OcrParsingException catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await _showRecognitionError(e.message);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await _showRecognitionError(
        'Во время OCR произошла ошибка: $e',
      );
    }
  }

  Future<void> _showRecognitionError(String message) async {
    final raw = _ocrService.lastRecognizedText.trim();
    final preview = raw.isEmpty
        ? ''
        : raw.length > 450
            ? '${raw.substring(0, 450)}…'
            : raw;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Не удалось распознать бланк'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'OCR при этом прочитал:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  preview,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканер бланков анализов'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal, width: 2),
                ),
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Лучший результат получается, когда лист занимает почти весь кадр, '
              'текст находится в фокусе, а на таблице нет бликов.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Камера'),
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
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Распознаю текст и таблицу…',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (_scannedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(_scannedImage!, fit: BoxFit.contain),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.document_scanner_outlined, size: 70, color: Colors.teal),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Сфотографируйте печатный бланк лабораторного анализа '
            'или выберите его фотографию из галереи.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
