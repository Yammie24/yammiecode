import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github-dark.dart';
import 'package:highlight/languages/python.dart';

class EditorPanel extends StatefulWidget {
  final String fileName;
  final String initialCode;

  const EditorPanel({
    super.key,
    required this.fileName,
    required this.initialCode,
  });

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  late CodeController controller;

  @override
  void initState() {
    super.initState();

    controller = CodeController(
      text: widget.initialCode,
      language: python,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 44,
          color: const Color(0xFF161B22),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.code,
                size: 17,
                color: Color(0xFF4B8BBE),
              ),
              const SizedBox(width: 8),
              Text(widget.fileName),
              const Spacer(),
              const Icon(
                Icons.circle,
                size: 8,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              const Text(
                'Modified',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: CodeTheme(
            data: CodeThemeData(
              styles: githubDarkTheme,
            ),
            child: SingleChildScrollView(
              child: CodeField(
                controller: controller,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
