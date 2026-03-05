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
  static const int _minConsistentDetections = 2;

  String? _candidateSerial;
  int _candidateHits = 0;
  String? _lastSeenSerial;
  String? get lastSeenSerial => _lastSeenSerial;

  Future<bool> processFrame(InputImage inputImage) async {
    if (_status == LiveCameraStatus.valid || _status == LiveCameraStatus.invalid) {
      return true;
    }

    final now = DateTime.now();
    if (_isProcessing ||
        now.difference(_lastProcessedAt).inMilliseconds < 550) {
      return false;
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
        _candidateSerial = null;
        _candidateHits = 0;
        _status = LiveCameraStatus.noSerial;
        notifyListeners();
        return false;
      }

      _lastSeenSerial = serial;
      if (_candidateSerial == serial) {
        _candidateHits += 1;
      } else {
        _candidateSerial = serial;
        _candidateHits = 1;
      }

      if (_candidateHits < _minConsistentDetections) {
        if (_status != LiveCameraStatus.scanning) {
          _status = LiveCameraStatus.scanning;
          notifyListeners();
        }
        return false;
      }

      final validation = _validationService.validate(rawSerial: serial);
      _result = validation;
      _status = validation.isValid
          ? LiveCameraStatus.valid
          : LiveCameraStatus.invalid;
      notifyListeners();
      return true;
    } catch (_) {
      _status = LiveCameraStatus.error;
      notifyListeners();
      return false;
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
