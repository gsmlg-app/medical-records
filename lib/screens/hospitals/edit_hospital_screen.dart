import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_bloc/hospital_bloc.dart';
import 'package:hospital_form_bloc/hospital_form_bloc.dart';
import 'package:hospital_form/hospital_form.dart';
import 'package:medical_records/destination.dart';

class EditHospitalScreen extends StatefulWidget {
  static const name = 'EditHospital';
  static const path = '/hospitals/:id/edit';

  final int hospitalId;

  const EditHospitalScreen({
    super.key,
    required this.hospitalId,
  });

  @override
  State<EditHospitalScreen> createState() => _EditHospitalScreenState();
}

class _EditHospitalScreenState extends State<EditHospitalScreen> {
  Hospital? _hospital;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHospital();
  }

  Future<void> _fetchHospital() async {
    try {
      final database = context.read<AppDatabase>();
      final hospital = await database.getHospitalById(widget.hospitalId);
      if (hospital != null) {
        setState(() {
          _hospital = hospital;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading hospital: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        body: Center(
          child: Text('Hospital not found'),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HospitalFormBloc()
            ..add(
              InitializeForm(
                name: _hospital!.name,
                address: _hospital!.address,
                type: _hospital!.type,
                level: _hospital!.level,
              ),
            ),
        ),
      ],
      child: BlocListener<HospitalFormBloc, HospitalFormState>(
        listener: (context, formState) {
          if (formState is HospitalFormSubmissionInProgress) {
            // Extract form data and trigger hospital update
            final formData = context.read<HospitalFormBloc>().formData;
            context.read<HospitalBloc>().add(
              UpdateHospital(
                id: _hospital!.id,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              context.pop();
            } else if (state is HospitalError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
              // Reset form to allow user to try again
              context.read<HospitalFormBloc>().add(
                InitializeForm(
                  name: _hospital!.name,
                  address: _hospital!.address,
                  type: _hospital!.type,
                  level: _hospital!.level,
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
                    title: Text(context.l10n.editHospital),
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
                            initialName: _hospital!.name,
                            initialAddress: _hospital!.address,
                            initialType: _hospital!.type,
                            initialLevel: _hospital!.level,
                            isEditMode: true,
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