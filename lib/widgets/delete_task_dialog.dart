import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class DeleteTaskDialog extends StatelessWidget {
  final TaskModel task;
  const DeleteTaskDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Delete Task?', style: AppTheme.heading(22)),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to remove this task?\nThis action cannot be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(task.course,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const Spacer(),
                      PriorityBadge(
                          priority: task.priority,
                          label: '${task.priority} Priority'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.hint),
                      const SizedBox(width: 6),
                      Text('Due ${DateFormat('MMM d, y').format(task.dueDate)}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Delete Task',
              color: AppColors.danger,
              leadingIcon: Icons.delete_outline_rounded,
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.inter(
                      color: AppColors.navy, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}