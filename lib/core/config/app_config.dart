class AppConfig {
  final List<String> categories;

  const AppConfig({required this.categories});

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
    );
  }
}
