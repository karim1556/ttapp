String currentAcademicYear({DateTime? now}) {
  final date = now ?? DateTime.now();
  final startYear = date.month >= 6 ? date.year : date.year - 1;
  final endYear = (startYear + 1) % 100;
  return '$startYear-${endYear.toString().padLeft(2, '0')}';
}

List<String> academicYearOptions({DateTime? now}) {
  return [currentAcademicYear(now: now)];
}
