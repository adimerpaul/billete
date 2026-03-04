import 'package:flutter/foundation.dart';

import '../models/serial_validation_result.dart';
import '../services/serial_validation_service.dart';

enum ValidatorStatus { idle, success, error }

class BanknoteValidatorViewModel extends ChangeNotifier {
  BanknoteValidatorViewModel({SerialValidationService? validationService})
    : _validationService = validationService ?? SerialValidationService();

  final SerialValidationService _validationService;

  ValidatorStatus _status = ValidatorStatus.idle;
  ValidatorStatus get status => _status;

  SerialValidationResult? _validationResult;
  SerialValidationResult? get validationResult => _validationResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void applyCameraResult(SerialValidationResult result) {
    _validationResult = result;
    _errorMessage = null;
    _status = ValidatorStatus.success;
    notifyListeners();
  }

  void validateManual(String rawSerial) {
    final result = _validationService.validate(rawSerial: rawSerial);
    _validationResult = result;
    _status = result.serial.isEmpty
        ? ValidatorStatus.error
        : ValidatorStatus.success;
    _errorMessage = result.serial.isEmpty ? result.message : null;
    notifyListeners();
  }

  void clear() {
    _validationResult = null;
    _errorMessage = null;
    _status = ValidatorStatus.idle;
    notifyListeners();
  }
}
