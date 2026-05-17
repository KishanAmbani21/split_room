DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> parseStringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}

List<String> parseUuidList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}

Map<String, dynamic> toSnakeMap(Map<String, dynamic> map) {
  final out = <String, dynamic>{};
  for (final entry in map.entries) {
    out[_camelToSnake(entry.key)] = entry.value;
  }
  return out;
}

String _camelToSnake(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      )
      .replaceFirst(RegExp(r'^_'), '');
}
