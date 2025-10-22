import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_database/app_database.dart';
import 'package:app_storage/app_storage.dart';
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
      // For new visits (visitId == null), we use a temporary visit ID of -1
      // The actual file will be moved/renamed when the visit is saved
      final temporaryVisitId = widget.visitId ?? -1;

      // Store the file
      final relativePath = await _storageService.storeResourceFile(
        visitId: temporaryVisitId,
        sourceFile: sourceFile,
        type: type,
      );

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

      setState(() {
        _resources.add(newResource);
      });

      // Notify parent so it can update the form bloc's resource list
      widget.onResourcesChanged?.call(_resources);

      _showSuccess(context.l10n.resourceAdded);
    } catch (e) {
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
      final file = await _storageService.getResourceFile(resource.filePath);
      if (file.existsSync()) {
        // In a real implementation, you would open the file
        // For now, just show a message
        _showInfo('File path: ${file.path}');
      } else {
        _showError('File not found');
      }
    } catch (e) {
      _showError('Failed to open resource: $e');
    }
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
