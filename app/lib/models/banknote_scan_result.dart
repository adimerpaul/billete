class BanknoteScanResult {
  const BanknoteScanResult({
    required this.fullText,
    required this.detectedSerials,
    this.bestSerial,
  });

  final String fullText;
  final List<String> detectedSerials;
  final String? bestSerial;
}
