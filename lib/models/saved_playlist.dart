class SavedPlaylist {
  const SavedPlaylist({
    required this.id,
    required this.name,
    required this.fileName,
  });

  final String id;
  final String name;
  final String fileName;

  Map<String, String> toJson() {
    return <String, String>{
      'id': id,
      'name': name,
      'fileName': fileName,
    };
  }

  factory SavedPlaylist.fromJson(Map<String, dynamic> json) {
    return SavedPlaylist(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
    );
  }
}
