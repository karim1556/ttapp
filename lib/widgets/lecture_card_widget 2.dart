import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/time_slot_model.dart';

/// A card displaying a single time slot with its lecture details.
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

    Color cardColor;
    Color textColor;
    if (isBreak) {
      cardColor = AppColors.breakBackground;
      textColor = AppColors.breakText;
    } else if (isLab) {
      cardColor = AppColors.labBackground;
      textColor = AppColors.labText;
    } else {
      cardColor = color ?? AppColors.primaryLight;
      textColor = AppColors.primary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isBreak
                  ? AppColors.textDisabled
                  : isLab
                      ? AppColors.labText
                      : textColor,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Time column
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.startTimeDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  Text(
                    slot.endTimeDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Vertical divider
            Container(
              width: 1,
              height: 36,
              color: textColor.withOpacity(0.25),
            ),
            const SizedBox(width: 12),

            // Lecture info
            Expanded(
              child: isBreak
                  ? Text(
                      'Break',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.breakText,
                        fontSize: 14,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isLab) ...[
                              const SizedBox(width: 6),
                              _Tag(label: 'Lab', color: AppColors.labText),
                            ],
                            if (isSubstitution) ...[
                              const SizedBox(width: 6),
                              _Tag(label: 'Sub', color: AppColors.warning),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (lecture!.facultyName != null) ...[
                              const Icon(Icons.person_outline,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  lecture.facultyName!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (lecture.roomNumber != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.room_outlined,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                lecture.roomNumber!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (lecture.batch != null &&
                                lecture.batch!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.group_outlined,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                lecture.batch!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
            ),

            if (onTap != null && !isBreak)
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
