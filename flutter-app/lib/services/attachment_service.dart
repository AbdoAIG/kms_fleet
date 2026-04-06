import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../utils/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AttachmentService
// ─────────────────────────────────────────────────────────────────────────────
//
// Manages local photo attachments for fleet entities.
// Images are stored under:  <app_documents>/attachments/{entity_type}/{entity_id}/
//
// Supported entity types:
//   'maintenance', 'fuel', 'checklist', 'work_order', 'violation', 'vehicle'
//
// All methods are static – no instance needed.

class AttachmentService {
  AttachmentService._();

  // ── Constants ──────────────────────────────────────────────────────────

  /// Root folder name inside the app's documents directory.
  static const String _folderName = 'attachments';

  /// Supported entity types for attachment grouping.
  static const List<String> entityTypes = [
    'maintenance',
    'fuel',
    'checklist',
    'work_order',
    'violation',
    'vehicle',
  ];

  // ── Directory helpers ──────────────────────────────────────────────────

  /// Returns the root attachments directory path.
  static Future<String> _getRootDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, _folderName);
  }

  /// Returns the directory path for a specific entity's attachments.
  static Future<String> _getEntityDir(
    String entityType,
    int entityId,
  ) async {
    final root = await _getRootDir();
    return p.join(root, entityType, '$entityId');
  }

  /// Ensures the entity directory exists, creating it if needed.
  static Future<String> _ensureEntityDir(
    String entityType,
    int entityId,
  ) async {
    final dirPath = await _getEntityDir(entityType, entityId);
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dirPath;
  }

  // ── Unique filename generator ──────────────────────────────────────────

  /// Generates a unique filename using the current timestamp and a random
  /// integer, preserving the original file extension.
  static String _uniqueFileName(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    final ext = p.extension(originalPath).toLowerCase();
    return 'img_${timestamp}_$random$ext';
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Public API
  // ═════════════════════════════════════════════════════════════════════════

  /// Opens a bottom‑sheet letting the user pick an image from the camera
  /// or the gallery.
  ///
  /// [context] is required to present the source-selection bottom sheet.
  ///
  /// Returns the temporary file path of the picked image, or `null` if the
  /// user cancelled.
  static Future<String?> pickImage(BuildContext context) async {
    // Build the option tiles
    final cameraOption = _PickerOption(
      icon: Icons.camera_alt,
      label: 'الكاميرا',
      description: 'التقاط صورة جديدة',
      color: AppColors.primary,
      source: ImageSource.camera,
    );
    final galleryOption = _PickerOption(
      icon: Icons.photo_library,
      label: 'المعرض',
      description: 'اختيار صورة من المعرض',
      color: AppColors.info,
      source: ImageSource.gallery,
    );

    final picked = await showModalBottomSheet<_PickerOption>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'إرفاق صورة',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildOptionTile(ctx, cameraOption),
                const SizedBox(height: 8),
                _buildOptionTile(ctx, galleryOption),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return null;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: picked.source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      debugPrint('AttachmentService: error picking image: $e');
      return null;
    }
  }

  /// Copies the image at [filePath] into the entity's attachments directory
  /// and returns the new absolute path.
  static Future<String> saveAttachment(
    String entityType,
    int entityId,
    String filePath,
  ) async {
    final dirPath = await _ensureEntityDir(entityType, entityId);
    final fileName = _uniqueFileName(filePath);
    final newPath = p.join(dirPath, fileName);

    final source = File(filePath);
    await source.copy(newPath);

    return newPath;
  }

  /// Returns a list of absolute file paths for every attachment belonging to
  /// [entityType] / [entityId].  Returns an empty list if the directory does
  /// not exist.
  static Future<List<String>> getAttachments(
    String entityType,
    int entityId,
  ) async {
    try {
      final dirPath = await _getEntityDir(entityType, entityId);
      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];

      final entities = await dir
          .list()
          .where((e) => e is File)
          .map((e) => (e as File).path)
          .toList();

      // Sort newest first
      entities.sort((a, b) => b.compareTo(a));
      return entities;
    } catch (e) {
      debugPrint('AttachmentService: getAttachments error: $e');
      return [];
    }
  }

  /// Deletes a single attachment file at [filePath].
  static Future<void> deleteAttachment(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('AttachmentService: deleteAttachment error: $e');
    }
  }

  /// Deletes **all** attachments for a given entity, including its directory.
  static Future<void> deleteAllAttachments(
    String entityType,
    int entityId,
  ) async {
    try {
      final dirPath = await _getEntityDir(entityType, entityId);
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('AttachmentService: deleteAllAttachments error: $e');
    }
  }

  // ── Bottom‑sheet helper ────────────────────────────────────────────────

  static Widget _buildOptionTile(
    BuildContext context,
    _PickerOption option,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, option),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option.icon, color: option.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Internal data class ──────────────────────────────────────────────────

class _PickerOption {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final ImageSource source;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.source,
  });
}
