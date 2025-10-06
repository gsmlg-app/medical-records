import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:visit_bloc/visit_bloc.dart';

class VisitDetailScreen extends StatefulWidget {
  static const name = 'VisitDetail';
  static const path = '/visits/detail/:id';

  const VisitDetailScreen({super.key});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  Visit? _visit;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitBloc, VisitState>(
      listener: (context, state) {
        if (_visit == null && state is VisitLoaded) {
          _loadVisit();
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
                title: Text(context.l10n.visitDetails),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      if (_visit != null) {
                        context.goNamed(
                          'EditVisit',
                          pathParameters: {'id': _visit!.id.toString()},
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _visit != null ? () => _showDeleteDialog(context) : null,
                  ),
                ],
              ),
              if (_visit == null)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildInfoCard(),
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
            // Visit Category
            Row(
              children: [
                Text(
                  'Category:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_formatCategoryName(_getCategoryFromValue(_visit!.category))),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visit Date
            Row(
              children: [
                Text(
                  context.l10n.visitDate,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(_visit!.date),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hospital Information
            if (_visit!.hospitalId != null) ...[
              Row(
                children: [
                  Text(
                    'Hospital ID:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _visit!.hospitalId.toString(),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Department Information
            if (_visit!.departmentId != null) ...[
              Row(
                children: [
                  Text(
                    'Department ID:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _visit!.departmentId.toString(),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Doctor Information
            if (_visit!.doctorId != null) ...[
              Row(
                children: [
                  Text(
                    'Doctor ID:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _visit!.doctorId.toString(),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Visit Details
            Text(
              context.l10n.visitDetails,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_visit!.details),
            const SizedBox(height: 16),

            // Timestamps
            Text(
              'Created:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(_formatDateTime(_visit!.createdAt)),
            const SizedBox(height: 8),
            Text(
              'Updated:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(_formatDateTime(_visit!.updatedAt)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteVisit),
        content: Text(context.l10n.deleteVisitConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VisitBloc>().add(DeleteVisit(_visit!.id));
              context.pop(); // Go back to previous screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  VisitCategory _getCategoryFromValue(dynamic value) {
    if (value is VisitCategory) {
      return value;
    }
    if (value is String) {
      for (final category in VisitCategory.values) {
        if (category.value == value) {
          return category;
        }
      }
    }
    return VisitCategory.outpatient;
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