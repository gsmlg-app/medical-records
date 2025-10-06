import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:visit_form_widget/visit_form.dart';
import 'package:visit_bloc/visit_bloc.dart';
import 'package:app_provider/app_provider.dart';

class EditVisitScreen extends StatelessWidget {
  static const name = 'EditVisit';
  static const path = '/visits/edit/:id';

  const EditVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EditVisitView();
  }
}

class _EditVisitView extends StatefulWidget {
  const _EditVisitView();

  @override
  State<_EditVisitView> createState() => _EditVisitViewState();
}

class _EditVisitViewState extends State<_EditVisitView> {
  Visit? _visit;
  bool _isLoaded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadVisit();
  }

  void _loadVisit() {
    final state = context.read<VisitBloc>().state;
    if (state is VisitLoaded) {
      // Extract visitId from route parameters
      final visitId = int.tryParse(GoRouterState.of(context).uri.pathSegments.last) ?? 0;

      _visit = state.visits.firstWhere(
        (v) => v.id == visitId,
        orElse: () => throw Exception('Visit not found'),
      );

      // Populate the form with visit data
      context.read<VisitFormBloc>().add(
            VisitFormPopulate({
              'category': _visit!.category,
              'date': _visit!.date,
              'details': _visit!.details,
              'hospitalId': _visit!.hospitalId,
              'departmentId': _visit!.departmentId,
              'doctorId': _visit!.doctorId,
              'informations': _visit!.informations,
            }),
          );

      setState(() {
        _isLoaded = true;
      });
    }
  }

  void _saveVisit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final blocState = context.read<VisitFormBloc>().state;
      if (blocState.isFormValid) {
        // Extract visitId from route parameters
        final visitId = int.tryParse(GoRouterState.of(context).uri.pathSegments.last) ?? 0;

        context.read<VisitBloc>().add(
              UpdateVisit(
                id: visitId,
                treatmentId: _visit!.treatmentId,
                category: blocState.category,
                date: blocState.date!,
                details: blocState.details.trim(),
                hospitalId: blocState.hospitalId,
                departmentId: blocState.departmentId,
                doctorId: blocState.doctorId,
                informations: blocState.informations,
              ),
            );
        context.pop();
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitBloc, VisitState>(
      listener: (context, state) {
        if (!_isLoaded && state is VisitLoaded) {
          _loadVisit();
        }
      },
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
                BlocBuilder<VisitFormBloc, VisitFormState>(
                  builder: (context, state) {
                    return TextButton(
                      onPressed: state.isFormValid && !_isSaving ? _saveVisit : null,
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
                    ? VisitForm(
                        visit: _visit,
                        onSave: ({
                          required VisitCategory category,
                          required DateTime date,
                          required String details,
                          int? hospitalId,
                          int? departmentId,
                          int? doctorId,
                          String? informations,
                        }) async {
                          // This is handled by the save button in the AppBar
                        },
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