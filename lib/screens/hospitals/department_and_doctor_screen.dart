import 'dart:convert';

import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_form/hospital_form.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/hospitals/hospitals_screen.dart';
import 'package:drift/drift.dart' show Value;

class DepartmentAndDoctorScreen extends StatefulWidget {
  static const name = 'DepartmentAndDoctor';
  static const path = '/hospitals/:id/department_and_doctor';

  final int hospitalId;

  const DepartmentAndDoctorScreen({
    super.key,
    required this.hospitalId,
  });

  @override
  State<DepartmentAndDoctorScreen> createState() => _DepartmentAndDoctorScreenState();
}

class _DepartmentAndDoctorScreenState extends State<DepartmentAndDoctorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Hospital? _hospital;
  List<Department> _departments = [];
  List<Doctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final database = context.read<AppDatabase>();

      // Fetch hospital
      final hospital = await database.getHospitalById(widget.hospitalId);
      if (hospital == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch departments
      List<Department> departments = [];
      if (hospital.departmentIds.isNotEmpty) {
        try {
          final departmentIds = (json.decode(hospital.departmentIds) as List)
              .map((e) => int.parse(e.toString()))
              .toList();
          for (final deptId in departmentIds) {
            final deptResults = await (database.select(database.departments)
                  ..where((d) => d.id.equals(deptId)))
                .get();
            departments.addAll(deptResults);
          }
        } catch (e) {
          // Silently handle JSON parsing errors
        }
      }

      // Fetch doctors for this hospital
      final doctors = await (database.select(database.doctors)
            ..where((d) => d.hospitalId.equals(widget.hospitalId)))
          .get();

      setState(() {
        _hospital = hospital;
        _departments = departments;
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDepartmentCategoryDisplayName(String category) {
    switch (category) {
      case 'InternalMedicine':
        return 'Internal Medicine';
      case 'ObstetricsGynecology':
        return 'Obstetrics & Gynecology';
      case 'TraditionalChineseMedicine':
        return 'Traditional Chinese Medicine';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hospital == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.departmentAndDoctorTitle),
        ),
        body: Center(
          child: Text('Hospital not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.departmentAndDoctorTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(HospitalsScreen.name),
        ),
      ),
      body: Column(
        children: [
          // Hospital Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _hospital!.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_hospital!.address != null && _hospital!.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _hospital!.address!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.business_outlined),
                text: context.l10n.departments,
              ),
              Tab(
                icon: const Icon(Icons.person_outline),
                text: context.l10n.doctors,
              ),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDepartmentsTab(),
                _buildDoctorsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildDepartmentsTab() {
    if (_departments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noDepartments,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _departments.length,
      itemBuilder: (context, index) {
        final department = _departments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.business,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(department.name),
            subtitle: department.category != null
                ? Text(_getDepartmentCategoryDisplayName(department.category!))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    _showEditDepartmentDialog(department);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    // TODO: Implement department removal
                    _showRemoveDepartmentDialog(department);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorsTab() {
    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noDoctors,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            title: Text(doctor.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doctor.level != null && doctor.level!.isNotEmpty)
                  Text(doctor.level!),
                FutureBuilder<Department?>(
                    future: _getDepartmentById(doctor.departmentId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          snapshot.data!.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      } else if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Loading...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        );
                      } else {
                        return Text(
                          'Department not found',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<Department?>(
                  future: _getDepartmentById(doctor.departmentId),
                  builder: (context, snapshot) {
                    final departmentExists = snapshot.hasData && snapshot.data != null;
                    return IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: departmentExists ? null : Theme.of(context).colorScheme.outline,
                      ),
                      onPressed: departmentExists ? () {
                        _showEditDoctorDialog(doctor);
                      } : null,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    // TODO: Implement doctor removal
                    _showRemoveDoctorDialog(doctor);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Department?> _getDepartmentById(int departmentId) async {
    try {
      final database = context.read<AppDatabase>();
      final departments = await (database.select(database.departments)
            ..where((d) => d.id.equals(departmentId)))
          .get();
      return departments.isNotEmpty ? departments.first : null;
    } catch (e) {
      return null;
    }
  }

  void _showRemoveDepartmentDialog(Department department) {
    // Count doctors assigned to this department
    final doctorsInDepartment = _doctors.where((doctor) => doctor.departmentId == department.id).length;

    String warningMessage = doctorsInDepartment > 0
        ? 'Warning: $doctorsInDepartment doctor${doctorsInDepartment == 1 ? '' : 's'} assigned to this department will also be removed. Are you sure?'
        : 'Are you sure you want to remove ${department.name} from this hospital?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Department'),
        content: Text(warningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _removeDepartment(department);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDoctorDialog(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Doctor'),
        content: Text('Are you sure you want to remove ${doctor.name} from this hospital?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _removeDoctor(doctor);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 0) {
          _showAddDepartmentDialog();
        } else {
          _showAddDoctorDialog();
        }
      },
      child: Icon(_tabController.index == 0 ? Icons.add_business : Icons.person_add),
    );
  }

  void _showAddDepartmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.addDepartment),
        content: SizedBox(
          width: double.maxFinite,
          child: DepartmentFormWidget(
            isEditMode: false,
            onSave: (name, category) async {
              await _addDepartment(name, category);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.departmentAddedSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showEditDepartmentDialog(Department department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.edit),
        content: SizedBox(
          width: double.maxFinite,
          child: DepartmentFormWidget(
            initialName: department.name,
            initialCategory: department.category,
            isEditMode: true,
            onSave: (name, category) async {
              await _updateDepartment(department.id, name, category);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.departmentUpdatedSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showAddDoctorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.addDoctor),
        content: SizedBox(
          width: double.maxFinite,
          child: DoctorFormWidget(
            availableDepartments: _departments,
            isEditMode: false,
            onSave: (name, departmentId, level) async {
              await _addDoctor(name, departmentId, level);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.doctorAddedSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showEditDoctorDialog(Doctor doctor) {
    // Check if the doctor's department still exists
    final departmentExists = _departments.any((dept) => dept.id == doctor.departmentId);

    if (!departmentExists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cannot Edit Doctor'),
          content: Text('${doctor.name} is assigned to a department that no longer exists. Please remove this doctor and create a new one with a valid department assignment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.edit),
        content: SizedBox(
          width: double.maxFinite,
          child: DoctorFormWidget(
            initialName: doctor.name,
            initialLevel: doctor.level,
            initialDepartmentId: doctor.departmentId,
            availableDepartments: _departments,
            isEditMode: true,
            onSave: (name, departmentId, level) async {
              await _updateDoctor(doctor.id, name, departmentId, level);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.doctorUpdatedSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addDepartment(String name, String? category) async {
    try {
      final database = context.read<AppDatabase>();

      // Create the department
      final departmentId = await database.createDepartment(
        DepartmentsCompanion(
          name: Value(name),
          category: Value(category),
        ),
      );

      // Add department ID to hospital's departmentIds
      if (_hospital != null) {
        final currentIds = <int>[];
        if (_hospital!.departmentIds.isNotEmpty) {
          try {
            final ids = (json.decode(_hospital!.departmentIds) as List)
                .map((e) => int.parse(e.toString()))
                .toList();
            currentIds.addAll(ids);
          } catch (e) {
            // Handle JSON parsing errors
          }
        }

        currentIds.add(departmentId);

        final updatedHospital = _hospital!.copyWith(
          departmentIds: json.encode(currentIds),
        );

        await database.updateHospital(updatedHospital);
      }

      // Refresh data
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding department: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDepartment(int departmentId, String name, String? category) async {
    try {
      final database = context.read<AppDatabase>();

      final updatedDepartment = Department(
        id: departmentId,
        name: name,
        category: category,
      );

      await database.updateDepartment(updatedDepartment);

      // Refresh data
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating department: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeDepartment(Department department) async {
    try {
      final database = context.read<AppDatabase>();

      // First, remove all doctors assigned to this department (cascade delete)
      final doctorsInDepartment = _doctors.where((doctor) => doctor.departmentId == department.id);
      for (final doctor in doctorsInDepartment) {
        await database.deleteDoctor(doctor.id);
      }

      // Remove department from database
      await database.deleteDepartment(department.id);

      // Remove department ID from hospital's departmentIds
      if (_hospital != null) {
        final currentIds = <int>[];
        if (_hospital!.departmentIds.isNotEmpty) {
          try {
            final ids = (json.decode(_hospital!.departmentIds) as List)
                .map((e) => int.parse(e.toString()))
                .toList();
            currentIds.addAll(ids);
          } catch (e) {
            // Handle JSON parsing errors
          }
        }

        currentIds.remove(department.id);

        final updatedHospital = _hospital!.copyWith(
          departmentIds: json.encode(currentIds),
        );

        await database.updateHospital(updatedHospital);
      }

      // Refresh data
      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.departmentRemovedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing department: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addDoctor(String name, int departmentId, String? level) async {
    try {
      final database = context.read<AppDatabase>();

      await database.createDoctor(
        DoctorsCompanion(
          name: Value(name),
          hospitalId: Value(widget.hospitalId),
          departmentId: Value(departmentId),
          level: Value(level),
        ),
      );

      // Refresh data
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding doctor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDoctor(int doctorId, String name, int departmentId, String? level) async {
    try {
      final database = context.read<AppDatabase>();

      final updatedDoctor = Doctor(
        id: doctorId,
        name: name,
        hospitalId: widget.hospitalId,
        departmentId: departmentId,
        level: level,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await database.updateDoctor(updatedDoctor);

      // Refresh data
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating doctor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeDoctor(Doctor doctor) async {
    try {
      final database = context.read<AppDatabase>();

      await database.deleteDoctor(doctor.id);

      // Refresh data
      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.doctorRemovedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing doctor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}