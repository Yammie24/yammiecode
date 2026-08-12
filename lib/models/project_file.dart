class ProjectFile {
  final String name;
  final String path;
  final bool isDirectory;

  String content;

  ProjectFile({
    required this.name,
    required this.path,
    required this.content,
    this.isDirectory = false,
  });

  ProjectFile copyWith({
    String? name,
    String? path,
    String? content,
    bool? isDirectory,
  }) {
    return ProjectFile(
      name: name ?? this.name,
      path: path ?? this.path,
      content: content ?? this.content,
      isDirectory: isDirectory ?? this.isDirectory,
    );
  }
}