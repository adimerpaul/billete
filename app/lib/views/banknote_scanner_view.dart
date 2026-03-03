import 'dart:io';

import 'package:flutter/material.dart';

import '../viewmodels/banknote_scanner_viewmodel.dart';

class BanknoteScannerView extends StatefulWidget {
  const BanknoteScannerView({super.key});

  @override
  State<BanknoteScannerView> createState() => _BanknoteScannerViewState();
}

class _BanknoteScannerViewState extends State<BanknoteScannerView> {
  late final BanknoteScannerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BanknoteScannerViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escaner de series')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildActionCard(context),
              const SizedBox(height: 16),
              if (_viewModel.capturedImage != null)
                _buildImagePreview(_viewModel.capturedImage!),
              if (_viewModel.capturedImage != null) const SizedBox(height: 16),
              _buildResultCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Proceso recomendado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('1. Coloca el billete en una superficie plana.'),
            const Text('2. Asegura buena iluminacion.'),
            const Text('3. Captura con la serie visible (arriba o abajo).'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _viewModel.status == ScannerStatus.loading
                  ? null
                  : _viewModel.takePhotoAndScan,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                _viewModel.status == ScannerStatus.loading
                    ? 'Procesando...'
                    : 'Tomar captura',
              ),
            ),
            if (_viewModel.scanResult != null) const SizedBox(height: 8),
            if (_viewModel.scanResult != null)
              OutlinedButton(
                onPressed: _viewModel.clearResult,
                child: const Text('Limpiar resultado'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File imageFile) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Imagen capturada',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(
              imageFile,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _viewModel.scanResult;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultado OCR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_viewModel.status == ScannerStatus.idle)
              const Text('Aun no hay una captura procesada.'),
            if (_viewModel.status == ScannerStatus.loading)
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Reconociendo texto...'),
                ],
              ),
            if (_viewModel.status == ScannerStatus.error)
              Text(
                _viewModel.errorMessage ?? 'Ocurrio un error inesperado.',
                style: const TextStyle(color: Colors.red),
              ),
            if (_viewModel.status == ScannerStatus.success && result != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.bestSerial == null
                        ? 'Serie principal: No detectada'
                        : 'Serie principal: ${result.bestSerial}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Series detectadas: ${result.detectedSerials.isEmpty ? '0' : result.detectedSerials.length}',
                  ),
                  const SizedBox(height: 4),
                  if (result.detectedSerials.isNotEmpty)
                    Text(result.detectedSerials.join(', ')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
