import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:treatment_bloc/treatment_bloc.dart';
import 'package:treatment_form_bloc/treatment_form_bloc.dart';
import 'package:medical_records/widgets/treatment_form.dart';

class AddTreatmentScreen extends StatelessWidget {
  static const name = 'AddTreatment';
  static const path = '/treatments/add';

  const AddTreatmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TreatmentFormBloc(),
      child: const _AddTreatmentView(),
    );
  }
}

class _AddTreatmentView extends StatefulWidget {
  const _AddTreatmentView();

  @override
  State<_AddTreatmentView> createState() => _AddTreatmentViewState();
}

class _AddTreatmentViewState extends State<_AddTreatmentView> {
  bool _isSaving = false;

  void _saveTreatment() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final blocState = context.read<TreatmentFormBloc>().state;
      if (blocState.isFormValid) {
        context.read<TreatmentBloc>().add(
              AddTreatment(
                title: blocState.title.trim(),
                diagnosis: blocState.diagnosis.trim(),
                startDate: blocState.startDate!,
                endDate: blocState.endDate,
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
              title: Text(context.l10n.addTreatment),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
              actions: [
                BlocBuilder<TreatmentFormBloc, TreatmentFormState>(
                  builder: (context, state) {
                    return TextButton(
                      onPressed: state.isFormValid && !_isSaving ? _saveTreatment : null,
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
                child: TreatmentForm(
              onSave: ({
                required String title,
                required String diagnosis,
                required DateTime startDate,
                DateTime? endDate,
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