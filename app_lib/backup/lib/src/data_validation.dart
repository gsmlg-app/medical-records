import 'package:app_logging/app_logging.dart';

/// Validation errors that can occur during data import
class ValidationError implements Exception {
  final String message;
  final String field;
  final dynamic value;

  ValidationError(this.message, this.field, [this.value]);

  @override
  String toString() => 'ValidationError: $message (field: $field, value: $value)';
}

/// Service for validating imported data before database insertion
class DataValidator {
  /// Validates a treatment JSON object
  static void validateTreatment(Map<String, dynamic> json) {
    _validateRequired(json, 'id', int);
    _validateRequired(json, 'title', String);
    _validateRequired(json, 'diagnosis', String);
    _validateRequired(json, 'startDate', String);
    _validateRequired(json, 'createdAt', String);
    _validateRequired(json, 'updatedAt', String);

    // Validate string lengths
    _validateStringLength(json, 'title', 1, 255);

    // Validate datetime fields
    _validateDateTime(json, 'startDate');
    _validateDateTime(json, 'createdAt');
    _validateDateTime(json, 'updatedAt');

    if (json['endDate'] != null) {
      _validateDateTime(json, 'endDate');

      // Validate that endDate is after startDate
      final startDate = DateTime.parse(json['startDate'] as String);
      final endDate = DateTime.parse(json['endDate'] as String);

      if (endDate.isBefore(startDate)) {
        throw ValidationError(
          'End date must be after start date',
          'endDate',
          json['endDate'],
        );
      }
    }

    AppLogger().d('Treatment validation passed: ${json['title']}');
  }

  /// Validates a visit JSON object
  static void validateVisit(Map<String, dynamic> json) {
    _validateRequired(json, 'id', int);
    _validateRequired(json, 'category', String);
    _validateRequired(json, 'date', String);
    _validateRequired(json, 'details', String);
    _validateRequired(json, 'createdAt', String);
    _validateRequired(json, 'updatedAt', String);

    // Validate enum values
    _validateEnum(json, 'category', ['outpatient', 'inpatient']);

    // Validate datetime fields
    _validateDateTime(json, 'date');
    _validateDateTime(json, 'createdAt');
    _validateDateTime(json, 'updatedAt');

    // Validate optional JSON field
    if (json['informations'] != null && json['informations'] is String) {
      try {
        // Ensure it's valid JSON if present
        final info = json['informations'] as String;
        if (info.isNotEmpty && info != 'null') {
          // Just basic check, don't need to parse
          if (!info.startsWith('{') && !info.startsWith('[')) {
            throw ValidationError(
              'informations field must be valid JSON',
              'informations',
              json['informations'],
            );
          }
        }
      } catch (e) {
        throw ValidationError(
          'informations field must be valid JSON',
          'informations',
          json['informations'],
        );
      }
    }

    AppLogger().d('Visit validation passed: ${json['id']}');
  }

  /// Validates a resource JSON object
  static void validateResource(Map<String, dynamic> json) {
    _validateRequired(json, 'id', int);
    _validateRequired(json, 'type', String);
    _validateRequired(json, 'filePath', String);
    _validateRequired(json, 'createdAt', String);
    _validateRequired(json, 'updatedAt', String);

    // Validate enum values
    _validateEnum(json, 'type', ['image', 'pdf', 'document']);

    // Validate file path format
    final filePath = json['filePath'] as String;
    if (filePath.isEmpty) {
      throw ValidationError(
        'File path cannot be empty',
        'filePath',
        filePath,
      );
    }

    // Validate datetime fields
    _validateDateTime(json, 'createdAt');
    _validateDateTime(json, 'updatedAt');

    AppLogger().d('Resource validation passed: ${json['filePath']}');
  }

  /// Validates a hospital JSON object
  static void validateHospital(Map<String, dynamic> json) {
    _validateRequired(json, 'name', String);

    // Validate string lengths
    _validateStringLength(json, 'name', 1, 255);

    // Validate departmentIds is valid JSON array
    if (json['departmentIds'] != null) {
      final deptIds = json['departmentIds'];
      if (deptIds is String) {
        try {
          // Should be a valid JSON array string
          if (!deptIds.startsWith('[') || !deptIds.endsWith(']')) {
            throw ValidationError(
              'departmentIds must be a valid JSON array',
              'departmentIds',
              deptIds,
            );
          }
        } catch (e) {
          throw ValidationError(
            'departmentIds must be a valid JSON array',
            'departmentIds',
            json['departmentIds'],
          );
        }
      }
    }

    AppLogger().d('Hospital validation passed: ${json['name']}');
  }

  /// Validates a department JSON object
  static void validateDepartment(Map<String, dynamic> json) {
    _validateRequired(json, 'name', String);

    // Validate string lengths
    _validateStringLength(json, 'name', 1, 255);

    AppLogger().d('Department validation passed: ${json['name']}');
  }

  /// Validates a doctor JSON object
  static void validateDoctor(Map<String, dynamic> json) {
    _validateRequired(json, 'name', String);
    _validateRequired(json, 'hospitalId', int);

    // Validate string lengths
    _validateStringLength(json, 'name', 1, 255);

    AppLogger().d('Doctor validation passed: ${json['name']}');
  }

  /// Validates manifest structure
  static void validateManifest(Map<String, dynamic> json) {
    _validateRequired(json, 'version', String);
    _validateRequired(json, 'exportDate', String);
    _validateRequired(json, 'treatments', List);

    // Validate version format (e.g., "1.0")
    final version = json['version'] as String;
    if (!RegExp(r'^\d+\.\d+$').hasMatch(version)) {
      throw ValidationError(
        'Invalid version format, expected "X.Y"',
        'version',
        version,
      );
    }

    // Validate export date
    _validateDateTime(json, 'exportDate');

    AppLogger().d('Manifest validation passed (version: $version)');
  }

  // Private helper methods

  static void _validateRequired(
    Map<String, dynamic> json,
    String field,
    Type expectedType,
  ) {
    if (!json.containsKey(field)) {
      throw ValidationError('Missing required field', field);
    }

    final value = json[field];
    if (value == null) {
      throw ValidationError('Field cannot be null', field);
    }

    // Type checking
    if (expectedType == int && value is! int) {
      throw ValidationError(
        'Expected type $expectedType but got ${value.runtimeType}',
        field,
        value,
      );
    }
    if (expectedType == String && value is! String) {
      throw ValidationError(
        'Expected type $expectedType but got ${value.runtimeType}',
        field,
        value,
      );
    }
    if (expectedType == List && value is! List) {
      throw ValidationError(
        'Expected type $expectedType but got ${value.runtimeType}',
        field,
        value,
      );
    }
  }

  static void _validateStringLength(
    Map<String, dynamic> json,
    String field,
    int minLength,
    int maxLength,
  ) {
    if (!json.containsKey(field)) return;

    final value = json[field];
    if (value is String) {
      if (value.length < minLength || value.length > maxLength) {
        throw ValidationError(
          'String length must be between $minLength and $maxLength',
          field,
          value,
        );
      }
    }
  }

  static void _validateDateTime(Map<String, dynamic> json, String field) {
    if (!json.containsKey(field)) return;

    final value = json[field];
    if (value == null) return;

    if (value is! String) {
      throw ValidationError(
        'DateTime field must be a string',
        field,
        value,
      );
    }

    try {
      DateTime.parse(value);
    } catch (e) {
      throw ValidationError(
        'Invalid ISO8601 datetime format',
        field,
        value,
      );
    }
  }

  static void _validateEnum(
    Map<String, dynamic> json,
    String field,
    List<String> allowedValues,
  ) {
    if (!json.containsKey(field)) return;

    final value = json[field];
    if (value == null) return;

    if (!allowedValues.contains(value)) {
      throw ValidationError(
        'Invalid enum value. Allowed: ${allowedValues.join(", ")}',
        field,
        value,
      );
    }
  }
}
