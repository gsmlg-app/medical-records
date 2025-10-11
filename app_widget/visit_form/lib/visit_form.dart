import 'dart:convert';

import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:hospital_bloc/hospital_bloc.dart';
import 'package:hospital_form_bloc/hospital_form_bloc.dart';
import 'package:hospital_form/hospital_form.dart';
import 'safe_dropdown_field_bloc_builder.dart';

/// {@template visit_form}
/// A reusable form widget for creating and editing visits.
/// {@endtemplate}
class VisitForm extends StatefulWidget {
  /// {@macro visit_form}
  const VisitForm({
    super.key,
    this.visit,
    required this.onSave,
    this.isLoading = false,
    this.formKey,
  });

  /// {@macro visit_form}
  final Visit? visit;

  /// {@macro visit_form}
  final bool isLoading;

  /// {@macro visit_form}
  final GlobalKey<FormState>? formKey;

  /// {@macro visit_form}
  final Future<void> Function({
    required VisitCategory category,
    required DateTime date,
    required String details,
    int? hospitalId,
    int? departmentId,
    int? doctorId,
  })
  onSave;

  @override
  State<VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends State<VisitForm> {
  @override
  void initState() {
    super.initState();
    // Form population is now handled internally in the VisitFormBloc
    // after items are loaded to avoid dropdown conflicts
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitFormBloc, FormBlocState<String, String>>(
      listener: (context, state) {
        // Handle submission success/failure
        if (state is FormBlocSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Visit saved successfully!')));
        } else if (state is FormBlocFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('An error occurred')));
        }
      },
      child: BlocBuilder<VisitFormBloc, FormBlocState<String, String>>(
        builder: (context, state) {
          // Show loading indicator while form data is being loaded
          if (state is FormBlocLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final visitFormBloc = context.read<VisitFormBloc>();

          return FormThemeProvider(
            theme: FormTheme(
              decorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            child: Form(
              key: widget.formKey ?? GlobalKey<FormState>(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visit Category
                  DropdownFieldBlocBuilder<VisitCategory>(
                    selectFieldBloc: visitFormBloc.categoryFieldBloc,
                    decoration: InputDecoration(
                      labelText: context.l10n.visitCategory,
                    ),
                    itemBuilder: (context, value) =>
                        FieldItem(child: Text(_formatCategoryName(value))),
                  ),
                  const SizedBox(height: 16),

                  // Visit Date
                  DateTimeFieldBlocBuilder(
                    dateTimeFieldBloc: visitFormBloc.dateFieldBloc,
                    format: DateFormat('yyyy-MM-dd'),
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    decoration: InputDecoration(
                      labelText: context.l10n.visitDate,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hospital with quick add
                  _HospitalDropdown(visitFormBloc: visitFormBloc),
                  const SizedBox(height: 16),

                  // Department with quick add
                  _DepartmentDropdown(visitFormBloc: visitFormBloc),
                  const SizedBox(height: 16),

                  // Doctor
                  SafeDropdownFieldBlocBuilder<int?>(
                    selectFieldBloc: visitFormBloc.doctorFieldBloc,
                    decoration: InputDecoration(
                      labelText: 'Doctor',
                      hintText: 'Select a doctor',
                    ),
                    itemBuilder: (context, value) {
                      if (value == null) {
                        return Text(
                          'None',
                          style: TextStyle(color: Colors.grey[600]),
                        );
                      }
                      final doctors = visitFormBloc.availableDoctors;
                      final doctor = doctors.cast<Doctor?>().firstWhere(
                        (d) => d?.id == value,
                        orElse: () => null,
                      );
                      return Text(doctor?.name ?? 'Unknown');
                    },
                  ),
                  const SizedBox(height: 16),

                  // Visit Details (optional)
                  TextFieldBlocBuilder(
                    textFieldBloc: visitFormBloc.detailsFieldBloc,
                    decoration: InputDecoration(
                      labelText: context.l10n.visitDetails,
                      hintText: 'Enter optional visit details...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCategoryName(VisitCategory category) {
    switch (category) {
      case VisitCategory.outpatient:
        return 'Outpatient';
      case VisitCategory.inpatient:
        return 'Inpatient';
      default:
        return category.toString();
    }
  }
}

/// Custom hospital dropdown with quick add functionality
class _HospitalDropdown extends StatelessWidget {
  const _HospitalDropdown({required this.visitFormBloc});

  final VisitFormBloc visitFormBloc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Hospital dropdown using DropdownFieldBlocBuilder
        Expanded(
          child: DropdownFieldBlocBuilder<int?>(
            selectFieldBloc: visitFormBloc.hospitalFieldBloc,
            decoration: InputDecoration(
              labelText: 'Hospital',
              hintText: 'Select a hospital',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            itemBuilder: (context, value) {
              if (value == null) {
                return const FieldItem(
                  child: Text('None', style: TextStyle(color: Colors.grey)),
                );
              }
              final hospital = visitFormBloc.availableHospitals
                  .where((h) => h.id == value)
                  .firstOrNull;
              return FieldItem(
                child: Text(hospital?.name ?? 'Unknown Hospital'),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Add hospital button
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddHospitalDialog(context),
          tooltip: 'Add Hospital',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  void _showAddHospitalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => HospitalFormBloc(),
          ),
          BlocProvider.value(
            value: context.read<HospitalBloc>(),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<HospitalFormBloc, HospitalFormState>(
              listener: (context, formState) {
                if (formState is HospitalFormSubmissionInProgress) {
                  // Extract form data and trigger hospital save
                  final formData = context.read<HospitalFormBloc>().formData;
                  context.read<HospitalBloc>().add(
                    AddHospital(
                      name: formData['name']!,
                      address: formData['address'],
                      type: formData['type'],
                      level: formData['level'],
                    ),
                  );
                }
              },
            ),
            BlocListener<HospitalBloc, HospitalState>(
              listener: (context, state) async {
                if (state is HospitalOperationSuccess) {
                  // Notify form bloc of success
                  context.read<HospitalFormBloc>().handleSubmissionSuccess();

                  // Close the dialog
                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );

                  // Add a small delay to ensure database write is completed
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Refresh the hospital list to include the newly added hospital
                  // and automatically select the newly created hospital
                  final visitFormBloc = context.read<VisitFormBloc>();
                  AppLogger().d('About to refresh hospitals...');
                  AppLogger().d('Current hospital count: ${visitFormBloc.availableHospitals.length}');
                  AppLogger().d('Current hospital field items: ${visitFormBloc.hospitalFieldBloc.state.items.length}');
                  await visitFormBloc.refreshHospitals(selectNewest: true);
                  AppLogger().d('Hospital refresh completed');
                  AppLogger().d('New hospital count: ${visitFormBloc.availableHospitals.length}');
                  AppLogger().d('New hospital field items: ${visitFormBloc.hospitalFieldBloc.state.items.length}');
                  AppLogger().d('Selected hospital value: ${visitFormBloc.hospitalFieldBloc.value}');
                } else if (state is HospitalError) {
                  // Notify form bloc of failure
                  context.read<HospitalFormBloc>().handleSubmissionFailure(state.message);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: AlertDialog(
            title: const Text('Add Hospital'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: HospitalFormWidget(
                  isEditMode: false,
                  onSave: () {
                    // Save is triggered by the BlocListener above
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom department dropdown with quick add functionality
class _DepartmentDropdown extends StatelessWidget {
  const _DepartmentDropdown({required this.visitFormBloc});

  final VisitFormBloc visitFormBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VisitFormBloc, FormBlocState<String, String>>(
      builder: (context, state) {
        final hospitalId = visitFormBloc.hospitalFieldBloc.value;
        final canAddDepartment = hospitalId != null;

        // Filter departments by selected hospital
        List<Department> filteredDepartments =
            visitFormBloc.availableDepartments;
        if (hospitalId != null) {
          // Find the hospital and get its department IDs
          final hospital = visitFormBloc.availableHospitals
              .where((h) => h.id == hospitalId)
              .firstOrNull;
          if (hospital != null && hospital.departmentIds.isNotEmpty) {
            try {
              // Parse JSON array of department IDs
              final departmentIds =
                  (json.decode(hospital.departmentIds) as List)
                      .map((e) => int.parse(e.toString()))
                      .toList();

              filteredDepartments = filteredDepartments
                  .where((d) => departmentIds.contains(d.id))
                  .toList();
            } catch (e) {
              // If parsing fails, show no departments
              filteredDepartments = [];
            }
          } else {
            // Hospital has no departments
            filteredDepartments = [];
          }
        }

        return DropdownButtonFormField<int?>(
          value: visitFormBloc.departmentFieldBloc.value,
          decoration: InputDecoration(
            labelText: 'Department',
            hintText: canAddDepartment
                ? 'Select a department or add new'
                : 'Select a hospital first',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: canAddDepartment
                ? IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddDepartmentDialog(context),
                    tooltip: 'Add Department',
                  )
                : null,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('None', style: TextStyle(color: Colors.grey)),
            ),
            ...filteredDepartments.map((department) {
              return DropdownMenuItem<int?>(
                value: department.id,
                child: Text(department.name),
              );
            }),
            if (canAddDepartment)
              const DropdownMenuItem<int?>(
                value: -1, // Special value for "Add Department"
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Add Department',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value == -1) {
              // "Add Department" selected
              _showAddDepartmentDialog(context);
            } else {
              visitFormBloc.departmentFieldBloc.updateValue(value);
            }
          },
        );
      },
    );
  }

  void _showAddDepartmentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Department Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Cardiology, Neurology',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a department name'),
                  ),
                );
                return;
              }

              final category = categoryController.text.trim().isEmpty
                  ? null
                  : categoryController.text.trim();

              Navigator.of(context).pop();

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Adding department...'),
                    ],
                  ),
                ),
              );

              try {
                final success = await visitFormBloc.quickAddDepartment(
                  name,
                  category: category,
                );
                Navigator.of(context).pop(); // Remove loading dialog

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Department "$name" added successfully'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add department')),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop(); // Remove loading dialog
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
