import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/treatments/treatments_screen.dart';
import 'package:visit_bloc/visit_bloc.dart';

class VisitsScreen extends StatelessWidget {
  static const name = 'Visits';
  static const path = '/visits';

  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VisitBloc(context.read())..add(LoadVisits()),
      child: AppAdaptiveScaffold(
        selectedIndex: Destinations.indexOf(Key(TreatmentsScreen.name), context),
        onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
        destinations: Destinations.navs(context),
        body: (context) => BlocConsumer<VisitBloc, VisitState>(
          listener: (context, state) {
            if (state is VisitOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is VisitError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is VisitLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is VisitLoaded) {
              return _buildVisitsList(context, state.visits);
            } else if (state is VisitError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<VisitBloc>().add(LoadVisits());
                      },
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              );
            }
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  context.read<VisitBloc>().add(LoadVisits());
                },
                child: Text(context.l10n.loadVisits),
              ),
            );
          },
        ),
        smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
      ),
    );
  }

  Widget _buildVisitsList(BuildContext context, List<Visit> visits) {
    if (visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noVisits,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.addFirstVisitHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<VisitBloc>().add(LoadVisits());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return VisitCard(visit: visit);
        },
      ),
    );
  }
}

class VisitCard extends StatelessWidget {
  final Visit visit;

  const VisitCard({
    super.key,
    required this.visit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            visit.category == 'outpatient' ? Icons.event : Icons.local_hospital,
          ),
        ),
        title: Text(
          visit.category == 'outpatient' ? 'Outpatient Visit' : 'Inpatient Visit',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(visit.date)),
            const SizedBox(height: 4),
            Text(
              visit.details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                // TODO: Navigate to edit visit screen
                break;
              case 'delete':
                _showDeleteDialog(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to visit detail screen
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visit'),
        content: const Text('Are you sure you want to delete this visit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VisitBloc>().add(DeleteVisit(visit.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}