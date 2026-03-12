import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/time_slot_model.dart';

/// Timetable grid cell widget. Displays one time slot with subject info.
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
    final isBreak = lecture == null;
    final isLab = lecture?.isLabLecture ?? false;
    final isExtra = lecture?.isExtraLecture ?? false;
    final isSubstitution = lecture?.isSubstitution ?? false;

    final bgColor = isBreak
        ? AppColors.breakBackground
        : isLab
            ? AppColors.labBackground
            : (color?.withOpacity(0.12) ?? AppColors.primaryLight);
    final borderColor = isBreak
        ? AppColors.textDisabled
        : isLab
            ? AppColors.labText
            : (color ?? AppColors.primary);
    final subjectTextColor = isBreak
        ? AppColors.breakText
        : isLab
            ? AppColors.labText
            : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.startTimeDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slot.endTimeDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: borderColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            Container(
              height: 40,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: borderColor.withOpacity(0.25),
            ),

            // Lecture content
            Expanded(
              child: isBreak
                  ? Row(
                      children: [
                        const Icon(Icons.free_breakfast_outlined,
                            color: AppColors.breakText, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Break / Free',
                          style: TextStyle(
                            color: AppColors.breakText,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject name + tags
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lecture!.subjectName ??
                                    lecture.subjectCode ??
                                    'Unknown Subject',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: subjectTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isLab)
                              _SmallTag(label: 'Lab', color: AppColors.labText),
                            if (isExtra)
                              _SmallTag(label: 'Extra', color: AppColors.warning),
                            if (isSubstitution)
                              _SmallTag(label: 'Sub', color: AppColors.accent),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Meta info row
                        Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          children: [
                            if (lecture!.subjectCode != null)
                              _MetaItem(
                                icon: Icons.book_outlined,
                                label: lecture.subjectCode!,
                              ),
                            if (lecture.facultyName != null)
                              _MetaItem(
                                icon: Icons.person_outlined,
                                label: lecture.facultyName!,
                              ),
                            if (lecture.roomNumber != null)
                              _MetaItem(
                                icon: Icons.room_outlined,
                                label: 'Room ${lecture.roomNumber}',
                              ),
                            if (lecture.batch != null &&
                                lecture.batch!.isNotEmpty)
                              _MetaItem(
                                icon: Icons.group_outlined,
                                label: lecture.batch!,
                              ),
                          ],
                        ),
                      ],
                    ),
            ),

            if (onTap != null && !isBreak)
              Icon(Icons.info_outline_rounded,
                  color: AppColors.textSecondary.withOpacity(0.6), size: 18),
          ],
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
