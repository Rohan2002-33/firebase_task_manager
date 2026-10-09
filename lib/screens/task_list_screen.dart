import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/delete_task_dialog.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import '../services/notification_service.dart';

enum TaskFilter { all, pending, completed }

enum TaskSort { dueDate, priority, newest }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final Stream<List<TaskModel>> _stream;
  final _searchCtrl = TextEditingController();
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.dueDate;
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _stream = TaskService.instance.watchTasks();
        WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.onHomeReady();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TaskModel> _apply(List<TaskModel> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((t) {
      final okFilter = switch (_filter) {
        TaskFilter.all => true,
        TaskFilter.pending => !t.isCompleted,
        TaskFilter.completed => t.isCompleted,
      };
      final okQuery = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
      return okFilter && okQuery;
    }).toList();

    int rank(String p) => p == 'High' ? 0 : (p == 'Medium' ? 1 : 2);
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      switch (_sort) {
        case TaskSort.dueDate:
          return a.dueDate.compareTo(b.dueDate);
        case TaskSort.priority:
          final c = rank(a.priority).compareTo(rank(b.priority));
          return c != 0 ? c : a.dueDate.compareTo(b.dueDate);
        case TaskSort.newest:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return list;
  }

  Future<void> _delete(TaskModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.navy.withValues(alpha: .35),
      builder: (_) => DeleteTaskDialog(task: t),
    );
    if (ok != true) return;
    try {
      await TaskService.instance.deleteTask(t.id);
      if (mounted) showSnack(context, 'Task deleted');
    } catch (_) {
      if (mounted) showSnack(context, 'Could not delete task.', error: true);
    }
  }

  Future<void> _toggle(TaskModel t) async {
    try {
      await TaskService.instance.setCompleted(t.id, !t.isCompleted);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not update task.', error: true);
    }
  }

  void _openOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        Widget sortTile(String label, TaskSort s) => ListTile(
              title: Text(label, style: GoogleFonts.inter(fontSize: 15)),
              trailing: _sort == s
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _sort = s);
                Navigator.pop(ctx);
              },
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sort by', style: AppTheme.heading(17)),
                  ),
                ),
                sortTile('Due date', TaskSort.dueDate),
                sortTile('Priority', TaskSort.priority),
                sortTile('Newest first', TaskSort.newest),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(AuthService.instance.currentUser?.email ?? 'Account',
                      style: GoogleFonts.inter(fontSize: 14)),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: Text('Sign out',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    AuthService.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(int total) {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(
            bottom: BorderSide(color: AppColors.border.withValues(alpha: .7))),
      ),
      child: _searching
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: Icon(Icons.search_rounded),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _searching = false;
                    _query = '';
                    _searchCtrl.clear();
                  }),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Tasks', style: AppTheme.heading(24)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8EEF6),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('$total TOTAL',
                                style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Today • $today',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.muted),
                  onPressed: () => setState(() => _searching = true),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.muted),
                  onPressed: _openOptions,
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, int count, TaskFilter f) {
    final sel = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sel ? AppColors.navy : AppColors.border),
          ),
          child: Row(
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.navy)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: sel
                      ? Colors.white.withValues(alpha: .2)
                      : const Color(0xFFEEF2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final searching = _query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(searching ? Icons.search_off_rounded : Icons.task_alt_rounded,
                size: 56, color: AppColors.hint),
            const SizedBox(height: 12),
            Text(searching ? 'No matching tasks' : 'No tasks here yet',
                style: AppTheme.heading(18)),
            const SizedBox(height: 6),
            Text(
                searching
                    ? 'Try a different keyword.'
                    : 'Tap "New Task" to add your first one.',
                style: GoogleFonts.inter(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded),
        label: Text('New Task',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen())),
      ),
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load tasks.\n${snap.error}',
                    textAlign: TextAlign.center),
              ));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snap.data!;
            final pending = all.where((t) => !t.isCompleted).length;
            final completed = all.length - pending;
            final visible = _apply(all);
            return Column(
              children: [
                _header(all.length),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                  child: Row(children: [
                    _chip('All', all.length, TaskFilter.all),
                    _chip('Pending', pending, TaskFilter.pending),
                    _chip('Completed', completed, TaskFilter.completed),
                  ]),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _empty()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final t = visible[i];
                            return _TaskCard(
                              task: t,
                              onToggle: () => _toggle(t),
                              onDelete: () => _delete(t),
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => EditTaskScreen(task: t)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _mini(IconData icon, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final overdue = !done && task.dueDate.isBefore(startToday);
    final fmt = DateFormat('MMM d');
    const slate = Color(0xFF475569);

    return Opacity(
      opacity: done ? .55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: AppColors.navy.withValues(alpha: .04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 2, bottom: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? slate : Colors.white,
                          border: Border.all(
                              color: done ? slate : const Color(0xFFCBD5E1),
                              width: 1.5),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded,
                                size: 15, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PriorityBadge(priority: task.priority),
                            if (done) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text('Done',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF059669))),
                              ),
                            ],
                            const Spacer(),
                            _mini(Icons.edit_outlined, onEdit),
                            _mini(Icons.delete_outline_rounded, onDelete),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: done ? AppColors.muted : AppColors.navy,
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(task.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.muted)),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Divider(
                            height: 1,
                            color: AppColors.border.withValues(alpha: .8)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 13,
                                color:
                                    overdue ? AppColors.danger : AppColors.muted),
                            const SizedBox(width: 5),
                            Text('Due ${fmt.format(task.dueDate)}',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: overdue
                                        ? AppColors.danger
                                        : AppColors.muted)),
                            const SizedBox(width: 14),
                            const Icon(Icons.schedule_rounded,
                                size: 13, color: AppColors.hint),
                            const SizedBox(width: 5),
                            Text(fmt.format(task.createdAt),
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.hint)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}