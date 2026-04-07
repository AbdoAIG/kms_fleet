import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../services/attachment_service.dart';
import '../utils/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AttachmentPickerWidget
// ─────────────────────────────────────────────────────────────────────────────
//
// Reusable widget that displays existing attachments as a horizontal scrollable
// row of thumbnails and provides an "Add" button to pick new images via the
// [AttachmentService].
//
// Usage:
// ```dart
// AttachmentPickerWidget(
//   entityType: 'maintenance',
//   entityId: 42,
//   onAttachmentsChanged: (paths) => print('Updated: $paths'),
//   maxAttachments: 5,
// )
// ```

class AttachmentPickerWidget extends StatefulWidget {
  /// The entity type key (e.g. 'maintenance', 'fuel', 'checklist', …).
  final String entityType;

  /// The unique id of the entity this widget is attached to.
  final int entityId;

  /// Called whenever the attachment list changes (add / delete).
  final Function(List<String>) onAttachmentsChanged;

  /// Maximum number of attachments allowed. Defaults to 5.
  final int maxAttachments;

  /// Optional section title shown above the thumbnails.
  final String? title;

  const AttachmentPickerWidget({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.onAttachmentsChanged,
    this.maxAttachments = 5,
    this.title,
  });

  @override
  State<AttachmentPickerWidget> createState() => _AttachmentPickerWidgetState();
}

class _AttachmentPickerWidgetState extends State<AttachmentPickerWidget> {
  List<String> _paths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  /// Loads (or reloads) attachments from local storage.
  Future<void> _loadAttachments() async {
    final paths =
        await AttachmentService.getAttachments(widget.entityType, widget.entityId);
    if (mounted) {
      setState(() {
        _paths = paths;
        _isLoading = false;
      });
    }
  }

  /// Opens the image picker, saves the picked file, and refreshes the list.
  Future<void> _addAttachment() async {
    if (_paths.length >= widget.maxAttachments) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'الحد الأقصى للمرفقات هو ${widget.maxAttachments}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final pickedPath = await AttachmentService.pickImage(context);
    if (pickedPath == null) return;

    try {
      final savedPath = await AttachmentService.saveAttachment(
        widget.entityType,
        widget.entityId,
        pickedPath,
      );
      if (mounted) {
        setState(() {
          _paths = [savedPath, ..._paths];
        });
        widget.onAttachmentsChanged(_paths);
      }
    } catch (e) {
      debugPrint('AttachmentPickerWidget: error saving attachment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'حدث خطأ أثناء حفظ الصورة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Deletes a single attachment and refreshes the list.
  Future<void> _deleteAttachment(String filePath, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'حذف المرفق',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'هل تريد حذف هذا المرفق؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AttachmentService.deleteAttachment(filePath);
    if (mounted) {
      setState(() {
        _paths.removeAt(index);
      });
      widget.onAttachmentsChanged(_paths);
    }
  }

  /// Opens a full‑screen image viewer dialog.
  void _viewImage(String filePath) {
    final fileName = p.basename(filePath);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenImageViewer(
          imagePath: filePath,
          fileName: fileName,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional section title + attachment count
        if (widget.title != null || _paths.isNotEmpty) ...[
          Row(
            children: [
              if (widget.title != null)
                Expanded(
                  child: Text(
                    widget.title ?? '',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (_paths.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_paths.length} / ${widget.maxAttachments}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Loading indicator
        if (_isLoading)
          const SizedBox(
            height: 80,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

        // Empty state
        if (!_isLoading && _paths.isEmpty)
          _buildEmptyState(),

        // Thumbnails row
        if (!_isLoading && _paths.isNotEmpty)
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.only(end: 12),
              itemCount: _paths.length + (_paths.length < widget.maxAttachments ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                // "Add" button is the last item
                if (index == _paths.length) {
                  return _buildAddButton();
                }
                return _buildThumbnail(_paths[index], index);
              },
            ),
          ),

        // If list is empty and below max, still show the add button
        if (!_isLoading && _paths.isEmpty)
          const SizedBox(height: 8),
        if (!_isLoading && _paths.isEmpty)
          Center(child: _buildAddButton()),
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.attach_file, size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          const Text(
            'لا توجد مرفقات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // ── Add button ────────────────────────────────────────────────────────

  Widget _buildAddButton() {
    final isDisabled = _paths.length >= widget.maxAttachments;
    return GestureDetector(
      onTap: isDisabled ? null : _addAttachment,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.surfaceVariant
              : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? AppColors.border : AppColors.primary,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 26,
              color: isDisabled ? AppColors.textHint : AppColors.primary,
            ),
            const SizedBox(height: 4),
            Text(
              'إضافة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDisabled ? AppColors.textHint : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Thumbnail ─────────────────────────────────────────────────────────

  Widget _buildThumbnail(String filePath, int index) {
    return GestureDetector(
      onTap: () => _viewImage(filePath),
      child: Stack(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(filePath),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textHint,
                  size: 28,
                ),
              ),
            ),
          ),

          // Delete button overlay – top-left corner (RTL)
          Positioned(
            top: -4,
            left: -4,
            child: GestureDetector(
              onTap: () => _deleteAttachment(filePath, index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Full‑Screen Image Viewer
// ═════════════════════════════════════════════════════════════════════════════

class _FullScreenImageViewer extends StatefulWidget {
  final String imagePath;
  final String fileName;

  const _FullScreenImageViewer({
    required this.imagePath,
    required this.fileName,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformController =
      TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final wasZoomed = _isZoomed;
    _isZoomed = (scale - 1.0).abs() > 0.01;
    if (wasZoomed != _isZoomed && mounted) {
      setState(() {});
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
        ),
        title: Text(
          widget.fileName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          if (_isZoomed)
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _resetZoom,
              tooltip: 'إعادة التعيين',
            ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          // Tap on black area: close when not zoomed, reset when zoomed
          onTap: () {
            if (_isZoomed) {
              _resetZoom();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 5.0,
                panEnabled: true,
                scaleEnabled: true,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'تعذر عرض الصورة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // Filename displayed at the bottom
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.image_outlined, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
