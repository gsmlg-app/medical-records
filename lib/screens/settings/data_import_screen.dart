import 'dart:io';
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_backup/app_backup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/settings/settings_screen.dart';

class DataImportScreen extends StatefulWidget {
  static const name = 'Data Import';
  static const path = 'import';
  static const fullPath = '${SettingsScreen.path}/$path';

  const DataImportScreen({super.key});

  @override
  State<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends State<DataImportScreen> {
  File? _selectedFile;
  Map<String, dynamic>? _parsedData;
  List<ImportConflict>? _conflicts;
  final Map<String, ConflictResolution> _conflictResolutions = {};
  bool _isLoading = false;
  bool _isImporting = false;

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select Medical Records Export File',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _parsedData = null;
          _conflicts = null;
          _conflictResolutions.clear();
        });

        await _parseFile();
      }
    } catch (e) {
      AppLogger().e('Failed to select file: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e')),
        );
      }
    }
  }

  Future<void> _parseFile() async {
    if (_selectedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final database = context.read<AppDatabase>();
      final importService = DataImportService(database);

      // Parse zip file
      final parsedData = await importService.parseZipFile(_selectedFile!);

      // Check for conflicts
      final conflicts = await importService.checkConflicts(parsedData['manifest']);

      setState(() {
        _parsedData = parsedData;
        _conflicts = conflicts;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger().e('Failed to parse file: $e', e, stackTrace);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to parse file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    if (_parsedData == null) return;

    // Check if all conflicts have been resolved
    if (_conflicts != null && _conflicts!.isNotEmpty) {
      for (final conflict in _conflicts!) {
        if (!_conflictResolutions.containsKey(conflict.treatment.title)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please resolve all conflicts before importing'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isImporting = true);

    try {
      final database = context.read<AppDatabase>();
      final importService = DataImportService(database);

      await importService.importTreatments(_parsedData!, _conflictResolutions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import completed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset state
        setState(() {
          _selectedFile = null;
          _parsedData = null;
          _conflicts = null;
          _conflictResolutions.clear();
        });
      }
    } catch (e, stackTrace) {
      AppLogger().e('Import failed: $e', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
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
            const SliverAppBar(
              title: Text('Import Data'),
              floating: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFileSelector(),
                  const SizedBox(height: 24),
                  if (_isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else if (_parsedData != null) ...[
                    _buildPreview(),
                    const SizedBox(height: 24),
                    if (_conflicts != null && _conflicts!.isNotEmpty) ...[
                      _buildConflictsSection(),
                      const SizedBox(height: 24),
                    ],
                    _buildImportButton(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }

  Widget _buildFileSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select File',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFile == null)
              ElevatedButton.icon(
                onPressed: _selectFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse...'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.file_present, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.path.split('/').last,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _parsedData = null;
                            _conflicts = null;
                            _conflictResolutions.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_parsedData == null) return const SizedBox.shrink();

    final manifest = _parsedData!['manifest'] as Map<String, dynamic>;
    final treatments = manifest['treatments'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Export Date',
              DateFormat('MMM d, yyyy HH:mm').format(
                DateTime.parse(manifest['exportDate'] as String)
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.medical_services, 'Treatments', '${treatments.length}'),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: treatments.length,
              itemBuilder: (context, index) {
                final treatment = treatments[index]['treatment'] as Map<String, dynamic>;
                final visits = treatments[index]['visits'] as List<dynamic>;
                final resources = treatments[index]['resources'] as List<dynamic>;

                return Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_right, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${treatment['title']} (${visits.length} visits, ${resources.length} resources)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictsSection() {
    if (_conflicts == null || _conflicts!.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Conflicts Found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_conflicts!.length} treatment(s) have the same title and date range as existing treatments.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
            const Divider(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _conflicts!.length,
              itemBuilder: (context, index) {
                final conflict = _conflicts![index];
                return _buildConflictResolutionCard(conflict);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictResolutionCard(ImportConflict conflict) {
    final resolution = _conflictResolutions[conflict.treatment.title];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conflict.treatment.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateFormat('MMM d, yyyy').format(conflict.treatment.startDate)} - '
              '${conflict.treatment.endDate != null ? DateFormat('MMM d, yyyy').format(conflict.treatment.endDate!) : 'Ongoing'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text('Choose action:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            SegmentedButton<ConflictResolution>(
              segments: const [
                ButtonSegment(
                  value: ConflictResolution.skip,
                  label: Text('Skip'),
                  icon: Icon(Icons.skip_next, size: 16),
                ),
                ButtonSegment(
                  value: ConflictResolution.override,
                  label: Text('Override'),
                  icon: Icon(Icons.sync, size: 16),
                ),
                ButtonSegment(
                  value: ConflictResolution.createNew,
                  label: Text('Create New'),
                  icon: Icon(Icons.add, size: 16),
                ),
              ],
              selected: resolution != null ? {resolution} : {},
              onSelectionChanged: (Set<ConflictResolution> newSelection) {
                setState(() {
                  _conflictResolutions[conflict.treatment.title] = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    final canImport = _parsedData != null &&
        (_conflicts == null ||
         _conflicts!.isEmpty ||
         _conflicts!.every((c) => _conflictResolutions.containsKey(c.treatment.title)));

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canImport && !_isImporting ? _importData : null,
        icon: _isImporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload),
        label: Text(_isImporting ? 'Importing...' : 'Import Data'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
