// Shared bulk-paste parser for filter values. Used by typed filter dialog.

/// Parses bulk-pasted text into a list of non-empty, trimmed, deduplicated values.
/// Supports separators: newline, comma, semicolon, tab. Order of first occurrence is preserved.
List<String> parseBulkPasteValues(String raw) {
  if (raw.trim().isEmpty) return [];
  final parts = raw
      .split(RegExp(r'[\n,;\t]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final seen = <String>{};
  final result = <String>[];
  for (final p in parts) {
    if (seen.add(p)) result.add(p);
  }
  return result;
}

/// Returns (parsedCount, uniqueCount) for bulk paste summary.
(int, int) bulkPasteCounts(String raw) {
  if (raw.trim().isEmpty) return (0, 0);
  final parts = raw
      .split(RegExp(r'[\n,;\t]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final unique = parts.toSet().length;
  return (parts.length, unique);
}
