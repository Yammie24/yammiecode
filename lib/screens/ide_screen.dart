import 'package:flutter/material.dart';

import '../models/project_file.dart';
import '../services/project_service.dart';
import '../widgets/console_panel.dart';
import '../widgets/editor_panel.dart';
import '../widgets/explorer.dart';

class IDEScreen extends StatefulWidget {
  final String projectName;

  const IDEScreen({
    super.key,
    required this.projectName,
  });

  @override
  State<IDEScreen> createState() => _IDEScreenState();
}

class _IDEScreenState extends State<IDEScreen> {
  List<ProjectFile> files = [];

  int selectedFile = 0;

  bool loading = true;
  bool saving = false;
  bool isDirty = false;

  /// Console is hidden by default to maximize editor space.
  bool consoleVisible = false;

  /// Used for mobile/tablet bottom console.
  bool consoleExpanded = false;

  String consoleOutput =
      'YammieCode Terminal\n'
      '────────────────────────────────────\n'
      'Ready.\n';

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  // ============================================================
  // PROJECT
  // ============================================================

  Future<void> _loadProject() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final loaded = await ProjectService.loadFiles(
        widget.projectName,
      );

      if (!mounted) return;

      setState(() {
        files = loaded;

        if (files.isEmpty) {
          selectedFile = 0;
        } else {
          selectedFile =
              selectedFile.clamp(0, files.length - 1);
        }

        loading = false;
        isDirty = false;

        consoleOutput =
            'YammieCode Terminal\n'
            '────────────────────────────────────\n'
            'Project: ${widget.projectName}\n'
            '${files.length} file(s) loaded.\n';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;

        consoleOutput =
            'ERROR\n'
            '────────────────────────────────────\n'
            '$error';
      });
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (files.isEmpty || saving) return;

    setState(() {
      saving = true;
    });

    try {
      await ProjectService.saveFile(
        widget.projectName,
        files[selectedFile],
      );

      if (!mounted) return;

      setState(() {
        saving = false;
        isDirty = false;

        consoleOutput =
            'YammieCode Terminal\n'
            '────────────────────────────────────\n'
            '✓ Saved ${files[selectedFile].name}\n';
      });

      _showMessage(
        'Saved ${files[selectedFile].name}',
        Icons.check_circle_outline,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        saving = false;

        consoleOutput =
            'SAVE ERROR\n'
            '────────────────────────────────────\n'
            '$error';
      });

      _showError(
        'Unable to save file',
        error.toString(),
      );
    }
  }

  // ============================================================
  // NEW FILE
  // ============================================================

  Future<void> _newFile() async {
    final controller = TextEditingController(
      text: 'main.py',
    );

    final fileName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.note_add_outlined),
              SizedBox(width: 10),
              Text('New File'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'File name',
              hintText: 'main.py',
              prefixIcon: Icon(
                Icons.insert_drive_file_outlined,
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(
                  dialogContext,
                  value.trim(),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(
                    dialogContext,
                    name,
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (fileName == null || fileName.isEmpty) {
      return;
    }

    final exists = files.any(
      (file) => file.name == fileName,
    );

    if (exists) {
      _showError(
        'File already exists',
        '"$fileName" already exists in this project.',
      );
      return;
    }

    try {
      await ProjectService.createFile(
        widget.projectName,
        fileName,
      );

      await _loadProject();

      if (!mounted) return;

      final index = files.indexWhere(
        (file) => file.name == fileName,
      );

      if (index >= 0) {
        setState(() {
          selectedFile = index;
          isDirty = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Unable to create file',
        error.toString(),
      );
    }
  }

  // ============================================================
  // DELETE FILE
  // ============================================================

  Future<void> _deleteFile() async {
    if (files.isEmpty) return;

    final file = files[selectedFile];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text('Delete file?'),
            ],
          ),
          content: Text(
            'Delete "${file.name}" permanently?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ProjectService.deleteFile(
        widget.projectName,
        file.name,
      );

      await _loadProject();

      if (!mounted) return;

      setState(() {
        if (files.isEmpty) {
          selectedFile = 0;
        } else {
          selectedFile =
              selectedFile.clamp(0, files.length - 1);
        }

        isDirty = false;
      });

      _showMessage(
        'File deleted',
        Icons.delete_outline,
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Unable to delete file',
        error.toString(),
      );
    }
  }

  // ============================================================
  // EDITOR
  // ============================================================

  void _onEditorChanged(String value) {
    if (files.isEmpty) return;

    setState(() {
      files[selectedFile].content = value;
      isDirty = true;
    });
  }

  // ============================================================
  // RUN
  // ============================================================

  void _run() {
    if (files.isEmpty) return;

    final file = files[selectedFile];

    setState(() {
      consoleVisible = true;
      consoleExpanded = true;

      consoleOutput =
          'YammieCode Terminal\n'
          '────────────────────────────────────\n'
          '▶ Running ${file.name}\n\n'
          'Python execution engine coming next.\n';
    });
  }

  // ============================================================
  // CONSOLE
  // ============================================================

  void _toggleConsole() {
    setState(() {
      consoleVisible = !consoleVisible;

      if (!consoleVisible) {
        consoleExpanded = false;
      }
    });
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _search() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.search),
              SizedBox(width: 10),
              Text('Search Project'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search files...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              Navigator.pop(dialogContext);

              if (value.trim().isNotEmpty) {
                _performSearch(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                final query = controller.text.trim();

                Navigator.pop(dialogContext);

                if (query.isNotEmpty) {
                  _performSearch(query);
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(String query) {
    final lowerQuery = query.toLowerCase();

    final matches = files.where((file) {
      return file.name.toLowerCase().contains(lowerQuery) ||
          file.content.toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() {
      consoleVisible = true;
      consoleExpanded = true;

      consoleOutput =
          'Search Results\n'
          '────────────────────────────────────\n'
          'Query: $query\n'
          '${matches.length} file(s) found.\n\n'
          '${matches.map((file) => '• ${file.name}').join('\n')}';
    });
  }

  // ============================================================
  // FILE SELECTION
  // ============================================================

  void _selectFile(int index) {
    if (index < 0 || index >= files.length) return;

    setState(() {
      selectedFile = index;
    });

    if (MediaQuery.sizeOf(context).width < 750) {
      Navigator.of(context).maybePop();
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showError(
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title),
              ),
            ],
          ),
          content: SelectableText(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
    String message,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  String _languageName() {
    if (files.isEmpty) return 'No file';

    final name =
        files[selectedFile].name.toLowerCase();

    if (name.endsWith('.py')) return 'Python';
    if (name.endsWith('.dart')) return 'Dart';
    if (name.endsWith('.json')) return 'JSON';
    if (name.endsWith('.js')) return 'JavaScript';
    if (name.endsWith('.ts')) return 'TypeScript';
    if (name.endsWith('.html')) return 'HTML';
    if (name.endsWith('.css')) return 'CSS';
    if (name.endsWith('.md')) return 'Markdown';
    if (name.endsWith('.yaml') ||
        name.endsWith('.yml')) {
      return 'YAML';
    }
    if (name.endsWith('.txt')) return 'Text';

    return 'Plain Text';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final isMobile = width < 750;

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !isDirty) return;

        final leave = await _confirmLeave();

        if (leave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: _buildAppBar(),
        drawer: isMobile
            ? Drawer(
                backgroundColor:
                    const Color(0xFF0D1117),
                child: SafeArea(
                  child: _buildExplorer(),
                ),
              )
            : null,
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth =
                      constraints.maxWidth;

                  final showExplorer =
                      availableWidth >= 750;

                  final showSideConsole =
                      availableWidth >= 1250 &&
                      consoleVisible;

                  return Row(
                    children: [
                      if (showExplorer)
                        _buildExplorerContainer(
                          availableWidth,
                        ),

                      Expanded(
                        child: _buildWorkspace(
                          width: availableWidth,
                          showSideConsole:
                              showSideConsole,
                        ),
                      ),

                      if (showSideConsole)
                        _buildConsoleContainer(
                          availableWidth,
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF161B22),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 8,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.code_rounded,
              size: 19,
              color: Color(0xFF4B8BBE),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isDirty
                      ? 'Unsaved changes'
                      : '${files.length} files',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDirty
                        ? Colors.orange
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: _search,
          icon: const Icon(Icons.search),
        ),

        IconButton(
          tooltip: 'New file',
          onPressed: _newFile,
          icon: const Icon(Icons.add),
        ),

        IconButton(
          tooltip: consoleVisible
              ? 'Hide terminal'
              : 'Show terminal',
          onPressed: _toggleConsole,
          icon: Icon(
            consoleVisible
                ? Icons.keyboard_arrow_down
                : Icons.terminal,
          ),
        ),

        IconButton(
          tooltip: 'Save',
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  isDirty
                      ? Icons.save
                      : Icons.save_outlined,
                ),
        ),

        PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadProject();
                break;

              case 'delete':
                _deleteFile();
                break;

              case 'terminal':
                _toggleConsole();
                break;
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading:
                      Icon(Icons.refresh),
                  title:
                      Text('Refresh project'),
                ),
              ),
              PopupMenuItem(
                value: 'terminal',
                child: ListTile(
                  leading:
                      Icon(Icons.terminal),
                  title:
                      Text('Toggle terminal'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                  ),
                  title:
                      Text('Delete file'),
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  // ============================================================
  // EXPLORER
  // ============================================================

  Widget _buildExplorerContainer(double width) {
    return Container(
      width: width >= 1400 ? 270 : 235,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(
          right: BorderSide(
            color: Color(0xFF30363D),
          ),
        ),
      ),
      child: _buildExplorer(),
    );
  }

  Widget _buildExplorer() {
    return Explorer(
      projectName: widget.projectName,
      files: files,
      selectedIndex: selectedFile,
      onFileSelected: _selectFile,
      onNewFile: _newFile,
    );
  }

  // ============================================================
  // WORKSPACE
  // ============================================================

  Widget _buildWorkspace({
    required double width,
    required bool showSideConsole,
  }) {
    if (files.isEmpty) {
      return _buildEmptyEditor();
    }

    final isMobile = width < 750;

    return Column(
      children: [
        Expanded(
          child: EditorPanel(
            key: ValueKey(
              files[selectedFile].name,
            ),
            fileName:
                files[selectedFile].name,
            initialCode:
                files[selectedFile].content,
            onChanged:
                _onEditorChanged,
          ),
        ),

        _buildEditorToolbar(),

        if (!showSideConsole &&
            consoleVisible &&
            consoleExpanded)
          SizedBox(
            height: isMobile ? 150 : 210,
            child: _buildBottomConsole(),
          ),

        if (!showSideConsole &&
            consoleVisible &&
            !consoleExpanded)
          _buildTerminalCollapsedBar(),

        _buildStatusBar(),
      ],
    );
  }

  // ============================================================
  // EDITOR TOOLBAR
  // ============================================================

  Widget _buildEditorToolbar() {
    return Container(
      height: 50,
      padding:
          const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(
          top: BorderSide(
            color: Color(0xFF30363D),
          ),
        ),
      ),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: _run,
            icon: const Icon(
              Icons.play_arrow_rounded,
              size: 18,
            ),
            label: const Text('Run'),
          ),

          const SizedBox(width: 6),

          IconButton(
            tooltip: 'Save',
            onPressed:
                saving ? null : _save,
            icon: Icon(
              isDirty
                  ? Icons.save
                  : Icons.save_outlined,
            ),
          ),

          IconButton(
            tooltip: 'Search',
            onPressed: _search,
            icon:
                const Icon(Icons.search),
          ),

          const Spacer(),

          Text(
            _languageName(),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 10),

          IconButton(
            tooltip: consoleVisible
                ? 'Hide terminal'
                : 'Show terminal',
            onPressed: _toggleConsole,
            icon: Icon(
              consoleVisible
                  ? Icons.keyboard_arrow_down
                  : Icons.terminal_outlined,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TERMINAL
  // ============================================================

  Widget _buildBottomConsole() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(
          top: BorderSide(
            color: Color(0xFF30363D),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildTerminalHeader(),
          Expanded(
            child: ConsolePanel(
              output: consoleOutput,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      height: 34,
      color: const Color(0xFF161B22),
      padding:
          const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            Icons.terminal,
            size: 15,
            color: Colors.grey,
          ),
          const SizedBox(width: 7),
          const Text(
            'TERMINAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: .7,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Collapse terminal',
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            onPressed: () {
              setState(() {
                consoleExpanded = false;
              });
            },
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: 'Close terminal',
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            onPressed: () {
              setState(() {
                consoleVisible = false;
                consoleExpanded = false;
              });
            },
            icon: const Icon(
              Icons.close,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalCollapsedBar() {
    return InkWell(
      onTap: () {
        setState(() {
          consoleExpanded = true;
        });
      },
      child: Container(
        height: 30,
        padding:
            const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          border: Border(
            top: BorderSide(
              color: Color(0xFF30363D),
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.terminal,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 7),
            const Text(
              'TERMINAL',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: .7,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_up,
              size: 17,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleContainer(double width) {
    return Container(
      width: width >= 1500 ? 400 : 350,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Color(0xFF30363D),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildTerminalHeader(),
          Expanded(
            child: ConsolePanel(
              output: consoleOutput,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BAR
  // ============================================================

  Widget _buildStatusBar() {
    return Container(
      height: 25,
      padding:
          const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFF21262D),
      child: Row(
        children: [
          const Icon(
            Icons.source,
            size: 13,
            color: Colors.grey,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              widget.projectName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ),

          if (isDirty) ...[
            const SizedBox(width: 12),
            const Icon(
              Icons.circle,
              size: 6,
              color: Colors.orange,
            ),
            const SizedBox(width: 5),
            const Text(
              'Modified',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange,
              ),
            ),
          ],

          const Spacer(),

          Text(
            _languageName(),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 12),

          const Text(
            'UTF-8',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 12),

          const Text(
            'LF',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyEditor() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 42,
                color: Color(0xFF4B8BBE),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No files in this project',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Create a file to start coding.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _newFile,
              icon: const Icon(Icons.add),
              label:
                  const Text('Create File'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXIT
  // ============================================================

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Unsaved changes'),
          content: const Text(
            'You have unsaved changes. '
            'Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}