import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/time_slot_model.dart';

/// Timetable card widget used in full-week and room report views.
class TimetableGridWidget extends StatelessWidget {
  final TimeSlotModel slot;
  final Color? color;
  final VoidCallback? onTap;

  const TimetableGridWidget({
    super.key,
    required this.slot,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lecture = slot.lectures.isNotEmpty ? slot.lectures.first : null;
    final lectureCount = slot.lectures.length;
    final hasParallelLectures = lectureCount > 1;
    final batchSet = slot.lectures
        .map((e) => (e.batch ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final isBreak = lecture == null;
    final isLab = lecture?.isLabLecture ?? false;
    final isExtra = lecture?.isExtraLecture ?? false;
    final isSubstitution = lecture?.isSubstitution ?? false;

    if (isBreak) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.breakBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            _TimeRail(slot: slot, highlight: AppColors.breakText),
            const SizedBox(width: 14),
            const Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.free_breakfast_outlined,
                    size: 18,
                    color: AppColors.breakText,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Break / Free Slot',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.breakText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final accent = isLab ? AppColors.labText : (color ?? AppColors.primary);
    final primaryTitle = hasParallelLectures
        ? '$lectureCount Parallel Sessions'
        : (lecture.subjectName ?? lecture.subjectCode ?? 'Unknown Subject');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeRail(slot: slot, highlight: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            primaryTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isLab)
                          const _TypeTag(
                            label: 'Lab',
                            bgColor: AppColors.labBackground,
                            fgColor: AppColors.labText,
                          )
                        else
                          _TypeTag(
                            label: 'Lecture',
                            bgColor: AppColors.primary.withOpacity(0.12),
                            fgColor: AppColors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (lecture.subjectCode != null)
                          _MetaItem(
                            icon: Icons.book_outlined,
                            label: lecture.subjectCode!,
                          ),
                        if (lecture.facultyName != null)
                          _MetaItem(
                            icon: Icons.person_outline,
                            label: lecture.facultyName!,
                          ),
                        if (lecture.roomNumber != null)
                          _MetaItem(
                            icon: Icons.room_outlined,
                            label: 'Room ${lecture.roomNumber}',
                          ),
                        if (hasParallelLectures)
                          _MetaItem(
                            icon: Icons.layers_outlined,
                            label: '$lectureCount entries',
                          ),
                        if (hasParallelLectures && batchSet.isNotEmpty)
                          _MetaItem(
                            icon: Icons.groups_outlined,
                            label: 'Batch ${batchSet.join('/')}',
                          ),
                        if (isExtra)
                          const _MetaItem(
                            icon: Icons.add_circle_outline,
                            label: 'Extra',
                            color: AppColors.warning,
                          ),
                        if (isSubstitution)
                          const _MetaItem(
                            icon: Icons.swap_horiz,
                            label: 'Substitution',
                            color: AppColors.accent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary.withOpacity(0.65),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRail extends StatelessWidget {
  final TimeSlotModel slot;
  final Color highlight;

  const _TimeRail({required this.slot, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.startTimeDisplay,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: highlight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            slot.endTimeDisplay,
            style: TextStyle(
              fontSize: 12,
              color: highlight.withOpacity(0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color fgColor;

  const _TypeTag({
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
