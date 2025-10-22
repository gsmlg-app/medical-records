import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_database/app_database.dart';

/// Resource picker modal bottom sheet
class ResourcePicker extends StatefulWidget {
  const ResourcePicker({
    super.key,
    required this.onResourceSelected,
    this.allowedTypes = const [ResourceType.image, ResourceType.document],
  });

  final Function(File sourceFile, ResourceType type) onResourceSelected;
  final List<ResourceType> allowedTypes;

  @override
  State<ResourcePicker> createState() => _ResourcePickerState();
}

class _ResourcePickerState extends State<ResourcePicker> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Resource',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a source to add a resource to this visit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      // Inner progress indicator
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      // Center dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Accessing your files...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we prepare your resources',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(children: _buildPickerOptions(context)),
            ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  child: Text(context.l10n.cancel.toUpperCase()),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPickerOptions(BuildContext context) {
    List<Widget> options = [];

    if (widget.allowedTypes.contains(ResourceType.image)) {
      // Camera is not available on web
      if (!kIsWeb) {
        options.add(
          _PickerOption(
            icon: Icons.camera_alt_outlined,
            label: context.l10n.camera,
            description: 'Take a new photo with your camera',
            color: Theme.of(context).primaryColor,
            onTap: _pickFromCamera,
          ),
        );
      }

      options.add(
        _PickerOption(
          icon: Icons.photo_library_outlined,
          label: context.l10n.gallery,
          description: 'Choose an existing photo from your gallery',
          color: Theme.of(context).colorScheme.secondary,
          onTap: _pickFromGallery,
        ),
      );
    }

    if (widget.allowedTypes.contains(ResourceType.document)) {
      options.add(
        _PickerOption(
          icon: Icons.insert_drive_file_outlined,
          label: kIsWeb ? 'Documents (Web Demo)' : context.l10n.documents,
          description: 'Select PDFs, images, and other documents',
          color: Theme.of(context).colorScheme.tertiary,
          onTap: _pickDocument,
        ),
      );
    }

    return options;
  }

  Future<void> _pickFromCamera() async {
    try {
      setState(() => _isLoading = true);

      // Web doesn't support camera picker
      if (kIsWeb) {
        _showError('Camera is not supported on web platform');
        return;
      }

      // Check camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showError(context.l10n.cameraPermissionDenied);
        return;
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        widget.onResourceSelected(file, ResourceType.image);
        _showSuccess('Photo captured successfully');
        // Dialog is closed in _showSuccess
      }
    } catch (e) {
      AppLogger().e('Error picking from camera: $e');
      _showError('Failed to access camera: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isLoading = true);

      // Check storage permission for mobile platforms
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final storageStatus = await Permission.photos.request();
          if (!storageStatus.isGranted) {
            _showError(context.l10n.storagePermissionDenied);
            return;
          }
        } else if (Platform.isIOS) {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            _showError('Photos permission denied');
            return;
          }
        }
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        widget.onResourceSelected(file, ResourceType.image);
        _showSuccess('Photo selected successfully');
        // Dialog is closed in _showSuccess
      }
    } catch (e) {
      AppLogger().e('Error picking from gallery: $e');
      _showError('Failed to access gallery: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument() async {
    try {
      setState(() => _isLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Document formats
          'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt',
          // Image formats
          'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif',
          // Spreadsheet formats
          'xls', 'xlsx', 'csv',
          // Other common formats
          'zip', 'rar', '7z',
        ],
        allowMultiple: false,
      );

      if (result != null) {
        // Handle web files differently (no file path)
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          // final name = result.files.single.name; // Unused variable

          if (bytes != null && bytes.length > 10 * 1024 * 1024) {
            _showError(context.l10n.fileTooLarge);
            return;
          }

          // For web, we would need a different storage approach
          _showError('File upload not supported on web in this demo');
          return;
        }

        if (result.files.single.path != null) {
          final file = File(result.files.single.path!);

          // Check file size (10MB limit)
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            _showError(context.l10n.fileTooLarge);
            return;
          }

          // Determine resource type based on file extension
          final extension = result.files.single.extension?.toLowerCase();
          ResourceType resourceType;

          if (extension != null && ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'].contains(extension)) {
            resourceType = ResourceType.image;
          } else {
            resourceType = ResourceType.document;
          }

          widget.onResourceSelected(file, resourceType);
          _showSuccess('File added successfully');
          // Dialog is closed in _showSuccess
        }
      }
    } catch (e) {
      AppLogger().e('Error picking document: $e');
      _showError('Failed to pick file: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      // Close the dialog first, then show the error message in the parent context
      Navigator.of(context).pop();

      // Use a post-frame callback to ensure the dialog is fully closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      });
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      // Close the dialog first, then show the success message in the parent context
      Navigator.of(context).pop();

      // Use a post-frame callback to ensure the dialog is fully closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }
}

/// Individual picker option widget
class _PickerOption extends StatefulWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_PickerOption> createState() => _PickerOptionState();
}

class _PickerOptionState extends State<_PickerOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon container with gradient background
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.color.withValues(alpha: 0.15),
                              widget.color.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: widget.color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(widget.icon, size: 28, color: widget.color),
                      ),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow icon
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Show resource picker modal
Future<void> showResourcePicker(
  BuildContext context, {
  required Function(File sourceFile, ResourceType type) onResourceSelected,
  List<ResourceType> allowedTypes = const [
    ResourceType.image,
    ResourceType.document,
  ],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => ResourcePicker(
      onResourceSelected: onResourceSelected,
      allowedTypes: allowedTypes,
    ),
  );
}
