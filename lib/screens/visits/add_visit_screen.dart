import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'dart:async';

import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_bloc/form_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:visit_form_widget/visit_form.dart';
import 'package:visit_bloc/visit_bloc.dart';

class AddVisitScreen extends StatelessWidget {
  static const name = 'AddVisit';
  static const path = '/visits/add/:treatmentId';

  const AddVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AddVisitView();
  }
}

class _AddVisitView extends StatefulWidget {
  const _AddVisitView();

  @override
  State<_AddVisitView> createState() => _AddVisitViewState();
}

class _AddVisitViewState extends State<_AddVisitView> {
  bool _isSaving = false;
  late final VisitFormBloc _visitFormBloc;

  @override
  void initState() {
    super.initState();
    // Create the bloc once in initState to prevent multiple instances
    _visitFormBloc = VisitFormBloc(
      context.read<AppDatabase>(),
      visitBloc: context.read<VisitBloc>(),
    );
    
    // Set up field dependencies after the UI is completely stable to avoid dropdown assertion errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use proper async pattern instead of delays
      if (mounted) {
        // First, ensure the form is fully loaded
        _visitFormBloc.emitLoaded();
        
        // Then set up dependencies after the UI has processed the first update
        Timer.run(() {
          if (mounted) {
            AppLogger().d('Setting up field dependencies after UI is stable');
            _visitFormBloc.setupFieldDependencies();
          }
        });
      }
    });
  }

  void _saveVisit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_visitFormBloc.state.isValid()) {
        // Get treatmentId from route parameters
        final treatmentId = int.tryParse(GoRouterState.of(context).uri.pathSegments.last) ?? 0;

        // Extract form values from field blocs
        final category = _visitFormBloc.categoryFieldBloc.value!;
        final date = _visitFormBloc.dateFieldBloc.value!;
        final details = _visitFormBloc.detailsFieldBloc.value;
        final hospitalId = _visitFormBloc.hospitalFieldBloc.value;
        final departmentId = _visitFormBloc.departmentFieldBloc.value;
        final doctorId = _visitFormBloc.doctorFieldBloc.value;

        AppLogger().d('Saving new visit with ${_visitFormBloc.resources.length} resources');

        // Add visit through VisitBloc
        context.read<VisitBloc>().add(
              AddVisit(
                treatmentId: treatmentId,
                category: category,
                date: date,
                details: details.trim(),
                hospitalId: hospitalId,
                departmentId: departmentId,
                doctorId: doctorId,
              ),
            );

        // Wait for the visit to be created so we can get its ID
        final visitBloc = context.read<VisitBloc>();
        await for (final state in visitBloc.stream) {
          if (state is VisitOperationSuccess) {
            AppLogger().d('Visit created successfully, now saving resources');

            // Get the newly created visit ID
            // The VisitBloc should have the new visit in its loaded state
            if (visitBloc.state is VisitLoaded) {
              final visits = (visitBloc.state as VisitLoaded).visits;
              if (visits.isNotEmpty) {
                // Get the most recently created visit (should be the last one)
                final newVisit = visits.last;
                AppLogger().d('New visit ID: ${newVisit.id}');

                // Save resources if any were added
                if (_visitFormBloc.resources.isNotEmpty) {
                  try {
                    await _visitFormBloc.saveResourcesForVisit(newVisit.id);
                    AppLogger().d('Resources saved successfully for visit ${newVisit.id}');
                  } catch (e) {
                    AppLogger().e('Failed to save resources: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Visit saved but failed to save resources: $e'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }
              }
            }

            if (mounted) {
              context.pop();
            }
            break;
          } else if (state is VisitError) {
            AppLogger().e('Failed to create visit: ${state.message}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create visit: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            break;
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _visitFormBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      destinations: Destinations.navs(context),
      selectedIndex: Destinations.indexOf(const Key('Treatments'), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      body: (context) => SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(context.l10n.addVisit),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
              actions: [
                BlocBuilder<VisitFormBloc, FormBlocState<String, String>>(
                  bloc: _visitFormBloc,
                  builder: (context, state) {
                    return TextButton(
                      onPressed: state.isValid() && !_isSaving ? _saveVisit : null,
                      child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.save),
                    );
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverToBoxAdapter(
                child: BlocProvider.value(
                  value: _visitFormBloc,
                  child: BlocListener<VisitFormBloc, FormBlocState<String, String>>(
                    listener: (context, state) {
                      if (state is FormBlocLoading) {
                        // Show loading indicator if needed
                      } else if (state is FormBlocFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error loading form')),
                        );
                      }
                    },
                    child: VisitForm(
                      onSave: ({
                        required VisitCategory category,
                        required DateTime date,
                        required String details,
                        int? hospitalId,
                        int? departmentId,
                        int? doctorId,
                      }) async {
                        // This is handled by the save button in the AppBar
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      smallSecondaryBody: DmAdaptiveScaffold.emptyBuilder,
    );
  }
}