import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
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

class EditVisitScreen extends StatelessWidget {
  static const name = 'EditVisit';
  static const path = '/visits/edit/:id';

  const EditVisitScreen({super.key, required this.visitId});

  final int visitId;

  @override
  Widget build(BuildContext context) {
    return _EditVisitView(visitId: visitId);
  }
}

class _EditVisitView extends StatefulWidget {
  const _EditVisitView({required this.visitId});

  final int visitId;

  @override
  State<_EditVisitView> createState() => _EditVisitViewState();
}

class _EditVisitViewState extends State<_EditVisitView> {
  Visit? _visit;
  bool _isLoaded = false;
  bool _isSaving = false;
  int? _visitId;
  late final VisitFormBloc _visitFormBloc;

  @override
  void initState() {
    super.initState();
    // Create the bloc once in initState to prevent multiple instances
    _visitFormBloc = VisitFormBloc(
      context.read<AppDatabase>(),
      visitBloc: context.read<VisitBloc>(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visitId == null) {
      // Use the visitId passed from the widget
      _visitId = widget.visitId;
      _loadVisit();
    }
  }

  void _loadVisit() {
    if (_visitId == null) return;
    
    final state = context.read<VisitBloc>().state;
    if (state is VisitLoaded) {
      try {
        _visit = state.visits.firstWhere(
          (v) => v.id == _visitId,
        );
      } catch (e) {
        // Create a dummy visit for testing if none exists
        AppLogger().w('No visit found with ID $_visitId, creating test visit');
        _visit = Visit(
          id: _visitId!,
          treatmentId: 1,
          category: VisitCategory.outpatient.value,
          date: DateTime.now(),
          details: 'Test visit details for editing',
          hospitalId: null,
          departmentId: null,
          doctorId: null,

          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Debug: Print visit data
      AppLogger().d('Loaded visit for editing: ${_visit?.toJson()}');

      // Populate the form with visit data after it's loaded
      if (_visit != null) {
        _visitFormBloc.visitToEdit = _visit;
        // The form will be populated automatically in the bloc's onLoading method
      }

      // Set the loaded state so the form renders
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _visitFormBloc.close();
    super.dispose();
  }

  void _saveVisit() async {
    if (_isSaving || _visitId == null) return;
    setState(() => _isSaving = true);

    try {
      if (_visitFormBloc.state.isValid()) {
        // Submit the form - this will trigger onSubmitting in the FormBloc
        _visitFormBloc.submit();
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<VisitBloc, VisitState>(
          listener: (context, state) {
            if (!_isLoaded && state is VisitLoaded) {
              _loadVisit();
            }
          },
        ),
        BlocListener<VisitFormBloc, FormBlocState<String, String>>(
          bloc: _visitFormBloc,
          listener: (context, state) {
            if (state is FormBlocSuccess) {
              context.pop();
            } else if (state is FormBlocFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('An error occurred')),
              );
            }
          },
        ),
      ],
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return AppAdaptiveScaffold(
      destinations: Destinations.navs(context),
      selectedIndex: Destinations.indexOf(const Key('Treatments'), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      body: (context) => SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(context.l10n.editVisit),
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
                child: _isLoaded && _visit != null
                    ? BlocProvider.value(
                        value: _visitFormBloc,
                        child: VisitForm(
                          visit: _visit,
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
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }
}