import 'package:flutter/material.dart';

import '../services/project_service.dart';
import 'ide_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surface2 = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);
  static const Color accent = Color(0xFF4B8BBE);

  List<String> projects = [];
  List<String> filteredProjects = [];

  bool loading = true;
  bool refreshing = false;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // ============================================================
  // LOAD PROJECTS
  // ============================================================

  Future<void> _loadProjects({
    bool showRefresh = false,
  }) async {
    if (showRefresh && mounted) {
      setState(() {
        refreshing = true;
      });
    }

    try {
      final result = await ProjectService.getProjects();

      if (!mounted) return;

      setState(() {
        projects = result..sort(
          (a, b) => a.toLowerCase().compareTo(
            b.toLowerCase(),
          ),
        );

        _filterProjects();

        loading = false;
        refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
      });

      _showError(
        'Unable to load projects',
        error.toString(),
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _filterProjects() {
    final query = searchQuery.toLowerCase().trim();

    if (query.isEmpty) {
      filteredProjects = List.from(projects);
      return;
    }

    filteredProjects = projects.where((project) {
      return project.toLowerCase().contains(query);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      _filterProjects();
    });
  }

  // ============================================================
  // CREATE PROJECT
  // ============================================================

  Future<void> _createProject() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surface,
          title: const Row(
            children: [
              Icon(
                Icons.create_new_folder_outlined,
                color: accent,
              ),
              SizedBox(width: 10),
              Text('New Project'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Project name',
              hintText: 'MyPythonApp',
              prefixIcon: Icon(
                Icons.folder_outlined,
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(
                  context,
                  value.trim(),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
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
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.isEmpty) {
      return;
    }

    // Prevent duplicates.
    final exists = projects.any(
      (project) =>
          project.toLowerCase() ==
          name.toLowerCase(),
    );

    if (exists) {
      _showError(
        'Project already exists',
        'A project named "$name" already exists.',
      );
      return;
    }

    try {
      await ProjectService.createProject(name);

      await _loadProjects();

      if (!mounted) return;

      _showMessage(
        'Project created',
        Icons.check_circle_outline,
      );

      _openProject(name);
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Unable to create project',
        error.toString(),
      );
    }
  }

  // ============================================================
  // OPEN PROJECT
  // ============================================================

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

  // ============================================================
  // DELETE PROJECT
  // ============================================================

  Future<void> _deleteProject(
    String projectName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surface,
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text('Delete Project'),
            ],
          ),
          content: Text(
            'Delete "$projectName" and all files inside it?\n\n'
            'This action cannot be undone.',
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
                backgroundColor: Colors.redAccent,
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
      await ProjectService.deleteProject(
        projectName,
      );

      await _loadProjects();

      if (!mounted) return;

      _showMessage(
        'Project deleted',
        Icons.delete_outline,
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Unable to delete project',
        error.toString(),
      );
    }
  }

  // ============================================================
  // PROJECT MENU
  // ============================================================

  void _showProjectMenu(
    String projectName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.folder_open_outlined,
                  color: accent,
                ),
                title: const Text('Open Project'),
                onTap: () {
                  Navigator.pop(context);
                  _openProject(projectName);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text('Delete Project'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProject(projectName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showMessage(
    String message,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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

  void _showError(
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surface,
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
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        backgroundColor: accent,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () => _loadProjects(
                showRefresh: true,
              ),
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(),
                  ),

                  if (projects.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSearch(),
                    ),

                  if (filteredProjects.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: searchQuery.isNotEmpty
                          ? _buildNoResults()
                          : _emptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        100,
                      ),
                      sliver: _buildProjectList(),
                    ),
                ],
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
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.code_rounded,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'YammieCode',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: refreshing
              ? null
              : () {
                  _loadProjects(
                    showRefresh: true,
                  );
                },
          icon: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Projects',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            projects.isEmpty
                ? 'Create your first coding project.'
                : '${projects.length} project'
                    '${projects.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        8,
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search projects...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: accent),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROJECT LIST
  // ============================================================

  SliverList _buildProjectList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final project =
              filteredProjects[index];

          return _buildProjectCard(project);
        },
        childCount: filteredProjects.length,
      ),
    );
  }

  Widget _buildProjectCard(
    String projectName,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openProject(projectName),
        onLongPress: () {
          _showProjectMenu(projectName);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2110),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.code,
                          size: 13,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Python project',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Project options',
                onPressed: () {
                  _showProjectMenu(
                    projectName,
                  );
                },
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: surface,
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color: border,
                ),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 46,
                color: accent,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No projects yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a Python project and start building.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createProject,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create Project',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO SEARCH RESULTS
  // ============================================================

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 58,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No projects found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nothing matches "$searchQuery".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _onSearchChanged('');
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}