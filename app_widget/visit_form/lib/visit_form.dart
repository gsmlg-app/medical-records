import 'package:app_database/app_database.dart';
import 'dart:async';

import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:hospital_bloc/hospital_bloc.dart';
import 'package:hospital_form_bloc/hospital_form_bloc.dart';
import 'package:hospital_form/hospital_form.dart';
import 'resources_section_wrapper.dart';
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
              child: SingleChildScrollView(
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

                    // Doctor with quick add
                    _DoctorDropdown(visitFormBloc: visitFormBloc),
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
                    const SizedBox(height: 24),

                    // Resources section
                    ResourcesSectionWrapper(visitFormBloc: visitFormBloc),
                  ],
                ),
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
        // Hospital dropdown using DropdownFieldBlocBuilder with BlocBuilder wrapper
        Expanded(
          child: BlocBuilder<VisitFormBloc, FormBlocState<String, String>>(
            builder: (context, state) {
              // Force rebuild when VisitFormBloc state changes
              // This ensures the dropdown updates when hospitals are refreshed
              return SafeDropdownFieldBlocBuilder<int?>(
                key: ValueKey(
                  'hospital_dropdown_${visitFormBloc.availableHospitals.length}',
                ),
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
            backgroundColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  void _showAddHospitalDialog(BuildContext context) {
    // Capture the VisitFormBloc reference from the parent context BEFORE showing the dialog
    // This is critical because the dialog creates a new context that doesn't include VisitFormBloc
    final capturedVisitFormBloc = visitFormBloc;

    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => HospitalFormBloc()),
          BlocProvider.value(value: context.read<HospitalBloc>()),
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
                  Navigator.of(dialogContext).pop();

                  // Show success message
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(state.message)));

                  // Use a microtask to ensure database write is completed
                  final completer = Completer<void>();
                  Timer.run(() => completer.complete());
                  await completer.future;

                  // Refresh the hospital list to include the newly added hospital
                  // and automatically select the newly created hospital
                  // Use the captured VisitFormBloc reference instead of trying to read from dialog context
                  AppLogger().d('About to refresh hospitals...');
                  AppLogger().d(
                    'Current hospital count: ${capturedVisitFormBloc.availableHospitals.length}',
                  );
                  AppLogger().d(
                    'Current hospital field items: ${capturedVisitFormBloc.hospitalFieldBloc.state.items.length}',
                  );
                  await capturedVisitFormBloc.refreshHospitals(selectNewest: true);
                  AppLogger().d('Hospital refresh completed');
                  AppLogger().d(
                    'New hospital count: ${capturedVisitFormBloc.availableHospitals.length}',
                  );
                  AppLogger().d(
                    'New hospital field items: ${capturedVisitFormBloc.hospitalFieldBloc.state.items.length}',
                  );
                  AppLogger().d(
                    'Selected hospital value: ${capturedVisitFormBloc.hospitalFieldBloc.value}',
                  );
                } else if (state is HospitalError) {
                  // Notify form bloc of failure
                  context.read<HospitalFormBloc>().handleSubmissionFailure(
                    state.message,
                  );

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
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
                    Navigator.of(dialogContext).pop();
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
    return Row(
      children: [
        // Department dropdown using DropdownFieldBlocBuilder with BlocBuilder wrapper
        Expanded(
          child: BlocBuilder<VisitFormBloc, FormBlocState<String, String>>(
            builder: (context, state) {
              final hospitalId = visitFormBloc.hospitalFieldBloc.value;
              final canAddDepartment = hospitalId != null;

              return SafeDropdownFieldBlocBuilder<int?>(
                key: ValueKey(
                  'department_dropdown_${hospitalId}_${visitFormBloc.availableDepartments.length}',
                ),
                selectFieldBloc: visitFormBloc.departmentFieldBloc,
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
                ),
                itemBuilder: (context, value) {
                  if (value == null) {
                    return const FieldItem(
                      child: Text('None', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  // The department filtering is now handled in the VisitFormBloc
                  // The field items only contain departments valid for the selected hospital
                  final department = visitFormBloc.availableDepartments
                      .where((d) => d.id == value)
                      .firstOrNull;
                  return FieldItem(
                    child: Text(department?.name ?? 'Unknown Department'),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Add department button - listen to hospital field changes
        BlocBuilder<SelectFieldBloc<int?, dynamic>, SelectFieldBlocState<int?, dynamic>>(
          bloc: visitFormBloc.hospitalFieldBloc,
          builder: (context, hospitalState) {
            final hospitalId = hospitalState.value;
            final canAddDepartment = hospitalId != null;

            return IconButton(
              icon: const Icon(Icons.add),
              onPressed: canAddDepartment
                  ? () => _showAddDepartmentDialog(context)
                  : null,
              tooltip: 'Add Department',
              style: IconButton.styleFrom(
                backgroundColor: canAddDepartment
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
            );
          },
        ),
      ],
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

              // Capture navigator and scaffold messenger before async gap
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop();

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
                navigator.pop(); // Remove loading dialog

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Department "$name" added successfully'),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Failed to add department')),
                  );
                }
              } catch (e) {
                navigator.pop(); // Remove loading dialog
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Custom doctor dropdown with quick add functionality
class _DoctorDropdown extends StatelessWidget {
  const _DoctorDropdown({required this.visitFormBloc});

  final VisitFormBloc visitFormBloc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Doctor dropdown using SafeDropdownFieldBlocBuilder with BlocBuilder wrapper
        Expanded(
          child: BlocBuilder<VisitFormBloc, FormBlocState<String, String>>(
            builder: (context, state) {
              final hospitalId = visitFormBloc.hospitalFieldBloc.value;
              final departmentId = visitFormBloc.departmentFieldBloc.value;
              final canAddDoctor = hospitalId != null && departmentId != null;

              return SafeDropdownFieldBlocBuilder<int?>(
                key: ValueKey(
                  'doctor_dropdown_${hospitalId}_${departmentId}_${visitFormBloc.availableDoctors.length}',
                ),
                selectFieldBloc: visitFormBloc.doctorFieldBloc,
                decoration: InputDecoration(
                  labelText: 'Doctor',
                  hintText: canAddDoctor
                      ? 'Select a doctor or add new'
                      : 'Select hospital and department first',
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

                  // The doctor filtering is now handled in the VisitFormBloc
                  // The field items only contain doctors valid for the selected hospital and department
                  final doctor = visitFormBloc.availableDoctors
                      .where((d) => d.id == value)
                      .firstOrNull;
                  return FieldItem(
                    child: Text(doctor?.name ?? 'Unknown Doctor'),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Add doctor button - listen to both hospital and department field changes
        BlocBuilder<SelectFieldBloc<int?, dynamic>, SelectFieldBlocState<int?, dynamic>>(
          bloc: visitFormBloc.hospitalFieldBloc,
          builder: (context, hospitalState) {
            return BlocBuilder<SelectFieldBloc<int?, dynamic>, SelectFieldBlocState<int?, dynamic>>(
              bloc: visitFormBloc.departmentFieldBloc,
              builder: (context, departmentState) {
                final hospitalId = hospitalState.value;
                final departmentId = departmentState.value;
                final canAddDoctor = hospitalId != null && departmentId != null;

                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: canAddDoctor
                      ? () => _showAddDoctorDialog(context)
                      : null,
                  tooltip: 'Add Doctor',
                  style: IconButton.styleFrom(
                    backgroundColor: canAddDoctor
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddDoctorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final titleController = TextEditingController();
    final specialtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Dr., Prof., MD',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: specialtyController,
              decoration: const InputDecoration(
                labelText: 'Specialty (Optional)',
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
                  const SnackBar(content: Text('Please enter a doctor name')),
                );
                return;
              }

              final title = titleController.text.trim().isEmpty
                  ? null
                  : titleController.text.trim();
              final specialty = specialtyController.text.trim().isEmpty
                  ? null
                  : specialtyController.text.trim();

              // Capture navigator and scaffold messenger before async gap
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop();

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Adding doctor...'),
                    ],
                  ),
                ),
              );

              try {
                final success = await visitFormBloc.quickAddDoctor(
                  name,
                  title: title,
                  specialty: specialty,
                );
                navigator.pop(); // Remove loading dialog

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Doctor "$name" added successfully'),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Failed to add doctor')),
                  );
                }
              } catch (e) {
                navigator.pop(); // Remove loading dialog
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
