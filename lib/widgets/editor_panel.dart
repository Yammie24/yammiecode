import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/python.dart';

class EditorPanel extends StatefulWidget {
  final String fileName;
  final String initialCode;
  final ValueChanged<String>? onChanged;

  const EditorPanel({
    super.key,
    required this.fileName,
    required this.initialCode,
    this.onChanged,
  });

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  late CodeController controller;

  bool modified = false;

  @override
  void initState() {
    super.initState();

    controller = CodeController(
      text: widget.initialCode,
      language: python,
    );

    controller.addListener(_handleChanged);
  }

  void _handleChanged() {
    if (!modified) {
      setState(() {
        modified = true;
      });
    }

    widget.onChanged?.call(controller.text);
  }

  @override
  void dispose() {
    controller.removeListener(_handleChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          _buildEditorHeader(),
          Expanded(
            child: _buildEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorHeader() {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF30363D),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),

          // Python icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.code,
              size: 17,
              color: Color(0xFF4B8BBE),
            ),
          ),

          const SizedBox(width: 9),

          Flexible(
            child: Text(
              widget.fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (modified) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Unsaved',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],

          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return CodeTheme(
      data: CodeThemeData(
        styles: monokaiSublimeTheme,
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: CodeField(
          controller: controller,
          expands: true,
          padding: const EdgeInsets.only(
            left: 8,
            right: 16,
            top: 14,
            bottom: 30,
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.55,
          ),
          gutterStyle: gutterStyle(
            width: 42,
            margin: 8,
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFF6E7681),
            ),
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0D1117),
          ),
        ),
      ),
    );
  }
}