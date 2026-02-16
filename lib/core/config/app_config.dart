class AppConfig {
  final List<String> categories;
  final String latestVersion;
  final String minVersion;

  const AppConfig({
    required this.categories,
    this.latestVersion = '1.0.0',
    this.minVersion = '1.0.0',
  });

  factory AppConfig.fromMap(Map<String, dynamic>? map) {
    final raw = map?['categories'];
    final cats = raw is List
        ? raw
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

    return AppConfig(
      categories: cats.isEmpty ? const ['힐링', '응원', '행복', '지혜', '기타'] : cats,
      latestVersion: map?['latest_version'] ?? '1.0.0',
      minVersion: map?['min_version'] ?? '1.0.0',
    );
  }
}
