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
  int? _visitId;
  Hospital? _hospital;
  Department? _department;
  Doctor? _doctor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visitId == null) {
      // Extract visitId from route parameters
      _visitId = int.tryParse(GoRouterState.of(context).uri.pathSegments.last) ?? 0;
      
      // Ensure VisitBloc has all visits loaded (not filtered)
      context.read<VisitBloc>().add(LoadVisits());
      
      _loadVisit();
    }
  }

  void _loadVisit() async {
    if (_visitId == null) return;
    
    final state = context.read<VisitBloc>().state;
    if (state is VisitLoaded) {
      try {
        final updatedVisit = state.visits.firstWhere(
          (v) => v.id == _visitId,
        );
        
        // Only update if the visit data has actually changed
        if (_visit == null || 
            _visit!.details != updatedVisit.details ||
            _visit!.date != updatedVisit.date ||
            _visit!.hospitalId != updatedVisit.hospitalId ||
            _visit!.departmentId != updatedVisit.departmentId ||
            _visit!.doctorId != updatedVisit.doctorId) {
          
          _visit = updatedVisit;
          
          // Load related data
          await _loadRelatedData();
        }
      } catch (e) {
        // Visit not found in current VisitBloc state, load all visits and try again
        if (_visit == null) {
          // First time loading, fetch directly from database
          await _loadVisitFromDatabase();
        } else {
          // Visit was loaded before but not found in current state, 
          // this might be due to filtering. Load all visits.
          context.read<VisitBloc>().add(LoadVisits());
          // Try again after a brief delay
          await Future.delayed(Duration(milliseconds: 100));
          _loadVisit();
        }
      }
    }
  }

  Future<void> _loadVisitFromDatabase() async {
    if (_visitId == null) return;
    
    try {
      final database = context.read<AppDatabase>();
      final visit = await database.getVisitById(_visitId!);
      if (visit != null) {
        _visit = visit;
        await _loadRelatedData();
      } else {
        throw Exception('Visit not found');
      }
    } catch (e) {
      throw Exception('Failed to load visit: ${e.toString()}');
    }
  }

  Future<void> _loadRelatedData() async {
    if (_visit == null) return;
    
    setState(() {
      _isLoading = true;
    });

    final database = context.read<AppDatabase>();
    
    // Load related data in parallel
    final futures = <Future>[];
    
    if (_visit!.hospitalId != null) {
      futures.add(database.getHospitalById(_visit!.hospitalId!).then((h) => _hospital = h));
    }
    
    if (_visit!.departmentId != null) {
      futures.add(database.getDepartmentById(_visit!.departmentId!).then((d) => _department = d));
    }
    
    if (_visit!.doctorId != null) {
      futures.add(database.getDoctorById(_visit!.doctorId!).then((d) => _doctor = d));
    }
    
    await Future.wait(futures);
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitBloc, VisitState>(
      listener: (context, state) {
        if (state is VisitLoaded) {
          // Always reload the visit when VisitBloc state changes
          // This ensures the visit details update when the visit is edited
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
                        context.pushNamed(
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
                    'Hospital:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            _hospital?.name ?? 'Unknown Hospital',
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
                    'Department:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            _department?.name ?? 'Unknown Department',
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
                    'Doctor:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            _doctor?.name ?? 'Unknown Doctor',
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