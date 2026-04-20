import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/time_slot_model.dart';

/// Compact lecture slot card used in Today and Dashboard previews.
class LectureCardWidget extends StatelessWidget {
  final TimeSlotModel slot;
  final VoidCallback? onTap;
  final Color? color;

  const LectureCardWidget({
    super.key,
    required this.slot,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final lecture = slot.lectures.isNotEmpty ? slot.lectures.first : null;
    final isBreak = lecture == null;
    final isLab = lecture?.isLabLecture ?? false;
    final isSubstitution = lecture?.isSubstitution ?? false;
    final lectureCount = slot.lectures.length;
    final hasParallelLectures = lectureCount > 1;
    final batchSet = slot.lectures
        .map((e) => (e.batch ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    if (isBreak) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.breakBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            _TimeColumn(slot: slot, color: AppColors.breakText),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Break',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.breakText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final accentColor = isLab
        ? AppColors.labText
        : (color ?? AppColors.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeColumn(slot: slot, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasParallelLectures
                                ? '$lectureCount Parallel Sessions'
                                : (lecture.subjectName ??
                                      lecture.subjectCode ??
                                      'Unknown Subject'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PillTag(
                              label: isLab ? 'Lab' : 'Lecture',
                              color: isLab ? AppColors.labText : AppColors.primary,
                            ),
                            if (isSubstitution) ...[
                              const SizedBox(width: 6),
                              const _PillTag(
                                label: 'Substitute',
                                color: AppColors.warning,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (lecture.facultyName != null)
                          _MetaText(
                            icon: Icons.person_outline,
                            text: lecture.facultyName!,
                          ),
                        if (lecture.roomNumber != null)
                          _MetaText(
                            icon: Icons.room_outlined,
                            text: 'Room ${lecture.roomNumber}',
                          ),
                        if (hasParallelLectures && batchSet.isNotEmpty)
                          _MetaText(
                            icon: Icons.groups_outlined,
                            text: 'Batch ${batchSet.join('/')}',
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

class _TimeColumn extends StatelessWidget {
  final TimeSlotModel slot;
  final Color color;

  const _TimeColumn({required this.slot, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.startTimeDisplay,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            slot.endTimeDisplay,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String label;
  final Color color;

  const _PillTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
