import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';

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
    String? informations,
  })
  onSave;

  @override
  State<VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends State<VisitForm> {
  @override
  void initState() {
    super.initState();

    // Debug: Log if visit is provided
    AppLogger().d(
      'VisitForm initState - widget.visit: ${widget.visit?.toJson()}',
    );

    // Populate form with existing visit data after initialization
    if (widget.visit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppLogger().d('VisitForm - Populating form with visit data');
          context.read<VisitFormBloc>().add(
            VisitFormEventPopulate(widget.visit!),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger().d('VisitForm build() called');
    return BlocListener<VisitFormBloc, FormBlocState<String, String>>(
      listener: (context, state) {
        // Handle submission success/failure
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visit saved successfully!')),
          );
        } else if (state.isFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failureResponse ?? 'An error occurred'),
            ),
          );
        }
      },
      child: Form(
        key: widget.formKey ?? GlobalKey<FormState>(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visit Category
            DropdownFieldBlocBuilder<VisitCategory>(
              selectFieldBloc: context.read<VisitFormBloc>().categoryFieldBloc,
              decoration: InputDecoration(
                labelText: context.l10n.visitCategory,
                border: const OutlineInputBorder(),
              ),
              itemBuilder: (context, value) => DropdownMenuItem(
                value: value,
                child: Text(_formatCategoryName(value)),
              ),
            ),
            const SizedBox(height: 16),

            // Visit Date
            DateTimeFieldBlocBuilder(
              inputFieldBloc: context.read<VisitFormBloc>().dateFieldBloc,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDate: DateTime.now(),
              format: (date) => _formatDate(date),
              fieldBuilder: (context, value) {
                return ListTile(
                  title: Text(context.l10n.visitDate),
                  subtitle: Text(
                    value != null
                        ? _formatDate(value)
                        : context.l10n.selectDate,
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: value ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selectedDate != null) {
                      context.read<VisitFormBloc>().dateFieldBloc.updateValue(
                        selectedDate,
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Visit Details
            TextFieldBlocBuilder(
              textFieldBloc: context.read<VisitFormBloc>().detailsFieldBloc,
              decoration: InputDecoration(
                labelText: context.l10n.visitDetails,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Optional fields section
            Text(
              'Optional Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Hospital Selector
            DropdownFieldBlocBuilder<int?>(
              selectFieldBloc: context.read<VisitFormBloc>().hospitalFieldBloc,
              decoration: InputDecoration(
                labelText: 'Hospital',
                border: const OutlineInputBorder(),
                helperText: 'Optional',
              ),
              itemBuilder: (context, hospitalId) {
                if (hospitalId == null) {
                  return const DropdownMenuItem(
                    value: null,
                    child: Text('Select Hospital'),
                  );
                }

                final hospital = context
                    .read<VisitFormBloc>()
                    .availableHospitals
                    .where((h) => h.id == hospitalId)
                    .firstOrNull;

                if (hospital == null) return null;

                return DropdownMenuItem(
                  value: hospitalId,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(hospital.name),
                      if (hospital.type != null)
                        Text(
                          hospital.type!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                );
              },
              onChanged: (hospitalId) {
                // Load departments for selected hospital
                context.read<VisitFormBloc>().add(
                  VisitFormEventLoadDepartmentsForHospital(hospitalId),
                );
              },
            ),
            const SizedBox(height: 16),

            // Department Selector
            DropdownFieldBlocBuilder<int?>(
              selectFieldBloc: context
                  .read<VisitFormBloc>()
                  .departmentFieldBloc,
              decoration: InputDecoration(
                labelText: 'Department',
                border: const OutlineInputBorder(),
                helperText: 'Optional',
              ),
              itemBuilder: (context, departmentId) {
                if (departmentId == null) {
                  return const DropdownMenuItem(
                    value: null,
                    child: Text('Select Department'),
                  );
                }

                final department = context
                    .read<VisitFormBloc>()
                    .availableDepartments
                    .where((d) => d.id == departmentId)
                    .firstOrNull;

                if (department == null) return null;

                return DropdownMenuItem(
                  value: departmentId,
                  child: Text(department.name),
                );
              },
              onChanged: (departmentId) {
                final hospitalId = context
                    .read<VisitFormBloc>()
                    .hospitalFieldBloc
                    .value;
                // Load doctors for selected hospital and department
                context.read<VisitFormBloc>().add(
                  VisitFormEventLoadDoctorsForHospitalAndDepartment(
                    hospitalId,
                    departmentId,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Doctor Selector
            DropdownFieldBlocBuilder<int?>(
              selectFieldBloc: context.read<VisitFormBloc>().doctorFieldBloc,
              decoration: InputDecoration(
                labelText: 'Doctor',
                border: const OutlineInputBorder(),
                helperText: 'Optional',
              ),
              itemBuilder: (context, doctorId) {
                if (doctorId == null) {
                  return const DropdownMenuItem(
                    value: null,
                    child: Text('Select Doctor'),
                  );
                }

                final doctor = context
                    .read<VisitFormBloc>()
                    .availableDoctors
                    .where((d) => d.id == doctorId)
                    .firstOrNull;

                if (doctor == null) return null;

                return DropdownMenuItem(
                  value: doctorId,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(doctor.name),
                      if (doctor.level != null)
                        Text(
                          doctor.level!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Additional Information
            TextFieldBlocBuilder(
              textFieldBloc: context
                  .read<VisitFormBloc>()
                  .informationsFieldBloc,
              decoration: InputDecoration(
                labelText: 'Additional Information',
                border: const OutlineInputBorder(),
                helperText: 'Optional',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCategoryName(VisitCategory category) {
    switch (category) {
      case VisitCategory.outpatient:
        return 'Outpatient';
      case VisitCategory.inpatient:
        return 'Inpatient';
      case VisitCategory.emergency:
        return 'Emergency';
      case VisitCategory.telemedicine:
        return 'Telemedicine';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
