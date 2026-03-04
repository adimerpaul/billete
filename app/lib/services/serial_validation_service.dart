import '../models/serial_range_rule.dart';
import '../models/serial_validation_result.dart';

class SerialValidationService {
  // Rangos inhabilitados de las imagenes recibidas (Bs10, Bs20, Bs50).
  static const List<SerialRangeRule> blockedRanges = [
    // Bs10
    SerialRangeRule(denomination: 10, start: 77100001, end: 77550000),
    SerialRangeRule(denomination: 10, start: 78000001, end: 78450000),
    SerialRangeRule(denomination: 10, start: 78900001, end: 96350000),
    SerialRangeRule(denomination: 10, start: 96350001, end: 96800000),
    SerialRangeRule(denomination: 10, start: 96800001, end: 97250000),
    SerialRangeRule(denomination: 10, start: 98150001, end: 98600000),
    SerialRangeRule(denomination: 10, start: 104900001, end: 105350000),
    SerialRangeRule(denomination: 10, start: 105350001, end: 105800000),
    SerialRangeRule(denomination: 10, start: 106700001, end: 107150000),
    SerialRangeRule(denomination: 10, start: 107600001, end: 108050000),
    SerialRangeRule(denomination: 10, start: 108050001, end: 108500000),
    SerialRangeRule(denomination: 10, start: 109400001, end: 109850000),
    // Bs20
    SerialRangeRule(denomination: 20, start: 87280145, end: 91646549),
    SerialRangeRule(denomination: 20, start: 96650001, end: 97100000),
    SerialRangeRule(denomination: 20, start: 99800001, end: 100250000),
    SerialRangeRule(denomination: 20, start: 100250001, end: 100700000),
    SerialRangeRule(denomination: 20, start: 109250001, end: 109700000),
    SerialRangeRule(denomination: 20, start: 110600001, end: 111050000),
    SerialRangeRule(denomination: 20, start: 111050001, end: 111500000),
    SerialRangeRule(denomination: 20, start: 111950001, end: 112400000),
    SerialRangeRule(denomination: 20, start: 112400001, end: 112850000),
    SerialRangeRule(denomination: 20, start: 112850001, end: 113300000),
    SerialRangeRule(denomination: 20, start: 114200001, end: 114650000),
    SerialRangeRule(denomination: 20, start: 114650001, end: 115100000),
    SerialRangeRule(denomination: 20, start: 115100001, end: 115550000),
    SerialRangeRule(denomination: 20, start: 118700001, end: 119150000),
    SerialRangeRule(denomination: 20, start: 119150001, end: 119600000),
    SerialRangeRule(denomination: 20, start: 120500001, end: 120950000),
    // Bs50
    SerialRangeRule(denomination: 50, start: 67250001, end: 67700000),
    SerialRangeRule(denomination: 50, start: 69050001, end: 69500000),
    SerialRangeRule(denomination: 50, start: 69500001, end: 69950000),
    SerialRangeRule(denomination: 50, start: 69950001, end: 70400000),
    SerialRangeRule(denomination: 50, start: 70400001, end: 70850000),
    SerialRangeRule(denomination: 50, start: 70850001, end: 71300000),
    SerialRangeRule(denomination: 50, start: 76310012, end: 85139995),
    SerialRangeRule(denomination: 50, start: 86400001, end: 86850000),
    SerialRangeRule(denomination: 50, start: 90900001, end: 91350000),
    SerialRangeRule(denomination: 50, start: 91800001, end: 92250000),
  ];

  String? normalizeSerial(String raw) {
    final text = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (text.isEmpty) {
      return null;
    }

    final digitsMatch = RegExp(r'\d{7,9}').firstMatch(text);
    if (digitsMatch == null) {
      return null;
    }

    final digits = digitsMatch.group(0)!;
    final letterMatch = RegExp(r'[A-Z]').firstMatch(text);
    if (letterMatch == null) {
      return digits;
    }
    return '$digits ${letterMatch.group(0)!}';
  }

  SerialValidationResult validate({required String rawSerial}) {
    final normalized = normalizeSerial(rawSerial);
    if (normalized == null) {
      return const SerialValidationResult(
        serial: '',
        isValid: false,
        message: 'Serie invalida. Ejemplo: 22588538 A',
      );
    }

    final digits = int.tryParse(normalized.replaceAll(RegExp(r'[^0-9]'), ''));
    if (digits == null) {
      return const SerialValidationResult(
        serial: '',
        isValid: false,
        message: 'No se pudo interpretar la serie.',
      );
    }

    final matchedRange = blockedRanges.where((range) {
      return digits >= range.start && digits <= range.end;
    }).toList();

    if (matchedRange.isNotEmpty) {
      final denomination = matchedRange.first.denomination;
      return SerialValidationResult(
        serial: normalized,
        isValid: false,
        message: 'Billete INHABILITADO para Bs $denomination.',
        matchedDenomination: denomination,
      );
    }

    return SerialValidationResult(
      serial: normalized,
      isValid: true,
      message: 'Billete VALIDO. No esta en rangos inhabilitados.',
    );
  }
}
