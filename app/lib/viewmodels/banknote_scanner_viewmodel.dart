import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/banknote_scan_result.dart';
import '../services/banknote_ocr_service.dart';

enum ScannerStatus { idle, loading, success, error }

class BanknoteScannerViewModel extends ChangeNotifier {
  BanknoteScannerViewModel({
    BanknoteOcrService? ocrService,
    ImagePicker? imagePicker,
  })  : _ocrService = ocrService ?? BanknoteOcrService(),
        _imagePicker = imagePicker ?? ImagePicker();

  final BanknoteOcrService _ocrService;
  final ImagePicker _imagePicker;

  ScannerStatus _status = ScannerStatus.idle;
  ScannerStatus get status => _status;

  File? _capturedImage;
  File? get capturedImage => _capturedImage;

  BanknoteScanResult? _scanResult;
  BanknoteScanResult? get scanResult => _scanResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> takePhotoAndScan() async {
    _setLoading();

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        _status = ScannerStatus.idle;
        notifyListeners();
        return;
      }

      _capturedImage = File(photo.path);
      _scanResult = await _ocrService.recognizeSerials(_capturedImage!);
      _status = ScannerStatus.success;
      notifyListeners();
    } catch (_) {
      _status = ScannerStatus.error;
      _errorMessage =
          'No se pudo procesar la imagen. Revisa permisos de camara e intenta de nuevo.';
      notifyListeners();
    }
  }

  void clearResult() {
    _capturedImage = null;
    _scanResult = null;
    _errorMessage = null;
    _status = ScannerStatus.idle;
    notifyListeners();
  }

  void _setLoading() {
    _errorMessage = null;
    _status = ScannerStatus.loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.close();
    super.dispose();
  }
}
