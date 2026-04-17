class Validators {
  Validators._();

  static String? validateAgentId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Agent ID is required';
    }
    if (value.length < 4) {
      return 'Agent ID must be at least 4 characters';
    }
    final validPattern = RegExp(r'^[A-Z0-9\-_]+$');
    if (!validPattern.hasMatch(value.toUpperCase())) {
      return 'Agent ID may only contain letters, numbers, hyphens and underscores';
    }
    return null;
  }

  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    if (value.length != 6) {
      return 'PIN must be exactly 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'PIN must contain only digits';
    }
    return null;
  }

  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateIntelContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Intel content is required';
    }
    if (value.trim().length < 10) {
      return 'Report must be at least 10 characters';
    }
    if (value.length > 4096) {
      return 'Report exceeds maximum length of 4096 characters';
    }
    return null;
  }
}
