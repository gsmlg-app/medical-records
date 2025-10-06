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

  void _saveVisit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final blocState = context.read<VisitFormBloc>().state;
      if (blocState.isFormValid) {
        // Get treatmentId from route parameters
        final treatmentId = int.tryParse(GoRouterState.of(context).uri.pathSegments.last) ?? 0;

        context.read<VisitBloc>().add(
              AddVisit(
                treatmentId: treatmentId,
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
                child: VisitForm(
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
                ),
              ),
            ),
          ],
        ),
      ),
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }
}