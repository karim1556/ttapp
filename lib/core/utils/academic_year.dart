String currentAcademicYear({DateTime? now}) {
  final date = now ?? DateTime.now();
  final startYear = date.month >= 6 ? date.year : date.year - 1;
  final endYear = (startYear + 1) % 100;
  return '$startYear-${endYear.toString().padLeft(2, '0')}';
}

List<String> academicYearOptions({DateTime? now}) {
  final date = now ?? DateTime.now();
  final year = date.year;
  final start = date.month >= 6 ? year : year - 1;
  return List.generate(5, (i) {
    final from = start - i;
    final to = (from + 1) % 100;
    return '$from-${to.toString().padLeft(2, '0')}';
  });
}

