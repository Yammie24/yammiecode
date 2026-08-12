import 'package:flutter/material.dart';

class ConsolePanel extends StatelessWidget {
  final String output;

  const ConsolePanel({
    super.key,
    required this.output,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080B0F),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONSOLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFF8B949E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
