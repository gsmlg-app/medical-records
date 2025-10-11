import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/treatments/add_treatment_screen.dart';
import 'package:medical_records/screens/treatments/edit_treatment_screen.dart';
import 'package:medical_records/screens/treatments/treatment_detail_screen.dart';
import 'package:treatment_bloc/treatment_bloc.dart';

class TreatmentsScreen extends StatefulWidget {
  static const name = 'Treatments';
  static const path = '/treatments';

  const TreatmentsScreen({super.key});

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  @override
  void initState() {
    super.initState();
    // Load treatments when the screen is first visited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreatmentBloc>().add(LoadTreatments());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TreatmentBloc, TreatmentState>(
      listener: (context, state) {
        if (state is TreatmentOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is TreatmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: state is TreatmentLoaded && state.treatments.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () {
                    context.pushNamed(AddTreatmentScreen.name);
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          body: AppAdaptiveScaffold(
            selectedIndex: Destinations.indexOf(const Key('Treatments'), context),
            onSelectedIndexChange: (idx) => Destinations.changeHandler(
              idx,
              context,
            ),
            destinations: Destinations.navs(context),
            body: (context) => SafeArea(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    title: Text(context.l10n.treatmentsTitle),
                    floating: true,
                  ),
                  if (state is TreatmentLoading || state is TreatmentInitial)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is TreatmentLoaded)
                    _buildTreatmentsList(context, state.treatments)
                  else if (state is TreatmentError)
                    SliverFillRemaining(
                      child: Center(
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
                                context.read<TreatmentBloc>().add(LoadTreatments());
                              },
                              child: Text(context.l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildEmptyState(context),
                ],
              ),
            ),
            smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noTreatments,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TreatmentBloc>().add(LoadTreatments());
                context.pushNamed(AddTreatmentScreen.name);
              },
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addTreatment),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentsList(BuildContext context, List<Treatment> treatments) {
    if (treatments.isEmpty) {
      return _buildEmptyState(context);
    }

    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final treatment = treatments[index];
            return TreatmentCard(treatment: treatment);
          },
          childCount: treatments.length,
        ),
      ),
    );
  }
}

class TreatmentCard extends StatelessWidget {
  final Treatment treatment;

  const TreatmentCard({
    super.key,
    required this.treatment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.medical_services),
        ),
        title: Text(treatment.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              treatment.diagnosis,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(treatment.startDate)} - ${treatment.endDate != null ? _formatDate(treatment.endDate!) : 'Ongoing'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                context.pushNamed(
                  TreatmentDetailScreen.name,
                  pathParameters: {'id': treatment.id.toString()},
                );
                break;
              case 'edit':
context.pushNamed(
                EditTreatmentScreen.name,
                pathParameters: {'id': treatment.id.toString()},
              );
                break;
              case 'delete':
                _showDeleteDialog(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
            ),
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
          context.goNamed(
            TreatmentDetailScreen.name,
            pathParameters: {'id': treatment.id.toString()},
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteTreatment),
        content: Text(context.l10n.deleteTreatmentConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TreatmentBloc>().add(DeleteTreatment(treatment.id));
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
}