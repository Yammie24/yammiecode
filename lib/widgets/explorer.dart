import 'package:flutter/material.dart';

class Explorer extends StatelessWidget {
  final List<String> files;
  final int selectedIndex;
  final ValueChanged<int> onFileSelected;
  final VoidCallback onNewFile;

  const Explorer({
    super.key,
    required this.files,
    required this.selectedIndex,
    required this.onFileSelected,
    required this.onNewFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF11161D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Text(
              'EXPLORER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.grey,
              ),
            ),
          ),

          const ListTile(
            dense: true,
            leading: Icon(
              Icons.folder,
              color: Colors.amber,
            ),
            title: Text(
              'my_project',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(
            height: 1,
            color: Color(0xFF30363D),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  selected: index == selectedIndex,
                  selectedTileColor:
                      const Color(0xFF21262D),
                  leading: Icon(
                    Icons.code,
                    size: 18,
                    color: index == selectedIndex
                        ? const Color(0xFF4B8BBE)
                        : Colors.grey,
                  ),
                  title: Text(files[index]),
                  onTap: () => onFileSelected(index),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: onNewFile,
              icon: const Icon(Icons.add),
              label: const Text('New File'),
              style: OutlinedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
