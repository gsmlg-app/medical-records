import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:treatment_form_bloc/treatment_form_bloc.dart';

/// {@template treatment_form}
/// A reusable form widget for creating and editing treatments.
/// {@endtemplate}
class TreatmentForm extends StatefulWidget {
  /// {@macro treatment_form}
  const TreatmentForm({
    super.key,
    this.treatment,
    required this.onSave,
    this.isLoading = false,
    this.formKey,
  });

  /// {@macro treatment_form}
  final Treatment? treatment;

  /// {@macro treatment_form}
  final bool isLoading;

  /// {@macro treatment_form}
  final GlobalKey<FormState>? formKey;

  /// {@macro treatment_form}
  final Future<void> Function({
    required String title,
    required String diagnosis,
    required DateTime startDate,
    DateTime? endDate,
  })? onSave;

  @override
  State<TreatmentForm> createState() => _TreatmentFormState();
}

class _TreatmentFormState extends State<TreatmentForm> {
  @override
  void initState() {
    super.initState();
    // Populate form with existing treatment data if editing
    if (widget.treatment != null) {
      context.read<TreatmentFormBloc>().add(
            TreatmentFormPopulate(widget.treatment!),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TreatmentFormBloc, TreatmentFormState>(
      listener: (context, state) {
        // Handle any state changes that require UI actions
        if (state.status == TreatmentFormStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'An error occurred')),
          );
        }
      },
      child: Form(
        key: widget.formKey ?? GlobalKey<FormState>(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: widget.treatment?.title,
              decoration: InputDecoration(
                labelText: context.l10n.treatmentTitle,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.fieldRequired;
                }
                return null;
              },
              onChanged: (value) {
                context.read<TreatmentFormBloc>().add(
                      TreatmentFormTitleChanged(value),
                    );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.treatment?.diagnosis,
              decoration: InputDecoration(
                labelText: context.l10n.diagnosis,
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
                context.read<TreatmentFormBloc>().add(
                      TreatmentFormDiagnosisChanged(value),
                    );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<TreatmentFormBloc, TreatmentFormState>(
              builder: (context, state) {
                return ListTile(
                  title: Text(context.l10n.startDate),
                  subtitle: Text(
                    state.startDate != null
                        ? _formatDate(state.startDate!)
                        : context.l10n.selectDate,
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(isStartDate: true),
                );
              },
            ),
            const SizedBox(height: 8),
            BlocBuilder<TreatmentFormBloc, TreatmentFormState>(
              builder: (context, state) {
                return ListTile(
                  title: Text(context.l10n.endDate),
                  subtitle: Text(
                    state.endDate != null
                        ? _formatDate(state.endDate!)
                        : context.l10n.optional,
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(isStartDate: false),
                  enabled: state.startDate != null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? context.read<TreatmentFormBloc>().state.startDate ?? DateTime.now()
          : context.read<TreatmentFormBloc>().state.endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      if (isStartDate) {
        context.read<TreatmentFormBloc>().add(
              TreatmentFormStartDateChanged(picked),
            );
      } else {
        context.read<TreatmentFormBloc>().add(
              TreatmentFormEndDateChanged(picked),
            );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Validates and saves the form
  Future<bool> saveForm() async {
    final formState = widget.formKey?.currentState;
    if (formState?.validate() ?? false) {
      final blocState = context.read<TreatmentFormBloc>().state;

      if (!blocState.isFormValid) {
        if (!blocState.isStartDateValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.fieldRequired)),
          );
          return false;
        }
        return false;
      }

      try {
        await widget.onSave?.call(
          title: blocState.title.trim(),
          diagnosis: blocState.diagnosis.trim(),
          startDate: blocState.startDate!,
          endDate: blocState.endDate,
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