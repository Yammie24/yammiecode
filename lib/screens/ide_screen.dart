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

  String consoleOutput =
      'YammieCode Console\n'
      '────────────────────────────\n'
      'Project: waiting for files...\n';

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() {
      loading = true;
    });

    try {
      final loaded = await ProjectService.loadFiles(
        widget.projectName,
      );

      if (!mounted) return;

      setState(() {
        files = loaded;
        selectedFile = files.isEmpty
            ? 0
            : selectedFile.clamp(0, files.length - 1);
        loading = false;

        consoleOutput =
            'YammieCode Console\n'
            '────────────────────────────\n'
            'Project: ${widget.projectName}\n'
            '${files.length} file(s) loaded.\n';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;

        consoleOutput =
            'ERROR\n'
            '────────────────────────────\n'
            '$error';
      });
    }
  }

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

        consoleOutput =
            'YammieCode Console\n'
            '────────────────────────────\n'
            '✓ Saved ${files[selectedFile].name}\n';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File saved'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        saving = false;

        consoleOutput =
            'SAVE ERROR\n'
            '────────────────────────────\n'
            '$error';
      });
    }
  }

  Future<void> _newFile() async {
    final controller = TextEditingController(
      text: 'new_file.py',
    );

    final fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'File name',
              hintText: 'example.py',
              prefixIcon: Icon(Icons.insert_drive_file),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (fileName == null || fileName.isEmpty) {
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

  Future<void> _deleteFile() async {
    if (files.isEmpty) return;

    final file = files[selectedFile];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete file?'),
          content: Text(
            'Delete "${file.name}" permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
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
      });
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Unable to delete file',
        error.toString(),
      );
    }
  }

  void _run() {
    if (files.isEmpty) return;

    setState(() {
      consoleOutput =
          'YammieCode Console\n'
          '────────────────────────────\n'
          '▶ Running ${files[selectedFile].name}\n\n'
          'Python execution engine is coming next.\n';
    });
  }

  void _search() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Project'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search files...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                final query = controller.text.trim();

                Navigator.pop(context);

                if (query.isNotEmpty) {
                  setState(() {
                    consoleOutput =
                        'Search\n'
                        '────────────────────────────\n'
                        'Searching for: $query';
                  });
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showError(
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SelectableText(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _languageName() {
    if (files.isEmpty) {
      return 'No file';
    }

    final name = files[selectedFile].name.toLowerCase();

    if (name.endsWith('.py')) {
      return 'Python';
    }

    if (name.endsWith('.dart')) {
      return 'Dart';
    }

    if (name.endsWith('.json')) {
      return 'JSON';
    }

    if (name.endsWith('.js')) {
      return 'JavaScript';
    }

    if (name.endsWith('.html')) {
      return 'HTML';
    }

    if (name.endsWith('.css')) {
      return 'CSS';
    }

    if (name.endsWith('.md')) {
      return 'Markdown';
    }

    if (name.endsWith('.txt')) {
      return 'Text';
    }

    return 'Plain Text';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: MediaQuery.sizeOf(context).width < 750
          ? Drawer(
              child: _buildExplorer(),
            )
          : null,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final showExplorer = width >= 750;
                final showConsole = width >= 1050;

                return Row(
                  children: [
                    if (showExplorer)
                      SizedBox(
                        width: width >= 1200 ? 250 : 220,
                        child: _buildExplorer(),
                      ),

                    Expanded(
                      child: _buildMainArea(
                        showConsole: showConsole,
                      ),
                    ),

                    if (showConsole)
                      SizedBox(
                        width: width >= 1400 ? 380 : 320,
                        child: ConsolePanel(
                          output: consoleOutput,
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF161B22),
      titleSpacing: 8,
      title: Row(
        children: [
          const Icon(
            Icons.code_rounded,
            color: Color(0xFF4B8BBE),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.projectName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
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
          tooltip: 'Save',
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'new':
                _newFile();
                break;

              case 'delete':
                _deleteFile();
                break;

              case 'refresh':
                _loadProject();
                break;
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem(
                value: 'new',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('New file'),
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete file'),
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildExplorer() {
    return Explorer(
      files: files.map((file) => file.name).toList(),
      selectedIndex: selectedFile,
      onFileSelected: (index) {
        setState(() {
          selectedFile = index;
        });

        if (MediaQuery.sizeOf(context).width < 750) {
          Navigator.of(context).pop();
        }
      },
      onNewFile: _newFile,
    );
  }

  Widget _buildMainArea({
    required bool showConsole,
  }) {
    if (files.isEmpty) {
      return _buildEmptyEditor();
    }

    return Column(
      children: [
        Expanded(
          child: EditorPanel(
            key: ValueKey(
              files[selectedFile].name,
            ),
            fileName: files[selectedFile].name,
            initialCode: files[selectedFile].content,
          ),
        ),

        _buildBottomToolbar(),

        if (!showConsole)
          SizedBox(
            height: 150,
            child: ConsolePanel(
              output: consoleOutput,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
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
              Icons.play_arrow,
              size: 18,
            ),
            label: const Text('Run'),
          ),

          const SizedBox(width: 8),

          IconButton(
            tooltip: 'Save',
            onPressed: saving ? null : _save,
            icon: const Icon(
              Icons.save_outlined,
            ),
          ),

          IconButton(
            tooltip: 'Search',
            onPressed: _search,
            icon: const Icon(
              Icons.search,
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _languageName(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEditor() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.description_outlined,
          size: 64,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        const Text(
          'No files in this project',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _newFile,
          icon: const Icon(Icons.add),
          label: const Text('Create File'),
        ),
      ],
    );
  }
}
