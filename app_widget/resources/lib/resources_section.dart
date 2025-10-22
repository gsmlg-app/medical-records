import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_database/app_database.dart';
import 'package:app_storage/app_storage.dart';
import 'package:app_logging/app_logging.dart';
import 'resource_picker.dart';
import 'resource_list_item.dart';

/// Widget to display and manage resources for a visit
class ResourcesSection extends StatefulWidget {
  const ResourcesSection({
    super.key,
    required this.visitId,
    this.resources,
    this.onResourcesChanged,
    this.isReadOnly = false,
  });

  final int? visitId;
  final List<Resource>? resources;
  final Function(List<Resource>)? onResourcesChanged;
  final bool isReadOnly;

  @override
  State<ResourcesSection> createState() => _ResourcesSectionState();
}

class _ResourcesSectionState extends State<ResourcesSection> {
  final ResourceStorageService _storageService = ResourceStorageService();
  List<Resource> _resources = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resources = widget.resources ?? [];
  }

  @override
  void didUpdateWidget(ResourcesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resources != oldWidget.resources) {
      setState(() {
        _resources = widget.resources ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.resources,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (!widget.isReadOnly)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _showResourcePicker,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addResource),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_resources.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  context.l10n.noResources,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _resources.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final resource = _resources[index];
              return ResourceListItem(
                resource: resource,
                onDelete: () => _deleteResource(resource),
                onTap: () => _openResource(resource),
              );
            },
          ),
      ],
    );
  }

  void _showResourcePicker() {
    // Allow adding resources even without visitId (for new visits)
    // Resources will be stored with a temporary ID and saved when visit is created
    showResourcePicker(
      context,
      onResourceSelected: (sourceFile, type) async {
        await _addResource(sourceFile, type);
      },
    );
  }

  Future<void> _addResource(File sourceFile, ResourceType type) async {
    setState(() => _isLoading = true);

    try {
      AppLogger().d('Starting resource addition - File: ${sourceFile.path}, Type: ${type.value}');

      // For new visits (visitId == null), we use a temporary visit ID of -1
      // The actual file will be moved/renamed when the visit is saved
      final temporaryVisitId = widget.visitId ?? -1;
      AppLogger().d('Using visit ID: $temporaryVisitId');

      // Verify source file exists
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: ${sourceFile.path}');
      }
      AppLogger().d('Source file exists, size: ${await sourceFile.length()} bytes');

      // Store the file
      AppLogger().d('Calling storeResourceFile...');
      final relativePath = await _storageService.storeResourceFile(
        visitId: temporaryVisitId,
        sourceFile: sourceFile,
        type: type,
      );
      AppLogger().d('File stored successfully at: $relativePath');

      // Create resource record with temporary IDs
      final newResource = Resource(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        visitId: temporaryVisitId, // Will be updated when visit is created
        type: type.value,
        filePath: relativePath,
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      AppLogger().d('Created resource record: ${newResource.id}');

      setState(() {
        _resources.add(newResource);
      });
      AppLogger().d('Resource added to list, total: ${_resources.length}');

      // Notify parent so it can update the form bloc's resource list
      widget.onResourcesChanged?.call(_resources);
      AppLogger().d('Parent notified of resource change');

      _showSuccess(context.l10n.resourceAdded);
    } catch (e, stackTrace) {
      AppLogger().e('Failed to add resource: $e', e, stackTrace);
      _showError('Failed to add resource: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteResource(Resource resource) async {
    try {
      // Delete file
      await _storageService.deleteResourceFile(resource.filePath);

      // Remove from list
      setState(() {
        _resources.removeWhere((r) => r.id == resource.id);
      });

      // Notify parent
      widget.onResourcesChanged?.call(_resources);

      _showSuccess(context.l10n.resourceRemoved);
    } catch (e) {
      _showError('Failed to delete resource: $e');
    }
  }

  Future<void> _openResource(Resource resource) async {
    try {
      AppLogger().d('Opening resource: ${resource.filePath}');
      final file = await _storageService.getResourceFile(resource.filePath);

      if (!await file.exists()) {
        _showError('File not found: ${resource.filePath}');
        AppLogger().e('File not found: ${file.path}');
        return;
      }

      AppLogger().d('File exists, attempting to open: ${file.path}');

      // Get file size before showing dialog
      final fileSize = await file.length();

      // Try to open the file with the default system application
      // For now, we'll show a dialog with file information and path
      // In a production app, you would use packages like:
      // - open_file package for mobile
      // - url_launcher for web
      // - platform-specific file opening APIs

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Resource Preview'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Type: ${resource.type}'),
                  const SizedBox(height: 8),
                  Text('Path: ${file.path}'),
                  const SizedBox(height: 8),
                  Text('Size: ${_formatFileSize(fileSize)}'),
                  const SizedBox(height: 16),
                  if (resource.type == 'image')
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text('Failed to load image: $error');
                        },
                      ),
                    ),
                  if (resource.type != 'image')
                    Text(
                      'Preview not available for ${resource.type} files. '
                      'The file is stored at the path shown above.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().e('Failed to open resource: $e', e, stackTrace);
      _showError('Failed to open resource: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }
}
