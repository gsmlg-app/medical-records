class ValidationUtils {
  static String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? minLengthValidator(String? value, int minLength) {
    if (value != null && value.trim().length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }

  static String? maxLengthValidator(String? value, int maxLength) {
    if (value != null && value.trim().length > maxLength) {
      return 'Must be no more than $maxLength characters';
    }
    return null;
  }

  static String? numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final numberRegex = RegExp(r'^\d+$');
    if (!numberRegex.hasMatch(value)) {
      return 'Please enter a valid number';
    }

    return null;
  }
}