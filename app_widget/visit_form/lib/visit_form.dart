import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
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
    String? informations,
  }) onSave;

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Visit saved successfully!')),
          );
        } else if (state is FormBlocFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred')),
          );
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    itemBuilder: (context, value) => FieldItem(
                      child: Text(_formatCategoryName(value)),
                    ),
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

                  // Visit Details
                  TextFieldBlocBuilder(
                    textFieldBloc: visitFormBloc.detailsFieldBloc,
                    decoration: InputDecoration(
                      labelText: context.l10n.visitDetails,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                   // Use safe dropdown builders that handle initialization properly
                   // Hospital
                   SafeDropdownFieldBlocBuilder<int?>(
                     selectFieldBloc: visitFormBloc.hospitalFieldBloc,
                     decoration: InputDecoration(
                       labelText: 'Hospital',
                       hintText: 'Select a hospital',
                     ),
                     itemBuilder: (context, value) {
                       if (value == null) {
                         return Text('None', style: TextStyle(color: Colors.grey[600]));
                       }
                       final hospitals = visitFormBloc.availableHospitals;
                       final hospital = hospitals.cast<Hospital?>().firstWhere(
                         (h) => h?.id == value,
                         orElse: () => null,
                       );
                       return Text(hospital?.name ?? 'Unknown');
                     },
                   ),
                   const SizedBox(height: 16),

                   // Department
                   SafeDropdownFieldBlocBuilder<int?>(
                     selectFieldBloc: visitFormBloc.departmentFieldBloc,
                     decoration: InputDecoration(
                       labelText: 'Department',
                       hintText: 'Select a department',
                     ),
                     itemBuilder: (context, value) {
                       if (value == null) {
                         return Text('None', style: TextStyle(color: Colors.grey[600]));
                       }
                       final departments = visitFormBloc.availableDepartments;
                       final department = departments.cast<Department?>().firstWhere(
                         (d) => d?.id == value,
                         orElse: () => null,
                       );
                       return Text(department?.name ?? 'Unknown');
                     },
                   ),
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
                         return Text('None', style: TextStyle(color: Colors.grey[600]));
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

                  // Additional Informations
                  TextFieldBlocBuilder(
                    textFieldBloc: visitFormBloc.informationsFieldBloc,
                    decoration: InputDecoration(
                      labelText: 'Additional Information',
                      hintText: 'Enter any additional notes...',
                    ),
                    maxLines: 2,
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