import 'dart:io';
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_backup/app_backup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/settings/settings_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DataExportScreen extends StatefulWidget {
  static const name = 'Data Export';
  static const path = 'export';
  static const fullPath = '${SettingsScreen.path}/$path';

  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  List<Treatment> _allTreatments = [];
  Set<int> _selectedTreatmentIds = {};
  bool _isLoading = true;
  bool _isExporting = false;
  String _exportMode = 'individual'; // individual, dateRange, all
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    setState(() => _isLoading = true);

    try {
      final database = context.read<AppDatabase>();
      final treatments = await database.getAllTreatments();

      // Sort by start date descending
      treatments.sort((a, b) => b.startDate.compareTo(a.startDate));

      setState(() {
        _allTreatments = treatments;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger().e('Failed to load treatments: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load treatments: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    if (_exportMode == 'individual' && _selectedTreatmentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one treatment to export')),
      );
      return;
    }

    if (_exportMode == 'dateRange' && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final database = context.read<AppDatabase>();
      final exportService = DataExportService(database);

      // Generate zip file
      final zipFile = await _performExport(exportService);
      final fileName = 'medical_records_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.zip';

      String? outputPath;

      if (kIsWeb) {
        // For web, use saveFile
        final bytes = await zipFile.readAsBytes();
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Export File',
          fileName: fileName,
          bytes: bytes,
        );
        outputPath = result;
        await zipFile.delete();
      } else if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, save to app documents directory or let user pick a directory
        try {
          // Try to use directory picker if available
          final directoryPath = await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'Select Export Location',
          );

          if (directoryPath != null) {
            // Save to selected directory
            final destPath = p.join(directoryPath, fileName);
            await zipFile.copy(destPath);
            outputPath = destPath;
            await zipFile.delete();
          } else {
            // User cancelled, clean up and return
            await zipFile.delete();
            setState(() => _isExporting = false);
            return;
          }
        } catch (e) {
          // If directory picker fails, save to Documents directory
          AppLogger().w('Directory picker not available, using Documents: $e');

          final documentsDir = await getApplicationDocumentsDirectory();
          final destPath = p.join(documentsDir.path, fileName);
          await zipFile.copy(destPath);
          outputPath = destPath;
          await zipFile.delete();
        }
      } else {
        // For desktop (macOS, Windows, Linux), use saveFile
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Export File',
          fileName: fileName,
        );

        if (result != null) {
          await zipFile.copy(result);
          outputPath = result;
          await zipFile.delete();
        } else {
          await zipFile.delete();
          setState(() => _isExporting = false);
          return;
        }
      }

      if (mounted && outputPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export completed: $outputPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().e('Export failed: $e', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<dynamic> _performExport(DataExportService exportService) async {
    switch (_exportMode) {
      case 'individual':
        return await exportService.exportTreatments(_selectedTreatmentIds.toList());

      case 'dateRange':
        return await exportService.exportTreatmentsByDateRange(_startDate!, _endDate!);

      case 'all':
        return await exportService.exportAllTreatments();

      default:
        throw Exception('Invalid export mode');
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(SettingsScreen.name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) => SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Export Data'),
              floating: true,
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildExportModeSelector(),
                    const SizedBox(height: 24),
                    if (_exportMode == 'individual') ...[
                      _buildIndividualSelection(),
                    ] else if (_exportMode == 'dateRange') ...[
                      _buildDateRangeSelection(),
                    ] else if (_exportMode == 'all') ...[
                      _buildAllSelection(),
                    ],
                    const SizedBox(height: 24),
                    _buildExportButton(),
                  ]),
                ),
              ),
          ],
        ),
      ),
      smallSecondaryBody: DmAdaptiveScaffold.emptyBuilder,
    );
  }

  Widget _buildExportModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'individual',
                  label: Text('Select'),
                  icon: Icon(Icons.checklist),
                ),
                ButtonSegment(
                  value: 'dateRange',
                  label: Text('Date Range'),
                  icon: Icon(Icons.date_range),
                ),
                ButtonSegment(
                  value: 'all',
                  label: Text('All'),
                  icon: Icon(Icons.select_all),
                ),
              ],
              selected: {_exportMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _exportMode = newSelection.first;
                  _selectedTreatmentIds.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Treatments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selectedTreatmentIds.length == _allTreatments.length) {
                        _selectedTreatmentIds.clear();
                      } else {
                        _selectedTreatmentIds = _allTreatments.map((t) => t.id).toSet();
                      }
                    });
                  },
                  icon: Icon(
                    _selectedTreatmentIds.length == _allTreatments.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  label: Text(
                    _selectedTreatmentIds.length == _allTreatments.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedTreatmentIds.length} of ${_allTreatments.length} selected',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            if (_allTreatments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No treatments found'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allTreatments.length,
                itemBuilder: (context, index) {
                  final treatment = _allTreatments[index];
                  final isSelected = _selectedTreatmentIds.contains(treatment.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedTreatmentIds.add(treatment.id);
                        } else {
                          _selectedTreatmentIds.remove(treatment.id);
                        }
                      });
                    },
                    title: Text(treatment.title),
                    subtitle: Text(
                      '${DateFormat('MMM d, yyyy').format(treatment.startDate)} - '
                      '${treatment.endDate != null ? DateFormat('MMM d, yyyy').format(treatment.endDate!) : 'Ongoing'}',
                    ),
                    secondary: const Icon(Icons.medical_services),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _startDate != null && _endDate != null
                    ? '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                    : 'Select Date Range',
              ),
            ),
            if (_startDate != null && _endDate != null) ...[
              const SizedBox(height: 16),
              Text(
                'Treatments within this date range will be exported',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All ${_allTreatments.length} treatments will be exported with their visits, resources, and related data.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _exportData,
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download),
        label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
