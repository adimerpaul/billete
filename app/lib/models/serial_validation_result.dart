class SerialValidationResult {
  const SerialValidationResult({
    required this.serial,
    required this.isValid,
    required this.message,
    this.matchedDenomination,
  });

  final String serial;
  final bool isValid;
  final String message;
  final int? matchedDenomination;
}
