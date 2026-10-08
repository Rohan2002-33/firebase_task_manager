import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  static const _courses = ['CS 421', 'CS 304', 'CS 101', 'General'];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  late DateTime _due;
  late String _priority;
  late String _course;
  late bool _completed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fill(widget.task);
    _title.addListener(() => setState(() {}));
  }

  void _fill(TaskModel t) {
    _title.text = t.title;
    _desc.text = t.description;
    _due = t.dueDate;
    _priority = t.priority;
    _course = t.course;
    _completed = t.isCompleted;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
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
      await TaskService.instance.updateTask(widget.task.copyWith(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        dueDate: _due,
        priority: _priority,
        course: _course,
        isCompleted: _completed,
      ));
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Task updated')));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Could not update task. Try again.', error: true);
      }
    }
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted));

  BoxDecoration get _boxDeco => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      );

  @override
  Widget build(BuildContext context) {
    final courses = {..._courses, _course}.toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('Edit Task',
                      style: AppTheme.heading(17, weight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _fill(widget.task)),
                    child: Text('Reset',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.muted)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _label('Task Title'),
                        Text('${_title.text.length}/60',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.hint)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _title,
                      maxLength: 60,
                      decoration: InputDecoration(
                        counterText: '',
                        suffixIcon: _title.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.muted),
                                onPressed: _title.clear,
                              ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    _label('Description & Milestones'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _desc,
                      minLines: 3,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Due Date'),
                              const SizedBox(height: 8),
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _pickDate,
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: _boxDeco,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 18, color: AppColors.muted),
                                      const SizedBox(width: 8),
                                      Text(DateFormat('MM/dd/yyyy').format(_due),
                                          style:
                                              GoogleFonts.inter(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Course Bucket'),
                              const SizedBox(height: 8),
                              Container(
                                height: 52,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: _boxDeco,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _course,
                                    isExpanded: true,
                                    icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.muted),
                                    items: courses
                                        .map((c) => DropdownMenuItem(
                                              value: c,
                                              child: Row(children: [
                                                Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration:
                                                        const BoxDecoration(
                                                            color:
                                                                AppColors.navy,
                                                            shape: BoxShape
                                                                .circle)),
                                                const SizedBox(width: 8),
                                                Text(c,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 14)),
                                              ]),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _course = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _label('Priority'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F7),
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: ['Low', 'Medium', 'High'].map((p) {
                          final sel = _priority == p;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _priority = p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sel ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: sel
                                      ? [
                                          BoxShadow(
                                              color: AppColors.navy
                                                  .withValues(alpha: .08),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2))
                                        ]
                                      : null,
                                ),
                                child: Text(p,
                                    style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? AppColors.navy
                                            : AppColors.muted)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: _boxDeco,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Completed',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('Mark task as done',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _completed,
                            onChanged: (v) => setState(() => _completed = v),
                            thumbColor: WidgetStateProperty.all(Colors.white),
                            trackOutlineColor:
                                WidgetStateProperty.all(Colors.transparent),
                            trackColor: WidgetStateProperty.resolveWith((s) =>
                                s.contains(WidgetState.selected)
                                    ? AppColors.primary
                                    : const Color(0xFFCBD5E1)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Save Changes',
                    color: AppColors.navy,
                    leadingIcon: Icons.check_rounded,
                    loading: _saving,
                    onPressed: _save,
                  ),
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