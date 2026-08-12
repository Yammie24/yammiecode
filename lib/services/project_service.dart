import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/project_file.dart';

class ProjectService {
  static const String projectsFolder = 'projects';

  // ------------------------------------------------------------
  // INTERNAL YAMMIECODE STORAGE
  // ------------------------------------------------------------

  static Future<Directory> _projectsDirectory() async {
    final base = await getApplicationDocumentsDirectory();

    final directory = Directory(
      p.join(base.path, projectsFolder),
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
      p.join(projects.path, projectName),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  // ------------------------------------------------------------
  // PROJECT PICKER
  // ------------------------------------------------------------

  /// Opens Android's native folder picker.
  ///
  /// Returns the selected project directory path,
  /// or null if the user cancels.
  static Future<String?> pickProjectDirectory() async {
    try {
      final path = await FilePicker.getDirectoryPath(
        dialogTitle: 'Open Python Project',
        lockParentWindow: false,
      );

      return path;
    } catch (error) {
      throw Exception(
        'Unable to open the file manager: $error',
      );
    }
  }

  // ------------------------------------------------------------
  // PROJECT NAME
  // ------------------------------------------------------------

  static String projectNameFromPath(String path) {
    final normalized = p.normalize(path);

    final name = p.basename(normalized);

    if (name.isEmpty) {
      return 'Untitled Project';
    }

    return name;
  }

  // ------------------------------------------------------------
  // READ PROJECT
  // ------------------------------------------------------------

  /// Loads files from an actual project directory.
  ///
  /// Only files in the project root are returned here.
  /// Folder support is handled separately by loadTree().
  static Future<List<ProjectFile>> loadFilesFromPath(
    String projectPath,
  ) async {
    final directory = Directory(projectPath);

    if (!await directory.exists()) {
      throw Exception(
        'Project directory does not exist:\n$projectPath',
      );
    }

    final entries = await directory.list().toList();

    final files = <ProjectFile>[];

    for (final entry in entries) {
      if (entry is File) {
        try {
          final content = await entry.readAsString();

          files.add(
            ProjectFile(
              name: p.basename(entry.path),
              path: entry.path,
              content: content,
            ),
          );
        } catch (_) {
          // Ignore files that cannot be decoded as text.
        }
      }
    }

    files.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return files;
  }

  // ------------------------------------------------------------
  // LOAD DIRECTORY TREE
  // ------------------------------------------------------------

  static Future<List<ProjectFile>> loadTree(
    String projectPath,
  ) async {
    final directory = Directory(projectPath);

    if (!await directory.exists()) {
      throw Exception(
        'Project directory does not exist.',
      );
    }

    final result = <ProjectFile>[];

    await _walkDirectory(
      directory,
      result,
    );

    result.sort(
      (a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }

        return a.path.toLowerCase().compareTo(
              b.path.toLowerCase(),
            );
      },
    );

    return result;
  }

  static Future<void> _walkDirectory(
    Directory directory,
    List<ProjectFile> result,
  ) async {
    final entries = await directory.list().toList();

    for (final entry in entries) {
      final name = p.basename(entry.path);

      // Hide common build/system folders.
      if (_shouldIgnore(name)) {
        continue;
      }

      if (entry is Directory) {
        result.add(
          ProjectFile(
            name: name,
            path: entry.path,
            content: '',
            isDirectory: true,
          ),
        );

        await _walkDirectory(
          entry,
          result,
        );
      } else if (entry is File) {
        try {
          final content = await entry.readAsString();

          result.add(
            ProjectFile(
              name: name,
              path: entry.path,
              content: content,
            ),
          );
        } catch (_) {
          // Ignore binary/unreadable files.
        }
      }
    }
  }

  static bool _shouldIgnore(String name) {
    return name == '.git' ||
        name == '.dart_tool' ||
        name == 'build' ||
        name == '__pycache__' ||
        name == '.idea' ||
        name == '.gradle';
  }

  // ------------------------------------------------------------
  // SAVE FILE
  // ------------------------------------------------------------

  static Future<void> saveFile(
    String projectName,
    ProjectFile file,
  ) async {
    if (file.isDirectory) {
      return;
    }

    final target = File(file.path);

    final parent = target.parent;

    if (!await parent.exists()) {
      await parent.create(
        recursive: true,
      );
    }

    await target.writeAsString(
      file.content,
    );
  }

  // ------------------------------------------------------------
  // SAVE FILE DIRECTLY
  // ------------------------------------------------------------

  static Future<void> saveFileAtPath(
    String filePath,
    String content,
  ) async {
    final file = File(filePath);

    final parent = file.parent;

    if (!await parent.exists()) {
      await parent.create(
        recursive: true,
      );
    }

    await file.writeAsString(content);
  }

  // ------------------------------------------------------------
  // CREATE FILE
  // ------------------------------------------------------------

  static Future<String> createFileAtPath(
    String directoryPath,
    String fileName, {
    String content = '',
  }) async {
    final safeName = p.basename(fileName.trim());

    if (safeName.isEmpty) {
      throw Exception(
        'Please enter a valid file name.',
      );
    }

    final filePath = p.join(
      directoryPath,
      safeName,
    );

    final file = File(filePath);

    if (!await file.exists()) {
      await file.writeAsString(content);
    }

    return filePath;
  }

  // ------------------------------------------------------------
  // CREATE FOLDER
  // ------------------------------------------------------------

  static Future<String> createFolderAtPath(
    String directoryPath,
    String folderName,
  ) async {
    final safeName = p.basename(folderName.trim());

    if (safeName.isEmpty) {
      throw Exception(
        'Please enter a valid folder name.',
      );
    }

    final folderPath = p.join(
      directoryPath,
      safeName,
    );

    final directory = Directory(folderPath);

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return folderPath;
  }

  // ------------------------------------------------------------
  // DELETE FILE
  // ------------------------------------------------------------

  static Future<void> deleteFileAtPath(
    String filePath,
  ) async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  // ------------------------------------------------------------
  // DELETE FOLDER
  // ------------------------------------------------------------

  static Future<void> deleteFolderAtPath(
    String folderPath,
  ) async {
    final directory = Directory(folderPath);

    if (await directory.exists()) {
      await directory.delete(
        recursive: true,
      );
    }
  }

  // ------------------------------------------------------------
  // RENAME
  // ------------------------------------------------------------

  static Future<String> renamePath(
    String oldPath,
    String newName,
  ) async {
    final name = p.basename(newName.trim());

    if (name.isEmpty) {
      throw Exception(
        'Please enter a valid name.',
      );
    }

    final parent = Directory(oldPath).existsSync()
        ? Directory(oldPath).parent.path
        : File(oldPath).parent.path;

    final newPath = p.join(
      parent,
      name,
    );

    if (FileSystemEntity.typeSync(oldPath) ==
        FileSystemEntityType.directory) {
      await Directory(oldPath).rename(newPath);
    } else {
      await File(oldPath).rename(newPath);
    }

    return newPath;
  }

  // ------------------------------------------------------------
  // OLD INTERNAL PROJECT API
  // ------------------------------------------------------------

  static Future<List<String>> getProjects() async {
    final directory = await _projectsDirectory();

    final entries = await directory.list().toList();

    return entries
        .whereType<Directory>()
        .map(
          (directory) => p.basename(directory.path),
        )
        .toList();
  }

  static Future<void> createProject(
    String projectName,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    final mainFile = File(
      p.join(directory.path, 'main.py'),
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
      p.join(
        directory.path,
        'requirements.txt',
      ),
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

    return loadFilesFromPath(
      directory.path,
    );
  }

  static Future<void> createFile(
    String projectName,
    String fileName,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    await createFileAtPath(
      directory.path,
      fileName,
    );
  }

  static Future<void> deleteFile(
    String projectName,
    String fileName,
  ) async {
    final directory =
        await _projectDirectory(projectName);

    await deleteFileAtPath(
      p.join(
        directory.path,
        fileName,
      ),
    );
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