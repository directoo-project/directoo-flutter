typedef Json = Map<String, dynamic>;

Json asJson(dynamic value) {
  if (value is Json) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<Json> asJsonList(dynamic value) {
  final raw = value is Map && value['results'] is List ? value['results'] : value;
  if (raw is! List) return const [];
  return [for (final item in raw) asJson(item)];
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? fallback;
}

double asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

String asString(dynamic value) => value == null ? '' : '$value';

bool asBool(dynamic value) => value == true || value == 1 || value == 'true';

List<String> asStringList(dynamic value) {
  if (value is! List) return const [];
  return [for (final item in value) asString(item)];
}
