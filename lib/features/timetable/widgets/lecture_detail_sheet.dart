import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/time_slot_model.dart';
import '../../../models/lecture_assignment_model.dart';

class LectureDetailSheet extends StatelessWidget {
  final TimeSlotModel slot;
  final void Function(LectureAssignmentModel)? onEdit;

  const LectureDetailSheet({super.key, required this.slot, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final lectures = slot.lectures;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Time header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        slot.timeRangeDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${lectures.length} lecture${lectures.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20),

              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: lectures.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final lec = lectures[index];
                    return _LectureDetailCard(
                      lecture: lec,
                      onEdit: onEdit != null
                          ? () {
                              Navigator.pop(context);
                              onEdit!(lec);
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LectureDetailCard extends StatelessWidget {
  final LectureAssignmentModel lecture;
  final VoidCallback? onEdit;

  const _LectureDetailCard({required this.lecture, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lecture.isLabLecture
                    ? AppColors.labBackground
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                lecture.isLabLecture
                    ? Icons.science_outlined
                    : Icons.menu_book_outlined,
                color: lecture.isLabLecture
                    ? AppColors.labText
                    : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.subjectName ??
                        lecture.subjectCode ??
                        'Unknown Subject',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (lecture.subjectCode != null)
                    Text(
                      lecture.subjectCode!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit this lecture',
                color: AppColors.primary,
                onPressed: onEdit,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Details grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (lecture.typeOfLecture != null)
              _DetailChip(
                icon: Icons.category_outlined,
                label: lecture.typeOfLecture!,
                color: lecture.isLabLecture
                    ? AppColors.labText
                    : AppColors.primary,
              ),
            if (lecture.facultyName != null)
              _DetailChip(
                icon: Icons.person_outlined,
                label: lecture.facultyName!,
              ),
            if (lecture.roomNumber != null)
              _DetailChip(
                icon: Icons.room_outlined,
                label: 'Room ${lecture.roomNumber}',
              ),
            if (lecture.batch != null && lecture.batch!.isNotEmpty)
              _DetailChip(
                icon: Icons.group_outlined,
                label: 'Batch ${lecture.batch}',
              ),
          ],
        ),

        // Substitution info
        if (lecture.isSubstitution) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Substitution Lecture',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (lecture.reason != null)
                        Text(
                          lecture.reason!,
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Extra lecture info
        if (lecture.isExtraLecture) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: AppColors.info, size: 16),
                SizedBox(width: 6),
                Text(
                  'Extra Lecture',
                  style: TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _DetailChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
