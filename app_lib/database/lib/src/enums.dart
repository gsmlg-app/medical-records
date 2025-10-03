// Simple enum classes for visit categories and resource types

class VisitCategory {
  final String value;

  const VisitCategory._(this.value);

  static const VisitCategory outpatient = VisitCategory._('outpatient');
  static const VisitCategory inpatient = VisitCategory._('inpatient');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitCategory &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class ResourceType {
  final String value;

  const ResourceType._(this.value);

  static const ResourceType image = ResourceType._('image');
  static const ResourceType document = ResourceType._('document');
  static const ResourceType video = ResourceType._('video');
  static const ResourceType audio = ResourceType._('audio');
  static const ResourceType other = ResourceType._('other');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceType &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}