import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/banknote_scan_result.dart';

class BanknoteOcrService {
  BanknoteOcrService({TextRecognizer? textRecognizer})
      : _textRecognizer =
            textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _textRecognizer;

  Future<BanknoteScanResult> recognizeSerials(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final fullText = recognizedText.text;
    final serials = _extractPossibleSerials(fullText);

    return BanknoteScanResult(
      fullText: fullText,
      detectedSerials: serials,
      bestSerial: serials.isEmpty ? null : serials.first,
    );
  }

  Future<void> close() async {
    await _textRecognizer.close();
  }

  List<String> _extractPossibleSerials(String text) {
    final cleanText = text.toUpperCase().replaceAll('\n', ' ');
    final patterns = <RegExp>[
      RegExp(r'\b\d{7,9}\s?[A-Z]\b'),
      RegExp(r'\b[A-Z]\s?\d{7,9}\b'),
    ];

    final found = <String>[];
    for (final pattern in patterns) {
      final matches = pattern.allMatches(cleanText);
      for (final match in matches) {
        final value = match.group(0);
        if (value == null || value.trim().isEmpty) {
          continue;
        }
        found.add(_normalizeSerial(value));
      }
    }

    final counts = <String, int>{};
    for (final serial in found) {
      counts[serial] = (counts[serial] ?? 0) + 1;
    }

    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted;
  }

  String _normalizeSerial(String raw) {
    final noExtraSpaces = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final startsWithLetter = RegExp(r'^[A-Z]').hasMatch(noExtraSpaces);

    if (startsWithLetter) {
      final letter = noExtraSpaces.substring(0, 1);
      final digits = noExtraSpaces.replaceAll(RegExp(r'[^0-9]'), '');
      return '$digits $letter';
    }
    return noExtraSpaces;
  }
}
