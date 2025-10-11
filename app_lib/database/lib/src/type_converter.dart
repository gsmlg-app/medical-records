import 'dart:convert';

import 'package:drift/drift.dart';

// Converter for List<int> (used for department IDs in Hospitals table)
class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();

  @override
  List<int> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return (json.decode(fromDb) as List)
        .map((e) => int.parse(e.toString()))
        .toList();
  }

  @override
  String toSql(List<int> value) {
    return json.encode(value);
  }
}

// Converter for List<String> (if needed in the future)
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return (json.decode(fromDb) as List).map((e) => e.toString()).toList();
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

// Converter for Map<String, dynamic> (used for informations field in Visits table)
class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    if (fromDb.isEmpty) return {};
    return json.decode(fromDb) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}
