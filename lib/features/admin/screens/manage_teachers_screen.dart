import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/faculty_model.dart';
import '../../../providers/faculty_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';
import '../../../providers/subject_provider.dart';

class ManageTeachersScreen extends ConsumerStatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  ConsumerState<ManageTeachersScreen> createState() =>
      _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends ConsumerState<ManageTeachersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedBranch;
  int? _selectedSemester;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facultyProvider.notifier).loadFaculty();
      ref.read(subjectProvider.notifier).loadSubjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facultyState = ref.watch(facultyProvider);
    final subjects = ref.watch(subjectProvider).subjects;
    
    final isLoading = (facultyState.status == FacultyStatus.loading && facultyState.faculty.isEmpty) ||
                      (ref.watch(subjectProvider).status == SubjectStatus.loading && subjects.isEmpty);

    final filtered = facultyState.faculty.where((f) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          f.name.toLowerCase().contains(q) ||
          f.email.toLowerCase().contains(q);
      
      final matchesBranch = _selectedBranch == null || f.branchId == _selectedBranch;
      
      bool matchesSem = true;
      if (_selectedSemester != null) {
        final teacherSubjects = subjects.where((s) {
          final profId = int.tryParse(s.professorAssign ?? '');
          return profId == f.facultyId && s.semester == _selectedSemester;
        });
        matchesSem = teacherSubjects.isNotEmpty;
      }
      
      return matchesQuery && matchesBranch && matchesSem;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.read(facultyProvider.notifier).loadFaculty();
              ref.read(subjectProvider.notifier).loadSubjects();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeacherDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
      ),
      body: Column(
        children: [
          // Search & Filters Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: Icon(Icons.search_outlined),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedBranch,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Dept')),
                          DropdownMenuItem(value: 1, child: Text('CS')),
                          DropdownMenuItem(value: 2, child: Text('IT')),
                          DropdownMenuItem(value: 3, child: Text('EXTC')),
                          DropdownMenuItem(value: 4, child: Text('Mech')),
                        ],
                        onChanged: (v) => setState(() => _selectedBranch = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedSemester,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Sem')),
                          ...List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Sem ${i + 1}'))),
                        ],
                        onChanged: (v) => setState(() => _selectedSemester = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const FullScreenLoader(message: 'Loading teachers...')
                : filtered.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.person_search_outlined,
                        title: 'No teachers found',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Add your first teacher using the + button',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _TeacherCard(
                            faculty: filtered[index],
                            onEdit: () =>
                                _showEditDialog(context, filtered[index]),
                            onDelete: () => _confirmDelete(
                                context, filtered[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddTeacherDialog(BuildContext context) {
    _showTeacherFormDialog(context, null);
  }

  void _showEditDialog(BuildContext context, FacultyModel faculty) {
    _showTeacherFormDialog(context, faculty);
  }

  void _showTeacherFormDialog(BuildContext context, FacultyModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final emailCtrl = TextEditingController(text: existing?.email);
    final contactCtrl = TextEditingController(text: existing?.contact);
    final qualCtrl = TextEditingController(text: existing?.qualification);
    final roleCtrl = TextEditingController(text: existing?.role);
    final weeklyHoursCtrl = TextEditingController(
      text: (existing?.weeklyWorkHours ?? 18).toString(),
    );
    final clgIdCtrl = TextEditingController(text: existing?.facultyClgId);
    final panCtrl = TextEditingController(text: existing?.panNo);
    final aadharCtrl = TextEditingController(text: existing?.aadharCard);
    final permAddrCtrl = TextEditingController(text: existing?.permanentAddress);
    final currAddrCtrl = TextEditingController(text: existing?.currentAddress);
    final altMobileCtrl = TextEditingController(text: existing?.alternateMobile);
    final expCtrl = TextEditingController(text: existing?.experienceDetails);
    final formKey = GlobalKey<FormState>();

    int branchId = existing?.branchId ?? 1;
    int? departId = existing?.departId;
    int? ftypeId = existing?.ftypeId;
    int? shiftId = existing?.shiftId;
    int privilege = existing?.privilege ?? 0;
    int status = existing?.status ?? 1;
    String gender = existing?.gender ?? 'Male';
    String? bloodGroup = existing?.bloodGroup;
    String? dob = existing?.dob;
    String? joiningDate = existing?.joiningDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Teacher' : 'Edit Teacher'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 12),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Basic Info ---
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email *'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: contactCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: clgIdCtrl,
                      decoration: const InputDecoration(labelText: 'College ID'),
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Department & Branch',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),

                    // --- Branch ---
                    DropdownButtonFormField<int>(
                      value: branchId,
                      decoration: const InputDecoration(labelText: 'Branch *'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('CS')),
                        DropdownMenuItem(value: 2, child: Text('IT')),
                        DropdownMenuItem(value: 3, child: Text('EXTC')),
                        DropdownMenuItem(value: 4, child: Text('Mech')),
                      ],
                      onChanged: (v) => setDialogState(() => branchId = v ?? 1),
                    ),
                    const SizedBox(height: 10),

                    // --- Department ---
                    DropdownButtonFormField<int>(
                      value: departId,
                      decoration: const InputDecoration(labelText: 'Department'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Computer Science')),
                        DropdownMenuItem(value: 2, child: Text('Information Technology')),
                        DropdownMenuItem(value: 3, child: Text('Electronics')),
                        DropdownMenuItem(value: 4, child: Text('Mechanical')),
                        DropdownMenuItem(value: 5, child: Text('General')),
                      ],
                      onChanged: (v) => setDialogState(() => departId = v),
                    ),
                    const SizedBox(height: 10),

                    // --- Role ---
                    TextFormField(
                      controller: roleCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Role',
                          hintText: 'e.g. Professor, Asst. Professor'),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: weeklyHoursCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Weekly Work Hours *',
                        hintText: 'e.g. 18',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final parsed = int.tryParse(v.trim());
                        if (parsed == null) return 'Must be a number';
                        if (parsed < 1 || parsed > 60) return 'Allowed range: 1-60';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // --- Qualification ---
                    TextFormField(
                      controller: qualCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Qualification',
                          hintText: 'e.g. M.Tech, PhD'),
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Personal Details',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),

                    // --- Gender ---
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setDialogState(() => gender = v ?? 'Male'),
                    ),
                    const SizedBox(height: 10),

                    // --- DOB ---
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dob != null
                          ? 'Date of Birth: ${dob!.split('T').first}'
                          : 'Date of Birth (tap to select)'),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime(1990),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() =>
                              dob = picked.toIso8601String().split('T').first);
                        }
                      },
                    ),

                    // --- Joining Date ---
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(joiningDate != null
                          ? 'Joining Date: ${joiningDate!.split('T').first}'
                          : 'Joining Date (tap to select)'),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setDialogState(() =>
                              joiningDate = picked.toIso8601String().split('T').first);
                        }
                      },
                    ),

                    // --- Blood Group ---
                    DropdownButtonFormField<String>(
                      value: bloodGroup,
                      decoration: const InputDecoration(labelText: 'Blood Group'),
                      items: const [
                        DropdownMenuItem(value: 'A+', child: Text('A+')),
                        DropdownMenuItem(value: 'A-', child: Text('A-')),
                        DropdownMenuItem(value: 'B+', child: Text('B+')),
                        DropdownMenuItem(value: 'B-', child: Text('B-')),
                        DropdownMenuItem(value: 'O+', child: Text('O+')),
                        DropdownMenuItem(value: 'O-', child: Text('O-')),
                        DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                        DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                      ],
                      onChanged: (v) => setDialogState(() => bloodGroup = v),
                    ),
                    const SizedBox(height: 10),

                    // --- PAN ---
                    TextFormField(
                      controller: panCtrl,
                      decoration: const InputDecoration(labelText: 'PAN No'),
                    ),
                    const SizedBox(height: 10),

                    // --- Aadhar ---
                    TextFormField(
                      controller: aadharCtrl,
                      decoration: const InputDecoration(labelText: 'Aadhar Card No'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),

                    // --- Alt Mobile ---
                    TextFormField(
                      controller: altMobileCtrl,
                      decoration: const InputDecoration(labelText: 'Alternate Mobile'),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Address & Experience',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),

                    // --- Permanent Address ---
                    TextFormField(
                      controller: permAddrCtrl,
                      decoration: const InputDecoration(labelText: 'Permanent Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),

                    // --- Current Address ---
                    TextFormField(
                      controller: currAddrCtrl,
                      decoration: const InputDecoration(labelText: 'Current Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),

                    // --- Experience ---
                    TextFormField(
                      controller: expCtrl,
                      decoration: const InputDecoration(labelText: 'Experience Details'),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Faculty Type & Access',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),

                    // --- Faculty Type ---
                    DropdownButtonFormField<int>(
                      value: ftypeId,
                      decoration: const InputDecoration(labelText: 'Faculty Type'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Permanent')),
                        DropdownMenuItem(value: 2, child: Text('Visiting')),
                        DropdownMenuItem(value: 3, child: Text('Contract')),
                        DropdownMenuItem(value: 4, child: Text('Adjunct')),
                      ],
                      onChanged: (v) => setDialogState(() => ftypeId = v),
                    ),
                    const SizedBox(height: 10),

                    // --- Shift ---
                    DropdownButtonFormField<int>(
                      value: shiftId,
                      decoration: const InputDecoration(labelText: 'Shift'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Morning')),
                        DropdownMenuItem(value: 2, child: Text('Evening')),
                      ],
                      onChanged: (v) => setDialogState(() => shiftId = v),
                    ),
                    const SizedBox(height: 10),

                    // --- Privilege ---
                    DropdownButtonFormField<int>(
                      value: privilege,
                      decoration: const InputDecoration(labelText: 'Privilege Level'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('None')),
                        DropdownMenuItem(value: 1, child: Text('Basic')),
                        DropdownMenuItem(value: 2, child: Text('Admin')),
                      ],
                      onChanged: (v) => setDialogState(() => privilege = v ?? 0),
                    ),
                    const SizedBox(height: 10),

                    // --- Status ---
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      subtitle: Text(status == 1 ? 'Teacher is active' : 'Teacher is inactive'),
                      value: status == 1,
                      onChanged: (v) => setDialogState(() => status = v ? 1 : 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'contact': contactCtrl.text.trim(),
                  'qualification': qualCtrl.text.trim(),
                  'branch_id': branchId,
                  'depart_id': departId,
                  'role': roleCtrl.text.trim(),
                  'gender': gender,
                  'faculty_clg_id': clgIdCtrl.text.trim(),
                  'blood_group': bloodGroup,
                  'pan_no': panCtrl.text.trim(),
                  'aadhar_card': aadharCtrl.text.trim(),
                  'permanent_address': permAddrCtrl.text.trim(),
                  'current_address': currAddrCtrl.text.trim(),
                  'alternate_mobile': altMobileCtrl.text.trim(),
                  'experience_details': expCtrl.text.trim(),
                  'weekly_work_hours': int.parse(weeklyHoursCtrl.text.trim()),
                  'ftype_id': ftypeId,
                  'shift_id': shiftId,
                  'previlage': privilege,
                  'status': status,
                  if (dob != null) 'dob': dob,
                  if (joiningDate != null) 'joining_date': joiningDate,
                };
                Navigator.pop(ctx);
              if (existing == null) {
                final credentials = await ref
                    .read(facultyProvider.notifier)
                    .createFaculty(data);
                if (mounted) {
                  if (credentials != null) {
                    showDialog(
                      context: context,
                      builder: (dlgCtx) => AlertDialog(
                        title: const Text('Teacher Created'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Share these login credentials with the teacher:'),
                            const SizedBox(height: 12),
                            SelectableText(
                                'Email: ${credentials['email']}'),
                            SelectableText(
                                'Password: ${credentials['defaultPassword']}'),
                            const SizedBox(height: 8),
                            const Text(
                              'They should change their password after first login.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dlgCtx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to create teacher'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              } else {
                final success = await ref
                    .read(facultyProvider.notifier)
                    .updateFaculty(existing.facultyId, data);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          success ? 'Teacher updated' : 'Operation failed'),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
        ),    // closes AlertDialog
      ),      // closes StatefulBuilder
    );        // closes showDialog
  }

  Future<void> _confirmDelete(BuildContext context, FacultyModel faculty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text(
            'Are you sure you want to remove ${faculty.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(facultyProvider.notifier).deleteFaculty(faculty.facultyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? '${faculty.name} removed' : 'Failed to delete'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}

class _TeacherCard extends StatelessWidget {
  final FacultyModel faculty;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCard({
    required this.faculty,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          backgroundImage:
              faculty.photo != null ? NetworkImage(faculty.photo!) : null,
          child: faculty.photo == null
              ? Text(
                  faculty.name.isNotEmpty ? faculty.name[0].toUpperCase() : 'T',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          faculty.name,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(faculty.email,
                style: Theme.of(context).textTheme.bodySmall),
            if (faculty.contact != null) ...[
              const SizedBox(height: 2),
              Text(faculty.contact!,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (faculty.role != null || faculty.branchId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (faculty.role != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        faculty.role!,
                        style: const TextStyle(
                            color: AppColors.info, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (faculty.branchId != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _branchName(faculty.branchId!),
                        style: const TextStyle(
                            color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  if (faculty.weeklyWorkHours != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${faculty.weeklyWorkHours} hr/wk',
                        style: const TextStyle(
                            color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: faculty.isActive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                faculty.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: faculty.isActive ? AppColors.success : AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  static String _branchName(int id) {
    switch (id) {
      case 1: return 'CS';
      case 2: return 'IT';
      case 3: return 'EXTC';
      case 4: return 'Mech';
      default: return 'Branch $id';
    }
  }
}
