import 'package:flutter/material.dart';

import '../services/project_service.dart';
import 'ide_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() =>
      _ProjectsScreenState();
}

class _ProjectsScreenState
    extends State<ProjectsScreen> {
  List<String> projects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final result =
        await ProjectService.getProjects();

    if (!mounted) return;

    setState(() {
      projects = result;
      loading = false;
    });
  }

  Future<void> _createProject() async {
    final controller =
        TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'New Python Project',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Project name',
              hintText: 'MyPythonApp',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(
                    context,
                    value,
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      return;
    }

    await ProjectService.createProject(name);

    await _loadProjects();

    if (!mounted) return;

    _openProject(name);
  }

  void _openProject(String projectName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IDEScreen(
          projectName: projectName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'YammieCode',
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Project',
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : projects.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(16),
                  itemCount:
                      projects.length,
                  itemBuilder:
                      (context, index) {
                    final project =
                        projects[index];

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.folder,
                          ),
                        ),
                        title:
                            Text(project),
                        subtitle:
                            const Text(
                          'Python project',
                        ),
                        trailing:
                            const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () =>
                            _openProject(
                          project,
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_open,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'No projects yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first Python project.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createProject,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Create Project',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
