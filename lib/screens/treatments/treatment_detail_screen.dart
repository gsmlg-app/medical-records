import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/treatments/edit_treatment_screen.dart';
import 'package:medical_records/screens/visits/add_visit_screen.dart';
import 'package:medical_records/screens/visits/visit_detail_screen.dart';
import 'package:treatment_bloc/treatment_bloc.dart';
import 'package:visit_bloc/visit_bloc.dart';
import 'package:hospital_bloc/hospital_bloc.dart';

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
  // List<Visit> _visits = []; // Unused field
  List<Hospital> _hospitals = [];
  List<Department> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadTreatment();
    _loadVisits();
    _loadHospitalsAndDepartments();
  }

  void _loadTreatment() {
    if (!context.mounted) return;
    final state = context.read<TreatmentBloc>().state;
    if (state is TreatmentLoaded) {
      _treatment = state.treatments.firstWhere(
        (t) => t.id == widget.treatmentId,
        orElse: () => throw Exception('Treatment not found'),
      );
    }
  }

  void _loadVisits() {
    context.read<VisitBloc>().add(LoadVisitsByTreatment(widget.treatmentId));
  }

  void _loadHospitalsAndDepartments() {
    // Load hospitals and departments for display in visit list
    context.read<HospitalBloc>().add(LoadHospitals());
  }

  Future<void> _loadDepartmentsFromDatabase() async {
    try {
      final database = context.read<AppDatabase>();
      final allDepartments = await database.getAllDepartments();

      setState(() {
        _departments = allDepartments;
      });
    } catch (e) {
      // Handle error gracefully - departments will remain empty
      AppLogger().e('Error loading departments: $e', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TreatmentBloc, TreatmentState>(
          listener: (context, state) {
            if (_treatment == null && state is TreatmentLoaded) {
              _loadTreatment();
            }
          },
        ),
        BlocListener<HospitalBloc, HospitalState>(
          listener: (context, state) {
            if (state is HospitalLoaded) {
              setState(() {
                _hospitals = state.hospitals;
              });
              // Load departments from database
              _loadDepartmentsFromDatabase();
            }
          },
        ),
      ],
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
                      context.pushNamed(
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
                context.pushNamed(
                  AddVisitScreen.name,
                  pathParameters: {'treatmentId': widget.treatmentId.toString()},
                );
              },
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addVisit),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<VisitBloc, VisitState>(
          builder: (context, state) {
            if (state is VisitLoading) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (state is VisitLoaded) {
              final treatmentVisits = state.visits.where((v) => v.treatmentId == widget.treatmentId).toList();

              if (treatmentVisits.isEmpty) {
                return Card(
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
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: treatmentVisits.length,
                itemBuilder: (context, index) {
                  final visit = treatmentVisits[index];
                  final hospitalName = _getHospitalName(visit.hospitalId);
                  final departmentName = _getDepartmentName(visit.departmentId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(_formatDate(visit.date)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hospitalName != null || departmentName != null) ...[
                            Row(
                              children: [
                                if (hospitalName != null) ...[
                                  Icon(Icons.local_hospital, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hospitalName,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                if (hospitalName != null && departmentName != null)
                                  const SizedBox(width: 8),
                                if (departmentName != null) ...[
                                  Icon(Icons.business, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      departmentName,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            visit.details.length > 50
                                ? '${visit.details.substring(0, 50)}...'
                                : visit.details,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.pushNamed(
                          VisitDetailScreen.name,
                          pathParameters: {'id': visit.id.toString()},
                        );
                      },
                    ),
                  );
                },
              );
            } else if (state is VisitError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading visits',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String? _getHospitalName(int? hospitalId) {
    if (hospitalId == null) return null;
    final hospital = _hospitals.where((h) => h.id == hospitalId).firstOrNull;
    return hospital?.name;
  }

  String? _getDepartmentName(int? departmentId) {
    if (departmentId == null) return null;
    final department = _departments.where((d) => d.id == departmentId).firstOrNull;
    return department?.name;
  }
}