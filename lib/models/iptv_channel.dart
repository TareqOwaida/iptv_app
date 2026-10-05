class IptvChannel {
  const IptvChannel({
    required this.name,
    required this.url,
    this.category,
    this.httpHeaders,
  });

  final String name;
  final String url;
  final String? category;

  /// Per-channel HTTP headers from M3U (e.g. `#EXTVLCOPT:http-user-agent=...`).
  final Map<String, String>? httpHeaders;
}
