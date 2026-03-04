import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/serial_validation_result.dart';
import '../services/banknote_ocr_service.dart';
import '../services/serial_validation_service.dart';

enum LiveCameraStatus { idle, scanning, valid, invalid, noSerial, error }

class BanknoteLiveCameraViewModel extends ChangeNotifier {
  BanknoteLiveCameraViewModel({
    BanknoteOcrService? ocrService,
    SerialValidationService? validationService,
  }) : _ocrService = ocrService ?? BanknoteOcrService(),
       _validationService = validationService ?? SerialValidationService();

  final BanknoteOcrService _ocrService;
  final SerialValidationService _validationService;

  LiveCameraStatus _status = LiveCameraStatus.idle;
  LiveCameraStatus get status => _status;

  SerialValidationResult? _result;
  SerialValidationResult? get result => _result;

  bool _isProcessing = false;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> processFrame(InputImage inputImage) async {
    final now = DateTime.now();
    if (_isProcessing ||
        now.difference(_lastProcessedAt).inMilliseconds < 700) {
      return;
    }

    _isProcessing = true;
    _lastProcessedAt = now;

    if (_status == LiveCameraStatus.idle) {
      _status = LiveCameraStatus.scanning;
      notifyListeners();
    }

    try {
      final ocrResult = await _ocrService.recognizeSerialsFromInputImage(
        inputImage,
      );
      final serial = ocrResult.bestSerial;
      if (serial == null) {
        _status = LiveCameraStatus.noSerial;
        notifyListeners();
        return;
      }

      final validation = _validationService.validate(rawSerial: serial);
      _result = validation;
      _status = validation.isValid
          ? LiveCameraStatus.valid
          : LiveCameraStatus.invalid;
      notifyListeners();
    } catch (_) {
      _status = LiveCameraStatus.error;
      notifyListeners();
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _ocrService.close();
    super.dispose();
  }
}
