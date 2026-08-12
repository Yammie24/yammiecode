import 'package:flutter/material.dart';

import '../models/project_file.dart';

class Explorer extends StatelessWidget {
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

  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.py')) {
      return Icons.code_rounded;
    }

    if (lower.endsWith('.json')) {
      return Icons.data_object_rounded;
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

    if (lower.endsWith('.js')) {
      return Icons.javascript_rounded;
    }

    return Icons.insert_drive_file_outlined;
  }

  Color _fileColor(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.py')) {
      return const Color(0xFF4B8BBE);
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

    return const Color(0xFF8B949E);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF11161D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // HEADER
          // --------------------------------------------------

          Padding(
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
                      color: Color(0xFF8B949E),
                    ),
                  ),
                ),

                if (onRefresh != null)
                  IconButton(
                    tooltip: 'Refresh',
                    visualDensity:
                        VisualDensity.compact,
                    onPressed: onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),

          // --------------------------------------------------
          // PROJECT NAME
          // --------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF30363D),
                ),
                bottom: BorderSide(
                  color: Color(0xFF30363D),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_rounded,
                  size: 18,
                  color: Colors.amber,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    projectName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF8B949E),
                ),
              ],
            ),
          ),

          // --------------------------------------------------
          // FILE TREE
          // --------------------------------------------------

          Expanded(
            child: files.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 8,
                    ),
                    itemCount: files.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final file = files[index];

                      if (file.isDirectory) {
                        return _buildFolder(
                          file,
                        );
                      }

                      return _buildFile(
                        file,
                        index,
                      );
                    },
                  ),
          ),

          // --------------------------------------------------
          // ACTIONS
          // --------------------------------------------------

          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFF30363D),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNewFile,
                    icon: const Icon(
                      Icons.note_add_outlined,
                      size: 17,
                    ),
                    label: const Text(
                      'File',
                    ),
                  ),
                ),

                if (onNewFolder != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onNewFolder,
                      icon: const Icon(
                        Icons.create_new_folder_outlined,
                        size: 17,
                      ),
                      label: const Text(
                        'Folder',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFile(
    ProjectFile file,
    int index,
  ) {
    final selected =
        index == selectedIndex;

    return Material(
      color: selected
          ? const Color(0xFF21262D)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          onFileSelected(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),

              Icon(
                _fileIcon(file.name),
                size: 17,
                color: selected
                    ? _fileColor(file.name)
                    : const Color(0xFF8B949E),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected
                        ? Colors.white
                        : const Color(
                            0xFFC9D1D9,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolder(
    ProjectFile folder,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_rounded,
            size: 18,
            color: Colors.amber,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC9D1D9),
              ),
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            size: 17,
            color: Color(0xFF6E7681),
          ),
        ],
      ),
    );
  }

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
                color: Color(0xFF8B949E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}