import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  }) onSave;

  @override
  State<VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends State<VisitForm> {
  @override
  void initState() {
    super.initState();

    // Load form data
    context.read<VisitFormBloc>().add(LoadFormData());

    // Populate form with existing visit data if editing
    if (widget.visit != null) {
      // Schedule population after data is loaded
      Future.delayed(Duration.zero, () {
        context.read<VisitFormBloc>().add(
              VisitFormPopulate({
                'category': widget.visit!.category,
                'date': widget.visit!.date,
                'details': widget.visit!.details,
                'hospitalId': widget.visit!.hospitalId,
                'departmentId': widget.visit!.departmentId,
                'doctorId': widget.visit!.doctorId,
                'informations': widget.visit!.informations,
              }),
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitFormBloc, VisitFormState>(
      listener: (context, state) {
        // Handle any state changes that require UI actions
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      child: Form(
        key: widget.formKey ?? GlobalKey<FormState>(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visit Category
            BlocBuilder<VisitFormBloc, VisitFormState>(
              builder: (context, state) {
                return DropdownButtonFormField<VisitCategory>(
                  value: state.category,
                  decoration: InputDecoration(
                    labelText: context.l10n.visitCategory,
                    border: const OutlineInputBorder(),
                  ),
                  items: VisitCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_formatCategoryName(category)),
                    );
                  }).toList(),
                  onChanged: (category) {
                    if (category != null) {
                      context.read<VisitFormBloc>().add(
                            VisitFormCategoryChanged(category),
                          );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Visit Date
            BlocBuilder<VisitFormBloc, VisitFormState>(
              builder: (context, state) {
                return ListTile(
                  title: Text(context.l10n.visitDate),
                  subtitle: Text(
                    state.date != null
                        ? _formatDate(state.date!)
                        : context.l10n.selectDate,
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(),
                );
              },
            ),
            const SizedBox(height: 16),

            // Visit Details
            TextFormField(
              initialValue: widget.visit?.details,
              decoration: InputDecoration(
                labelText: context.l10n.visitDetails,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.fieldRequired;
                }
                return null;
              },
              onChanged: (value) {
                context.read<VisitFormBloc>().add(
                      VisitFormDetailsChanged(value),
                    );
              },
            ),

            // Optional fields section
            const SizedBox(height: 24),
            Text(
              'Optional Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Hospital Selector
            BlocBuilder<VisitFormBloc, VisitFormState>(
              builder: (context, state) {
                return DropdownButtonFormField<int?>(
                  value: state.hospitalId,
                  decoration: InputDecoration(
                    labelText: 'Hospital',
                    border: const OutlineInputBorder(),
                    helperText: 'Optional',
                    suffixIcon: state.isLoadingHospitals
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  items: state.availableHospitals.map((hospital) {
                    return DropdownMenuItem<int?>(
                      value: hospital.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(hospital.name),
                          if (hospital.type != null)
                            Text(
                              hospital.type!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (hospitalId) {
                    context.read<VisitFormBloc>().add(
                      VisitFormHospitalIdChanged(hospitalId),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Department Selector
            BlocBuilder<VisitFormBloc, VisitFormState>(
              builder: (context, state) {
                return DropdownButtonFormField<int?>(
                  value: state.departmentId,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: const OutlineInputBorder(),
                    helperText: 'Optional',
                    suffixIcon: state.isLoadingDepartments
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  items: state.availableDepartments.map((department) {
                    return DropdownMenuItem<int?>(
                      value: department.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(department.name),
                          if (department.category != null)
                            Text(
                              department.category!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (departmentId) {
                    context.read<VisitFormBloc>().add(
                      VisitFormDepartmentIdChanged(departmentId),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Doctor Selector
            BlocBuilder<VisitFormBloc, VisitFormState>(
              builder: (context, state) {
                return DropdownButtonFormField<int?>(
                  value: state.doctorId,
                  decoration: InputDecoration(
                    labelText: 'Doctor',
                    border: const OutlineInputBorder(),
                    helperText: 'Optional',
                    suffixIcon: state.isLoadingDoctors
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  items: state.availableDoctors.map((doctor) {
                    return DropdownMenuItem<int?>(
                      value: doctor.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(doctor.name),
                          if (doctor.level != null)
                            Text(
                              doctor.level!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (doctorId) {
                    context.read<VisitFormBloc>().add(
                      VisitFormDoctorIdChanged(doctorId),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: context.read<VisitFormBloc>().state.date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      context.read<VisitFormBloc>().add(
            VisitFormDateChanged(picked),
          );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  /// Validates and saves the form
  Future<bool> saveForm() async {
    final formState = widget.formKey?.currentState;
    if (formState?.validate() ?? false) {
      final blocState = context.read<VisitFormBloc>().state;

      if (!blocState.isFormValid) {
        if (!blocState.isDateValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a visit date')),
          );
          return false;
        }
        if (!blocState.isDetailsValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter visit details')),
          );
          return false;
        }
        return false;
      }

      try {
        await widget.onSave(
          category: blocState.category,
          date: blocState.date!,
          details: blocState.details.trim(),
          hospitalId: blocState.hospitalId,
          departmentId: blocState.departmentId,
          doctorId: blocState.doctorId,
          informations: blocState.informations,
        );
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        return false;
      }
    }
    return false;
  }

  /// Public method to trigger form validation and save
  Future<bool> validateAndSave() async {
    return await saveForm();
  }
}