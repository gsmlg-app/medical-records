import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:treatment_bloc/treatment_bloc.dart';
import 'package:treatment_form_bloc/treatment_form_bloc.dart';
import 'package:medical_records/widgets/treatment_form.dart';

class EditTreatmentScreen extends StatelessWidget {
  static const name = 'EditTreatment';
  static const path = '/treatments/edit/:id';

  final int treatmentId;

  const EditTreatmentScreen({super.key, required this.treatmentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TreatmentFormBloc(),
      child: _EditTreatmentView(treatmentId: treatmentId),
    );
  }
}

class _EditTreatmentView extends StatefulWidget {
  const _EditTreatmentView({required this.treatmentId});

  final int treatmentId;

  @override
  State<_EditTreatmentView> createState() => _EditTreatmentViewState();
}

class _EditTreatmentViewState extends State<_EditTreatmentView> {
  Treatment? _treatment;
  bool _isLoaded = false;
  bool _isSaving = false;

  void _saveTreatment() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final blocState = context.read<TreatmentFormBloc>().state;
      if (blocState.isFormValid) {
        context.read<TreatmentBloc>().add(
              UpdateTreatment(
                id: widget.treatmentId,
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
  void initState() {
    super.initState();
    _loadTreatment();
  }

  void _loadTreatment() {
    final state = context.read<TreatmentBloc>().state;
    if (state is TreatmentLoaded) {
      _treatment = state.treatments.firstWhere(
        (t) => t.id == widget.treatmentId,
        orElse: () => throw Exception('Treatment not found'),
      );
      // Populate the form with treatment data
      context.read<TreatmentFormBloc>().add(
            TreatmentFormPopulate(_treatment!),
          );
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TreatmentBloc, TreatmentState>(
      listener: (context, state) {
        if (!_isLoaded && state is TreatmentLoaded) {
          _loadTreatment();
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
              title: Text(context.l10n.editTreatment),
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
                child: _isLoaded && _treatment != null
                    ? TreatmentForm(
                        treatment: _treatment,
                        onSave: ({
                          required String title,
                          required String diagnosis,
                          required DateTime startDate,
                          DateTime? endDate,
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