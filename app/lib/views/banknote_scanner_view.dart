import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/serial_validation_result.dart';
import '../viewmodels/banknote_live_camera_viewmodel.dart';

class BanknoteScannerView extends StatefulWidget {
  const BanknoteScannerView({super.key});

  @override
  State<BanknoteScannerView> createState() => _BanknoteScannerViewState();
}

class _BanknoteScannerViewState extends State<BanknoteScannerView> {
  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;
  late final BanknoteLiveCameraViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BanknoteLiveCameraViewModel();
    _cameraInitFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (!mounted || cameras.isEmpty) {
      return;
    }

    final rearCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      rearCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await controller.initialize();
    _cameraController = controller;
    await controller.startImageStream(_processCameraImage);
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final controller = _cameraController;
    if (controller == null || !mounted) {
      return;
    }

    final inputImage = _toInputImage(image, controller.description);
    if (inputImage == null) {
      return;
    }

    await _viewModel.processFrame(inputImage);
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null || image.planes.isEmpty) {
      return null;
    }

    late final Uint8List bytes;
    late final InputImageFormat format;
    late final int bytesPerRow;

    if (Platform.isAndroid) {
      final detectedFormat = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );
      if (detectedFormat == InputImageFormat.nv21 && image.planes.length == 1) {
        bytes = image.planes.first.bytes;
        format = InputImageFormat.nv21;
        bytesPerRow = image.planes.first.bytesPerRow;
      } else if (detectedFormat == InputImageFormat.yuv_420_888) {
        bytes = Uint8List.fromList([
          for (final plane in image.planes) ...plane.bytes,
        ]);
        format = InputImageFormat.yuv_420_888;
        bytesPerRow = image.planes.first.bytesPerRow;
      } else {
        return null;
      }
    } else if (Platform.isIOS) {
      bytes = image.planes.first.bytes;
      format = InputImageFormat.bgra8888;
      bytesPerRow = image.planes.first.bytesPerRow;
    } else {
      final detectedFormat = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );
      if (detectedFormat == null) {
        return null;
      }
      bytes = Uint8List.fromList([
        for (final plane in image.planes) ...plane.bytes,
      ]);
      format = detectedFormat;
      bytesPerRow = image.planes.first.bytesPerRow;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
  }

  void _goBack() {
    Navigator.of(context).pop<SerialValidationResult?>(_viewModel.result);
  }

  @override
  void dispose() {
    if (_cameraController?.value.isStreamingImages ?? false) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(child: _buildCameraSection()),
              Positioned(
                top: 48,
                left: 16,
                child: _GlassButton(
                  icon: Icons.arrow_back,
                  label: 'Atras',
                  onPressed: _goBack,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 28,
                child: _buildStatusPanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraSection() {
    return FutureBuilder<void>(
      future: _cameraInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            _cameraController == null ||
            !_cameraController!.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final frameWidth = constraints.maxWidth * 0.86;
            final frameHeight = constraints.maxHeight * 0.22;
            final previewSize = _cameraController!.value.previewSize;
            return Stack(
              children: [
                Positioned.fill(
                  child: previewSize == null
                      ? CameraPreview(_cameraController!)
                      : ClipRect(
                          child: ColoredBox(
                            color: Colors.black,
                            child: SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: previewSize.height,
                                  height: previewSize.width,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                Positioned.fill(
                  child: _CaptureOverlay(
                    frameWidth: frameWidth,
                    frameHeight: frameHeight,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    final result = _viewModel.result;
    final status = _viewModel.status;

    String title = 'Escaneando serie...';
    Color color = const Color(0xFF2E86DE);
    Color bgColor = Colors.black.withOpacity(0.68);
    String subtitle = 'Apunta la serie dentro del recuadro.';

    if (status == LiveCameraStatus.invalid && result != null) {
      title = 'INVALIDO';
      color = const Color(0xFFFF4D4F);
      bgColor = const Color(0xAA4A1414);
      subtitle = '${result.serial} | ${result.message}';
    } else if (status == LiveCameraStatus.valid && result != null) {
      title = 'VALIDO';
      color = const Color(0xFF2ECC71);
      bgColor = const Color(0xAA113C2A);
      subtitle = '${result.serial} | ${result.message}';
    } else if (status == LiveCameraStatus.noSerial) {
      title = 'Sin lectura';
      color = const Color(0xFFF5B041);
      bgColor = const Color(0xAA4C3B12);
      subtitle = 'No se detecta una serie legible.';
    } else if (status == LiveCameraStatus.error) {
      title = 'Error';
      color = const Color(0xFFFF4D4F);
      bgColor = const Color(0xAA4A1414);
      subtitle = 'No se pudo procesar el frame.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.95), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.42),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureOverlay extends StatelessWidget {
  const _CaptureOverlay({required this.frameWidth, required this.frameHeight});

  final double frameWidth;
  final double frameHeight;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          Expanded(child: Container(color: Colors.black45)),
          Row(
            children: [
              Expanded(child: Container(color: Colors.black45)),
              Container(
                width: frameWidth,
                height: frameHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              Expanded(child: Container(color: Colors.black45)),
            ],
          ),
          Expanded(child: Container(color: Colors.black45)),
        ],
      ),
    );
  }
}
