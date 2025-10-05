import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/treatments/edit_treatment_screen.dart';
import 'package:treatment_bloc/treatment_bloc.dart';

class TreatmentDetailScreen extends StatefulWidget {
  static const name = 'TreatmentDetail';
  static const path = '/treatments/detail/:id';

  final int treatmentId;

  const TreatmentDetailScreen({super.key, required this.treatmentId});

  @override
  State<TreatmentDetailScreen> createState() => _TreatmentDetailScreenState();
}

class _TreatmentDetailScreenState extends State<TreatmentDetailScreen> {
  Treatment? _treatment;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TreatmentBloc, TreatmentState>(
      listener: (context, state) {
        if (_treatment == null && state is TreatmentLoaded) {
          _loadTreatment();
        }
      },
      child: AppAdaptiveScaffold(
        destinations: Destinations.navs(context),
        selectedIndex: Destinations.indexOf(const Key('Treatments'), context),
        onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
        body: (context) => SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(context.l10n.treatmentDetails),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.goNamed(
                        EditTreatmentScreen.name,
                        pathParameters: {'id': widget.treatmentId.toString()},
                      );
                    },
                  ),
                ],
              ),
              if (_treatment == null)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildVisitsSection(),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _treatment!.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.diagnosis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(_treatment!.diagnosis),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.startDate,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_formatDate(_treatment!.startDate)),
                    ],
                  ),
                ),
                if (_treatment!.endDate != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.endDate,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(_formatDate(_treatment!.endDate!)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.visits,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to add visit screen with treatmentId
              },
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addVisit),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.noVisitsForTreatment,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.addFirstVisit,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}