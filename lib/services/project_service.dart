import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/project_file.dart';

class ProjectService {
  static const String projectsFolder = 'projects';

  // ============================================================
  // INTERNAL PROJECT STORAGE
  //
  // Used when the user creates a new project inside YammieCode.
  // Projects created here are still real files on the device.
  // ============================================================

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

    final safeName = p.basename(
      projectName.trim(),
    );

    if (safeName.isEmpty) {
      throw Exception(
        'Invalid project name.',
      );
    }

    final directory = Directory(
      p.join(projects.path, safeName),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  // ============================================================
  // OPEN PROJECT FOLDER
  // ============================================================

  /// Opens the device's native folder picker.
  ///
  /// Returns the selected folder path.
  /// Returns null when the user cancels.
  static Future<String?> pickProjectDirectory() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Open Python Project',
        lockParentWindow: false,
      );

      if (path == null || path.trim().isEmpty) {
        return null;
      }

      return path;
    } catch (error) {
      throw Exception(
        'Unable to open the folder picker:\n$error',
      );
    }
  }

  // ============================================================
  // PROJECT NAME
  // ============================================================

  static String projectNameFromPath(
    String path,
  ) {
    final normalized = p.normalize(path);

    final name = p.basename(
      normalized,
    );

    if (name.isEmpty || name == '.') {
      return 'Untitled Project';
    }

    return name;
  }

  // ============================================================
  // CHECK DIRECTORY
  // ============================================================

  static Future<bool> directoryExists(
    String path,
  ) async {
    return Directory(path).exists();
  }

  // ============================================================
  // LOAD ROOT FILES
  // ============================================================

  /// Loads files directly inside the project root.
  ///
  /// This is useful when the editor only needs root-level files.
  static Future<List<ProjectFile>> loadFilesFromPath(
    String projectPath,
  ) async {
    final directory = Directory(projectPath);

    if (!await directory.exists()) {
      throw Exception(
        'Project directory does not exist:\n$projectPath',
      );
    }

    final entries = await directory.list(
      followLinks: false,
    ).toList();

    final files = <ProjectFile>[];

    for (final entry in entries) {
      if (entry is! File) {
        continue;
      }

      try {
        final content = await entry.readAsString();

        files.add(
          ProjectFile(
            name: p.basename(entry.path),
            path: entry.path,
            content: content,
            isDirectory: false,
          ),
        );
      } catch (_) {
        // Binary or unreadable files are ignored.
      }
    }

    files.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return files;
  }

  // ============================================================
  // LOAD COMPLETE TREE
  // ============================================================

  /// Loads the complete project tree recursively.
  ///
  /// Both files and folders are returned.
  static Future<List<ProjectFile>> loadTree(
    String projectPath,
  ) async {
    final directory = Directory(projectPath);

    if (!await directory.exists()) {
      throw Exception(
        'Project directory does not exist:\n$projectPath',
      );
    }

    final result = <ProjectFile>[];

    await _walkDirectory(
      directory,
      result,
    );

    return result;
  }

  static Future<void> _walkDirectory(
    Directory directory,
    List<ProjectFile> result,
  ) async {
    List<FileSystemEntity> entries;

    try {
      entries = await directory.list(
        followLinks: false,
      ).toList();
    } catch (_) {
      return;
    }

    entries.sort(
      (a, b) {
        final aDirectory = a is Directory;
        final bDirectory = b is Directory;

        if (aDirectory != bDirectory) {
          return aDirectory ? -1 : 1;
        }

        return p.basename(a.path)
            .toLowerCase()
            .compareTo(
              p.basename(b.path).toLowerCase(),
            );
      },
    );

    for (final entry in entries) {
      final name = p.basename(entry.path);

      if (_shouldIgnore(name)) {
        continue;
      }

      // ----------------------------------------------------------
      // DIRECTORY
      // ----------------------------------------------------------

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

        continue;
      }

      // ----------------------------------------------------------
      // FILE
      // ----------------------------------------------------------

      if (entry is File) {
        try {
          final content = await entry.readAsString();

          result.add(
            ProjectFile(
              name: name,
              path: entry.path,
              content: content,
              isDirectory: false,
            ),
          );
        } catch (_) {
          // Ignore binary/unreadable files.
        }
      }
    }
  }

  // ============================================================
  // IGNORED FOLDERS
  // ============================================================

  static bool _shouldIgnore(
    String name,
  ) {
    return name == '.git' ||
        name == '.dart_tool' ||
        name == 'build' ||
        name == '__pycache__' ||
        name == '.idea' ||
        name == '.gradle' ||
        name == '.DS_Store';
  }

  // ============================================================
  // SAVE FILE
  // ============================================================

  /// Saves directly to the file's actual filesystem path.
  static Future<void> saveFile(
    ProjectFile file,
  ) async {
    if (file.isDirectory) {
      return;
    }

    if (file.path.trim().isEmpty) {
      throw Exception(
        'Cannot save file: file path is empty.',
      );
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
      flush: true,
    );
  }

  // ============================================================
  // SAVE FILE AT PATH
  // ============================================================

  static Future<void> saveFileAtPath(
    String filePath,
    String content,
  ) async {
    if (filePath.trim().isEmpty) {
      throw Exception(
        'File path cannot be empty.',
      );
    }

    final file = File(filePath);

    final parent = file.parent;

    if (!await parent.exists()) {
      await parent.create(
        recursive: true,
      );
    }

    await file.writeAsString(
      content,
      flush: true,
    );
  }

  // ============================================================
  // CREATE FILE
  // ============================================================

  static Future<String> createFileAtPath(
    String directoryPath,
    String fileName, {
    String content = '',
  }) async {
    final safeName = p.basename(
      fileName.trim(),
    );

    if (safeName.isEmpty ||
        safeName == '.' ||
        safeName == '..') {
      throw Exception(
        'Please enter a valid file name.',
      );
    }

    final directory = Directory(
      directoryPath,
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    final filePath = p.join(
      directoryPath,
      safeName,
    );

    final file = File(filePath);

    if (await file.exists()) {
      throw Exception(
        'A file named "$safeName" already exists.',
      );
    }

    await file.writeAsString(
      content,
      flush: true,
    );

    return filePath;
  }

  // ============================================================
  // CREATE FOLDER
  // ============================================================

  static Future<String> createFolderAtPath(
    String directoryPath,
    String folderName,
  ) async {
    final safeName = p.basename(
      folderName.trim(),
    );

    if (safeName.isEmpty ||
        safeName == '.' ||
        safeName == '..') {
      throw Exception(
        'Please enter a valid folder name.',
      );
    }

    final parent = Directory(
      directoryPath,
    );

    if (!await parent.exists()) {
      await parent.create(
        recursive: true,
      );
    }

    final folderPath = p.join(
      directoryPath,
      safeName,
    );

    final directory = Directory(
      folderPath,
    );

    if (await directory.exists()) {
      throw Exception(
        'A folder named "$safeName" already exists.',
      );
    }

    await directory.create(
      recursive: true,
    );

    return folderPath;
  }

  // ============================================================
  // DELETE FILE
  // ============================================================

  static Future<void> deleteFileAtPath(
    String filePath,
  ) async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  // ============================================================
  // DELETE FOLDER
  // ============================================================

  static Future<void> deleteFolderAtPath(
    String folderPath,
  ) async {
    final directory = Directory(
      folderPath,
    );

    if (await directory.exists()) {
      await directory.delete(
        recursive: true,
      );
    }
  }

  // ============================================================
  // DELETE ANY PATH
  // ============================================================

  static Future<void> deletePath(
    String path,
  ) async {
    final type = await FileSystemEntity.type(
      path,
      followLinks: false,
    );

    switch (type) {
      case FileSystemEntityType.file:
        await deleteFileAtPath(path);
        break;

      case FileSystemEntityType.directory:
        await deleteFolderAtPath(path);
        break;

      case FileSystemEntityType.link:
        final link = Link(path);

        if (await link.exists()) {
          await link.delete();
        }
        break;

      case FileSystemEntityType.notFound:
        break;
    }
  }

  // ============================================================
  // RENAME FILE OR FOLDER
  // ============================================================

  static Future<String> renamePath(
    String oldPath,
    String newName,
  ) async {
    final safeName = p.basename(
      newName.trim(),
    );

    if (safeName.isEmpty ||
        safeName == '.' ||
        safeName == '..') {
      throw Exception(
        'Please enter a valid name.',
      );
    }

    final type = await FileSystemEntity.type(
      oldPath,
      followLinks: false,
    );

    if (type == FileSystemEntityType.notFound) {
      throw Exception(
        'The file or folder no longer exists.',
      );
    }

    final parent = p.dirname(
      oldPath,
    );

    final newPath = p.join(
      parent,
      safeName,
    );

    if (await FileSystemEntity.type(
          newPath,
          followLinks: false,
        ) !=
        FileSystemEntityType.notFound) {
      throw Exception(
        'A file or folder named "$safeName" already exists.',
      );
    }

    if (type == FileSystemEntityType.directory) {
      await Directory(oldPath).rename(
        newPath,
      );
    } else if (type == FileSystemEntityType.file) {
      await File(oldPath).rename(
        newPath,
      );
    } else {
      throw Exception(
        'Unsupported filesystem item.',
      );
    }

    return newPath;
  }

  // ============================================================
  // CHECK PATH EXISTS
  // ============================================================

  static Future<bool> pathExists(
    String path,
  ) async {
    final type = await FileSystemEntity.type(
      path,
      followLinks: false,
    );

    return type != FileSystemEntityType.notFound;
  }

  // ============================================================
  // PROJECT ROOT NAME
  // ============================================================

  static String getProjectName(
    String projectPath,
  ) {
    return projectNameFromPath(
      projectPath,
    );
  }

  // ============================================================
  // CREATE NEW INTERNAL PROJECT
  // ============================================================

  /// Creates a real project directory inside
  /// YammieCode's application documents folder.
  ///
  /// The resulting files are still actual files on disk.
  static Future<String> createProject(
    String projectName,
  ) async {
    final directory = await _projectDirectory(
      projectName,
    );

    // ----------------------------------------------------------
    // main.py
    // ----------------------------------------------------------

    final mainFile = File(
      p.join(
        directory.path,
        'main.py',
      ),
    );

    if (!await mainFile.exists()) {
      await mainFile.writeAsString(
        '''def main():
    print("Hello from YammieCode!")


if __name__ == "__main__":
    main()
''',
        flush: true,
      );
    }

    // ----------------------------------------------------------
    // requirements.txt
    // ----------------------------------------------------------

    final requirements = File(
      p.join(
        directory.path,
        'requirements.txt',
      ),
    );

    if (!await requirements.exists()) {
      await requirements.writeAsString(
        '',
        flush: true,
      );
    }

    return directory.path;
  }

  // ============================================================
  // INTERNAL PROJECT LIST
  // ============================================================

  static Future<List<String>> getProjects() async {
    final directory =
        await _projectsDirectory();

    final entries = await directory.list(
      followLinks: false,
    ).toList();

    final projects = entries
        .whereType<Directory>()
        .map(
          (directory) => p.basename(
            directory.path,
          ),
        )
        .toList();

    projects.sort(
      (a, b) => a.toLowerCase().compareTo(
            b.toLowerCase(),
          ),
    );

    return projects;
  }

  // ============================================================
  // LOAD INTERNAL PROJECT
  // ============================================================

  static Future<List<ProjectFile>> loadFiles(
    String projectName,
  ) async {
    final directory =
        await _projectDirectory(
      projectName,
    );

    return loadTree(
      directory.path,
    );
  }

  // ============================================================
  // CREATE FILE IN INTERNAL PROJECT
  // ============================================================

  static Future<String> createFile(
    String projectName,
    String fileName,
  ) async {
    final directory =
        await _projectDirectory(
      projectName,
    );

    return createFileAtPath(
      directory.path,
      fileName,
    );
  }

  // ============================================================
  // CREATE FOLDER IN INTERNAL PROJECT
  // ============================================================

  static Future<String> createFolder(
    String projectName,
    String folderName,
  ) async {
    final directory =
        await _projectDirectory(
      projectName,
    );

    return createFolderAtPath(
      directory.path,
      folderName,
    );
  }

  // ============================================================
  // DELETE FILE FROM INTERNAL PROJECT
  // ============================================================

  static Future<void> deleteFile(
    String projectName,
    String fileName,
  ) async {
    final directory =
        await _projectDirectory(
      projectName,
    );

    final filePath = p.join(
      directory.path,
      p.basename(fileName),
    );

    await deleteFileAtPath(
      filePath,
    );
  }

  // ============================================================
  // DELETE INTERNAL PROJECT
  // ============================================================

  static Future<void> deleteProject(
    String projectName,
  ) async {
    final directory =
        await _projectDirectory(
      projectName,
    );

    if (await directory.exists()) {
      await directory.delete(
        recursive: true,
      );
    }
  }
}