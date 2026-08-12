import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/project_file.dart';

class ProjectService {
  static const String projectsFolder = 'projects';

  static Future<Directory> _projectsDirectory() async {
    final base = await getApplicationDocumentsDirectory();

    final directory = Directory(
      '${base.path}/$projectsFolder',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  static Future<Directory> _projectDirectory(
    String projectName,
  ) async {
    final projects = await _projectsDirectory();

    final directory = Directory(
      '${projects.path}/$projectName',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  static Future<List<String>> getProjects() async {
    final directory = await _projectsDirectory();

    final entries = await directory.list().toList();

    return entries
        .whereType<Directory>()
        .map(
          (directory) =>
              directory.path.split('/').last,
        )
        .toList();
  }

  static Future<void> createProject(
    String projectName,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    final mainFile = File(
      '${directory.path}/main.py',
    );

    if (!await mainFile.exists()) {
      await mainFile.writeAsString(
        '''def main():
    print("Hello from YammieCode!")


if __name__ == "__main__":
    main()
''',
      );
    }

    final requirements = File(
      '${directory.path}/requirements.txt',
    );

    if (!await requirements.exists()) {
      await requirements.writeAsString('');
    }
  }

  static Future<List<ProjectFile>> loadFiles(
    String projectName,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    final entries = await directory.list().toList();

    final files = <ProjectFile>[];

    for (final entry in entries) {
      if (entry is File) {
        final name =
            entry.path.split('/').last;

        final content =
            await entry.readAsString();

        files.add(
          ProjectFile(
            name: name,
            content: content,
          ),
        );
      }
    }

    files.sort(
      (a, b) => a.name.compareTo(b.name),
    );

    return files;
  }

  static Future<void> saveFile(
    String projectName,
    ProjectFile file,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    final target = File(
      '${directory.path}/${file.name}',
    );

    await target.writeAsString(
      file.content,
    );
  }

  static Future<void> createFile(
    String projectName,
    String fileName,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    final file = File(
      '${directory.path}/$fileName',
    );

    if (!await file.exists()) {
      await file.writeAsString('');
    }
  }

  static Future<void> deleteFile(
    String projectName,
    String fileName,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    final file = File(
      '${directory.path}/$fileName',
    );

    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> deleteProject(
    String projectName,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    if (await directory.exists()) {
      await directory.delete(
        recursive: true,
      );
    }
  }
}
