import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  late DateTime _due;
  String _priority = 'Medium';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _due = DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final task = TaskModel(
        id: '',
        title: _title.text.trim(),
        description: _notes.text.trim(),
        dueDate: _due,
        priority: _priority,
        isCompleted: false,
        createdAt: DateTime.now(),
        course: 'General',
      );
            final newId = await TaskService.instance.addTask(task);
      NotificationService.instance.showTaskNotification(
        title: 'New Task',
        body: 'You have a new task: ${task.title}',
        taskId: newId,
        priority: task.priority,
      );
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Task added')));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Could not save task. Try again.', error: true);
      }
    }
  }

  Widget _priorityChip(String p) {
    final selected = _priority == p;
    final c = AppColors.priority(p);
    final dark = Color.lerp(c, Colors.black, .4)!;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(
            color: selected ? c.withValues(alpha: .12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? c.withValues(alpha: .6) : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(p,
                  style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? dark : AppColors.navy)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text('New Task',
                      style: AppTheme.heading(17, weight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const FieldLabel('Title'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _title,
                      maxLength: 60,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Complete Flutter Assignment',
                          counterText: ''),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Notes'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notes,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          hintText: 'Add details, links, or notes...'),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Due Date'),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickDate,
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(DateFormat('MM/dd/yyyy').format(_due),
                                    style: GoogleFonts.inter(fontSize: 15))),
                            const Icon(Icons.calendar_today_outlined,
                                size: 19, color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Priority'),
                    const SizedBox(height: 8),
                    Row(children: [
                      _priorityChip('Low'),
                      const SizedBox(width: 10),
                      _priorityChip('Medium'),
                      const SizedBox(width: 10),
                      _priorityChip('High'),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  PrimaryButton(
                      label: 'Save Task', loading: _saving, onPressed: _save),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: AppColors.muted)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}