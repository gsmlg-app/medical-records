import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_bloc/hospital_bloc.dart';
import 'package:hospital_form_bloc/hospital_form_bloc.dart';
import 'package:hospital_form/hospital_form.dart';
import 'package:medical_records/destination.dart';

class AddHospitalScreen extends StatelessWidget {
  static const name = 'AddHospital';
  static const path = '/hospitals/add';

  const AddHospitalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HospitalFormBloc(),
        ),
      ],
      child: BlocListener<HospitalFormBloc, HospitalFormState>(
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
        child: BlocListener<HospitalBloc, HospitalState>(
          listener: (context, state) {
            if (state is HospitalOperationSuccess) {
              // Notify form bloc of success
              context.read<HospitalFormBloc>().handleSubmissionSuccess();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              context.pop();
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
          child: AppAdaptiveScaffold(
            selectedIndex: Destinations.indexOf(const Key('Hospitals'), context),
            onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
            destinations: Destinations.navs(context),
            body: (context) => SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: Text(context.l10n.addHospital),
                    floating: true,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: HospitalFormWidget(
                            isEditMode: false,
                            onSave: () {
                              // Save is triggered by the BlocListener above
                            },
                            onCancel: () {
                              context.pop();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}