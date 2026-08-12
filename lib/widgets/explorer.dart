import 'package:flutter/material.dart';

import '../models/project_file.dart';

class Explorer extends StatefulWidget {
  final String projectName;
  final List<ProjectFile> files;
  final int selectedIndex;

  final ValueChanged<int> onFileSelected;

  final VoidCallback onNewFile;
  final VoidCallback? onNewFolder;
  final VoidCallback? onRefresh;

  const Explorer({
    super.key,
    required this.projectName,
    required this.files,
    required this.selectedIndex,
    required this.onFileSelected,
    required this.onNewFile,
    this.onNewFolder,
    this.onRefresh,
  });

  @override
  State<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends State<Explorer> {
  final Set<String> _expandedFolders = <String>{};

  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF11161D);
  static const Color surface = Color(0xFF161B22);
  static const Color selected = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);
  static const Color text = Color(0xFFC9D1D9);
  static const Color muted = Color(0xFF8B949E);
  static const Color accent = Color(0xFF4B8BBE);

  // ============================================================
  // FILE ICON
  // ============================================================

  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.py')) {
      return Icons.code_rounded;
    }

    if (lower.endsWith('.dart')) {
      return Icons.code_rounded;
    }

    if (lower.endsWith('.json')) {
      return Icons.data_object_rounded;
    }

    if (lower.endsWith('.yaml') ||
        lower.endsWith('.yml')) {
      return Icons.settings_outlined;
    }

    if (lower.endsWith('.md')) {
      return Icons.article_outlined;
    }

    if (lower.endsWith('.txt')) {
      return Icons.description_outlined;
    }

    if (lower.endsWith('.html')) {
      return Icons.language_rounded;
    }

    if (lower.endsWith('.css')) {
      return Icons.style_rounded;
    }

    if (lower.endsWith('.js') ||
        lower.endsWith('.jsx')) {
      return Icons.javascript_rounded;
    }

    if (lower.endsWith('.ts') ||
        lower.endsWith('.tsx')) {
      return Icons.code_rounded;
    }

    if (lower.endsWith('.xml')) {
      return Icons.data_object_rounded;
    }

    if (lower.endsWith('.csv')) {
      return Icons.table_chart_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }

  // ============================================================
  // FILE COLOR
  // ============================================================

  Color _fileColor(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.py')) {
      return const Color(0xFF4B8BBE);
    }

    if (lower.endsWith('.dart')) {
      return const Color(0xFF42A5F5);
    }

    if (lower.endsWith('.json')) {
      return Colors.orange;
    }

    if (lower.endsWith('.md')) {
      return Colors.blueGrey;
    }

    if (lower.endsWith('.html')) {
      return Colors.deepOrange;
    }

    if (lower.endsWith('.css')) {
      return Colors.blue;
    }

    if (lower.endsWith('.js') ||
        lower.endsWith('.jsx')) {
      return Colors.amber;
    }

    if (lower.endsWith('.ts') ||
        lower.endsWith('.tsx')) {
      return Colors.lightBlue;
    }

    if (lower.endsWith('.yaml') ||
        lower.endsWith('.yml')) {
      return Colors.purpleAccent;
    }

    return const Color(0xFF8B949E);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildProjectHeader(),
          Expanded(
            child: widget.files.isEmpty
                ? _buildEmptyState()
                : _buildFileTree(),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        8,
        12,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'EXPLORER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: muted,
              ),
            ),
          ),

          if (widget.onRefresh != null)
            IconButton(
              tooltip: 'Refresh',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onRefresh,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: muted,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROJECT HEADER
  // ============================================================

  Widget _buildProjectHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: muted,
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.folder_rounded,
            size: 18,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.projectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILE TREE
  // ============================================================

  Widget _buildFileTree() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 4,
        bottom: 8,
      ),
      itemCount: widget.files.length,
      itemBuilder: (context, index) {
        final file = widget.files[index];

        if (file.isDirectory) {
          return _buildFolder(
            file,
            index,
          );
        }

        final depth = _calculateDepth(file);

        if (!_isFileVisible(file)) {
          return const SizedBox.shrink();
        }

        return _buildFile(
          file,
          index,
          depth,
        );
      },
    );
  }

  // ============================================================
  // DIRECTORY DEPTH
  // ============================================================

  int _calculateDepth(ProjectFile file) {
    final projectPath =
        widget.files.isNotEmpty
            ? _findProjectRoot(file.path)
            : '';

    if (projectPath.isEmpty) {
      return 0;
    }

    final normalizedFile =
        file.path.replaceAll('\\', '/');

    final normalizedRoot =
        projectPath.replaceAll('\\', '/');

    if (!normalizedFile.startsWith(normalizedRoot)) {
      return 0;
    }

    final relative = normalizedFile
        .substring(normalizedRoot.length)
        .replaceFirst('/', '');

    if (relative.isEmpty) {
      return 0;
    }

    return '/'.allMatches(relative).length;
  }

  String _findProjectRoot(String path) {
    if (widget.files.isEmpty) {
      return '';
    }

    final normalized = path.replaceAll('\\', '/');

    // Find the shortest common path among the files.
    final first =
        widget.files.first.path.replaceAll('\\', '/');

    final firstParts = first.split('/');

    final currentParts = normalized.split('/');

    final length = firstParts.length <
            currentParts.length
        ? firstParts.length
        : currentParts.length;

    int common = 0;

    for (int i = 0; i < length; i++) {
      if (firstParts[i] != currentParts[i]) {
        break;
      }

      common++;
    }

    if (common <= 0) {
      return '';
    }

    return firstParts
        .take(common)
        .join('/');
  }

  // ============================================================
  // FILE VISIBILITY
  // ============================================================

  bool _isFileVisible(ProjectFile file) {
    if (file.isDirectory) {
      return true;
    }

    final normalized =
        file.path.replaceAll('\\', '/');

    for (final folder in widget.files) {
      if (!folder.isDirectory) {
        continue;
      }

      final folderPath =
          folder.path.replaceAll('\\', '/');

      if (!normalized.startsWith(
        '$folderPath/',
      )) {
        continue;
      }

      if (!_expandedFolders.contains(folder.path)) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // FOLDER
  // ============================================================

  Widget _buildFolder(
    ProjectFile folder,
    int index,
  ) {
    final expanded =
        _expandedFolders.contains(folder.path);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (expanded) {
              _expandedFolders.remove(
                folder.path,
              );
            } else {
              _expandedFolders.add(
                folder.path,
              );
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.chevron_right_rounded,
                size: 17,
                color: muted,
              ),
              const SizedBox(width: 2),
              Icon(
                expanded
                    ? Icons.folder_open_rounded
                    : Icons.folder_rounded,
                size: 18,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILE
  // ============================================================

  Widget _buildFile(
    ProjectFile file,
    int index,
    int depth,
  ) {
    final selected =
        index == widget.selectedIndex;

    final leftPadding =
        12.0 + (depth * 16.0);

    return Material(
      color: selected
          ? selected
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onFileSelected(index);
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            leftPadding,
            7,
            10,
            7,
          ),
          child: Row(
            children: [
              Icon(
                _fileIcon(file.name),
                size: 17,
                color: selected
                    ? _fileColor(file.name)
                    : muted,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected
                        ? Colors.white
                        : text,
                    fontWeight: selected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onNewFile,
              icon: const Icon(
                Icons.note_add_outlined,
                size: 17,
              ),
              label: const Text('File'),
            ),
          ),
          if (widget.onNewFolder != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onNewFolder,
                icon: const Icon(
                  Icons.create_new_folder_outlined,
                  size: 17,
                ),
                label: const Text('Folder'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 42,
              color: Color(0xFF484F58),
            ),
            SizedBox(height: 12),
            Text(
              'No files',
              style: TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Create a file to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6E7681),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}