import 'package:flutter/material.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_database/app_database.dart';
import 'package:app_storage/app_storage.dart';
import 'package:app_feedback/app_feedback.dart';
import 'package:duskmoon_widgets/duskmoon_widgets.dart';

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
    return DmCard(
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

    final colorScheme = Theme.of(context).colorScheme;

    if (!_fileExists) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.error_outline,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
      );
    }

    switch (widget.resource.type) {
      case ResourceType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            color: colorScheme.outlineVariant,
            child: Icon(
              Icons.image,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        );
      case ResourceType.document:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.picture_as_pdf, color: colorScheme.error, size: 20),
        );
      case ResourceType.video:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.videocam, color: colorScheme.primary, size: 20),
        );
      case ResourceType.audio:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.audiotrack, color: colorScheme.primary, size: 20),
        );
      default:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.insert_drive_file,
            color: colorScheme.onSurfaceVariant,
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
      parts.join(' \u2022 '),
      style: TextStyle(
        color: _fileExists
            ? null
            : Theme.of(context).colorScheme.error,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTrailingWidget() {
    if (widget.isReadOnly) {
      return const SizedBox.shrink();
    }

    return DmIconButton(
      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
      onPressed: _showDeleteConfirmation,
      tooltip: context.l10n.delete,
    );
  }

  void _showDeleteConfirmation() async {
    final confirmed = await showAppDeleteDialog(
      context,
      title: context.l10n.deleteResource,
      content: context.l10n.deleteResourceConfirmation,
    );
    if (confirmed) {
      widget.onDelete();
    }
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
