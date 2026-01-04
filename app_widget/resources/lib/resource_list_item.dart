import 'package:flutter/material.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_database/app_database.dart';
import 'package:app_storage/app_storage.dart';

/// Widget to display a single resource item
class ResourceListItem extends StatefulWidget {
  const ResourceListItem({
    super.key,
    required this.resource,
    required this.onDelete,
    this.onTap,
    this.isReadOnly = false,
  });

  final Resource resource;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool isReadOnly;

  @override
  State<ResourceListItem> createState() => _ResourceListItemState();
}

class _ResourceListItemState extends State<ResourceListItem> {
  final ResourceStorageService _storageService = ResourceStorageService();
  bool _fileExists = false;
  int? _fileSize;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFileStatus();
  }

  Future<void> _checkFileStatus() async {
    try {
      final exists = await _storageService.resourceFileExists(
        widget.resource.filePath,
      );
      final size = await _storageService.getResourceFileSize(
        widget.resource.filePath,
      );

      if (mounted) {
        setState(() {
          _fileExists = exists;
          _fileSize = size;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileExists = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: _buildLeadingWidget(),
        title: Text(_getDisplayName()),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailingWidget(),
        onTap: widget.onTap,
      ),
    );
  }

  Widget _buildLeadingWidget() {
    if (_isLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (!_fileExists) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error_outline, color: Colors.grey, size: 20),
      );
    }

    switch (widget.resource.type) {
      case ResourceType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            color: Colors.grey[300],
            child: const Icon(Icons.image, color: Colors.grey, size: 20),
          ),
        );
      case ResourceType.document:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
        );
      case ResourceType.video:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.videocam, color: Colors.blue, size: 20),
        );
      case ResourceType.audio:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.audiotrack, color: Colors.green, size: 20),
        );
      default:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.insert_drive_file,
            color: Colors.grey,
            size: 20,
          ),
        );
    }
  }

  String _getDisplayName() {
    // Use custom name if set
    if (widget.resource.name != null && widget.resource.name!.isNotEmpty) {
      return widget.resource.name!;
    }

    final fileName = widget.resource.filePath.split('/').last;
    if (fileName.isNotEmpty) {
      return fileName;
    }

    // Fallback to type-based name
    switch (widget.resource.type) {
      case ResourceType.image:
        return 'Image';
      case ResourceType.document:
        return 'Document';
      case ResourceType.video:
        return 'Video';
      case ResourceType.audio:
        return 'Audio';
      default:
        return 'File';
    }
  }

  Widget _buildSubtitle() {
    List<String> parts = [];

    // Add file size if available
    if (_fileSize != null) {
      parts.add(_formatFileSize(_fileSize!));
    }

    // Add creation date
    parts.add(_formatDate(widget.resource.createdAt));

    // Add error message if file doesn't exist
    if (!_fileExists && !_isLoading) {
      parts.add('File not found');
    }

    return Text(
      parts.join(' • '),
      style: TextStyle(color: _fileExists ? null : Colors.red, fontSize: 12),
    );
  }

  Widget _buildTrailingWidget() {
    if (widget.isReadOnly) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: _showDeleteConfirmation,
      tooltip: context.l10n.delete,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteResource),
        content: Text(context.l10n.deleteResourceConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
