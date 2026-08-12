import 'package:flutter/material.dart';

import '../models/project_file.dart';
import '../services/project_service.dart';
import '../widgets/console_panel.dart';
import '../widgets/editor_panel.dart';
import '../widgets/explorer.dart';

class IDEScreen extends StatefulWidget {
  const IDEScreen({super.key});

  @override
  State<IDEScreen> createState() => _IDEScreenState();
}

class _IDEScreenState extends State<IDEScreen> {
  late List<ProjectFile> files;

  int selectedFile = 0;

  String consoleOutput =
      'YammieCode ready.\n'
      r'$ Waiting for program...';

  @override
  void initState() {
    super.initState();
    files = ProjectService.defaultFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Row(
          children: [
            Icon(
              Icons.code_rounded,
              color: Color(0xFF4B8BBE),
            ),
            SizedBox(width: 10),
            Text(
              'YammieCode',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      drawer: MediaQuery.sizeOf(context).width < 700
          ? Drawer(
              child: Explorer(
                files: files.map((e) => e.name).toList(),
                selectedIndex: selectedFile,
                onFileSelected: (index) {
                  setState(() {
                    selectedFile = index;
                  });
                  Navigator.pop(context);
                },
                onNewFile: _newFile,
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final showExplorer = width >= 700;
          final showConsole = width >= 1000;

          return Row(
            children: [
              if (showExplorer)
                SizedBox(
                  width: width >= 1100 ? 240 : 210,
                  child: Explorer(
                    files:
                        files.map((e) => e.name).toList(),
                    selectedIndex: selectedFile,
                    onFileSelected: (index) {
                      setState(() {
                        selectedFile = index;
                      });
                    },
                    onNewFile: _newFile,
                  ),
                ),

              Expanded(
                child: Column(
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
                      ),
                    ),

                    Container(
                      height: 54,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      color: const Color(0xFF161B22),
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
                            onPressed: _save,
                            tooltip: 'Save',
                            icon: const Icon(
                              Icons.save_outlined,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            tooltip: 'Search',
                            icon: const Icon(
                              Icons.search,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _languageName(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (showConsole)
                SizedBox(
                  width: 320,
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

  String _languageName() {
    final name = files[selectedFile].name;

    if (name.endsWith('.py')) {
      return 'Python';
    }

    if (name.endsWith('.txt')) {
      return 'Text';
    }

    return 'Unknown';
  }

  void _run() {
    setState(() {
      consoleOutput =
          'YammieCode\n'
          '────────────────────\n'
          '▶ Running ${files[selectedFile].name}...\n\n'
          'Python execution engine coming next.';
    });
  }

  void _save() {
    setState(() {
      consoleOutput =
          '✓ ${files[selectedFile].name} saved.';
    });
  }

  void _newFile() {
    setState(() {
      files.add(
        ProjectFile(
          name: 'new_file.py',
          content:
              '# New Python file\n\nprint("Hello!")\n',
        ),
      );

      selectedFile = files.length - 1;
    });
  }
}
