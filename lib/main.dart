import 'package:flutter/material.dart';

void main() {
  runApp(const YammieCodeApp());
}

class YammieCodeApp extends StatelessWidget {
  const YammieCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YammieCode',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3776AB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const IDEHome(),
    );
  }
}

class IDEHome extends StatefulWidget {
  const IDEHome({super.key});

  @override
  State<IDEHome> createState() => _IDEHomeState();
}

class _IDEHomeState extends State<IDEHome> {
  int selectedFile = 0;

  final List<String> files = [
    'main.py',
    'api.py',
    'requirements.txt',
  ];

  final List<IconData> fileIcons = [
    Icons.code,
    Icons.api,
    Icons.inventory_2_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        titleSpacing: 16,
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
            tooltip: 'Search',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Explorer
                Container(
                  width: 230,
                  decoration: const BoxDecoration(
                    color: Color(0xFF11161D),
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFF30363D),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          18,
                          16,
                          12,
                        ),
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

                      ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.folder,
                          color: Colors.amber,
                        ),
                        title: const Text(
                          'my_project',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {},
                      ),

                      const Divider(
                        height: 1,
                        color: Color(0xFF30363D),
                      ),

                      for (int i = 0; i < files.length; i++)
                        ListTile(
                          dense: true,
                          selected: selectedFile == i,
                          selectedTileColor:
                              const Color(0xFF21262D),
                          leading: Icon(
                            fileIcons[i],
                            size: 19,
                            color: i == 0
                                ? const Color(0xFF4B8BBE)
                                : Colors.grey,
                          ),
                          title: Text(files[i]),
                          onTap: () {
                            setState(() {
                              selectedFile = i;
                            });
                          },
                        ),

                      const Spacer(),

                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: OutlinedButton.icon(
                          onPressed: () {},
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
                ),

                // Editor
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 48,
                        color: const Color(0xFF161B22),
                        child: Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D1117),
                                border: Border(
                                  top: BorderSide(
                                    color: Color(0xFF4B8BBE),
                                    width: 2,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.code,
                                    size: 16,
                                    color: Color(0xFF4B8BBE),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(files[selectedFile]),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.close,
                                    size: 15,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          color: const Color(0xFF0D1117),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _sampleCode(files[selectedFile]),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                height: 1.7,
                                color: Color(0xFFE6EDF3),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Toolbar
                      Container(
                        height: 56,
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
                            FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.play_arrow,
                                size: 18,
                              ),
                              label: const Text('Run'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Save',
                              onPressed: () {},
                              icon: const Icon(Icons.save_outlined),
                            ),
                            IconButton(
                              tooltip: 'Search',
                              onPressed: () {},
                              icon: const Icon(Icons.search),
                            ),
                            const Spacer(),
                            const Text(
                              'Python',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Console
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF080B0F),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF30363D),
                ),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSOLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'YammieCode ready.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF8B949E),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  r'$ Waiting for program...',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF58A6FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sampleCode(String file) {
    switch (file) {
      case 'api.py':
        return '''from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def home():
    return {"message": "Hello YammieCode!"}
''';

      case 'requirements.txt':
        return '''fastapi
uvicorn
flet
requests
''';

      default:
        return '''import flet as ft


def main(page: ft.Page):
    page.title = "YammieCode"

    page.add(
        ft.Text("Hello, YammieCode!")
    )


if __name__ == "__main__":
    ft.run(main)
''';
    }
  }
}
