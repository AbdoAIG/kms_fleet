import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist.dart';
import '../models/fuel_record.dart';
import '../models/work_order.dart';
import '../models/expense.dart';
import '../utils/constants.dart';
import 'database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReportService
// ─────────────────────────────────────────────────────────────────────────────
//
// Generates PDF and Excel reports from local data and shares them via the
// system share sheet.
//
// PDF generation uses the Cairo font for proper Arabic text rendering.
// Excel generation uses the `excel` package with number and date formatting.
//
// Files are saved to a temporary directory with proper extensions and MIME
// types before sharing, to avoid Android saving them as generic .bin files.

class ReportService {
  ReportService._();

  // ── Font loading ─────────────────────────────────────────────────────────

  /// Loads the Cairo-Regular.ttf bundled font for Arabic PDF text.
  static Future<pw.Font> _loadCairoFont() async {
    final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  /// Builds a standard PDF header with logo, report title and subtitle.
  /// Returns a Row with logo on the right and title/subtitle on the left.
  static Future<List<pw.Widget>> buildPdfHeader({
    required String title,
    required String subtitle,
  }) async {
    // Load logo image from assets
    final logoBytes = await rootBundle.load('assets/images/kms_logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    return [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Title and subtitle on the left
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          // Logo on the right (compact, no overlap)
          pw.Image(logoImage, width: 130, height: 130, fit: pw.BoxFit.contain),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Divider(),
      pw.SizedBox(height: 10),
    ];
  }

  /// Loads the watermark image from assets for use as PDF background.
  static Future<pw.MemoryImage> _loadWatermarkImage() async {
    final bytes = await rootBundle.load('assets/images/kms_watermark.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  /// Returns a full-page centered watermark widget that sits behind content.
  /// Must be used as the FIRST child of a pw.Stack with pw.Positioned.fill.
  static pw.Widget buildWatermarkOverlay(pw.MemoryImage watermarkImage) {
    return pw.Positioned.fill(
      child: pw.Opacity(
        opacity: 0.15,
        child: pw.Center(
          child: pw.Image(
            watermarkImage,
            width: 450,
            height: 210,
            fit: pw.BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Wraps a list of content widgets with a watermark background using Stack.
  static pw.Widget wrapWithWatermark(pw.MemoryImage watermarkImage, List<pw.Widget> content) {
    return pw.Stack(
      children: [
        buildWatermarkOverlay(watermarkImage),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: content,
        ),
      ],
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  /// MIME type mapping for proper file sharing.
  static String _mimeType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/octet-stream';
  }

  /// Saves raw bytes to a temporary file with the correct extension and
  /// shares it via the system share sheet.
  ///
  /// Writing to disk (instead of using XFile.fromData) ensures Android
  /// recognises the file type, preventing the "saved as .bin" issue.
  // ── Temp file cleanup ────────────────────────────────────────────────

  /// Deletes report temp files older than 1 hour from the temporary directory.
  ///
  /// Only targets files matching known report prefixes with .pdf or .xlsx extensions:
  /// `تقرير_*.pdf`, `تقرير_*.xlsx`, `سجلات_*.xlsx`, `قوائم_*.xlsx`, `تصدير_*.xlsx`.
  static Future<void> _cleanupOldTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      final prefixes = ['تقرير_', 'سجلات_', 'قوائم_', 'تصدير_'];

      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final isReport = prefixes.any((p) => name.startsWith(p));
        if (!isReport) continue;
        if (!name.endsWith('.pdf') && !name.endsWith('.xlsx')) continue;

        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('ReportService: error cleaning temp files: $e');
    }
  }

  static Future<String> _shareBytes(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      // Clean up old report temp files (fire-and-forget, don't block sharing)
      _cleanupOldTempFiles();

      final dir = await getTemporaryDirectory();
      // Sanitise file name: keep only safe characters
      final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-\u0600-\u06FF]'), '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);

      final xFile = XFile(
        file.path,
        name: safeName,
        mimeType: _mimeType(safeName),
      );
      await Share.shareXFiles([xFile], text: '');
      return fileName;
    } catch (e) {
      debugPrint('ReportService: error sharing file: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PDF Report: Maintenance Records
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateMaintenancePDF() async {
    try {
      final font = await _loadCairoFont();
      final watermarkImage = await _loadWatermarkImage();
      final records = await DatabaseService.getAllMaintenanceRecords();
      final now = DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.now());

      // Pre-build header
      final headerWidgets = await buildPdfHeader(
        title: 'تقرير سجلات الصيانة',
        subtitle: '${AppConstants.appName} – $now',
      );

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
              wrapWithWatermark(watermarkImage, [
                ...headerWidgets,
                pw.SizedBox(height: 8),
                pw.Text(
                  'إجمالي السجلات: ${records.length}',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                if (records.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: [
                      '#', 'المركبة', 'التاريخ', 'الوصف', 'النوع',
                      'التكلفة', 'الحالة', 'الأولوية',
                    ],
                    data: records.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final r = entry.value;
                      final vehicleLabel =
                          r.vehicle != null ? '${r.vehicle!.make} ${r.vehicle!.model}' : 'غير معروف';
                      final dateLabel = DateFormat('dd/MM/yyyy').format(r.maintenanceDate);
                      final typeLabel = AppConstants.maintenanceTypes[r.type] ?? r.type;
                      final statusLabel = AppConstants.maintenanceStatuses[r.status] ?? r.status;
                      final priorityLabel = AppConstants.priorities[r.priority] ?? r.priority;

                      return [
                        '$i', vehicleLabel, dateLabel, r.description, typeLabel,
                        '${r.totalCost.toStringAsFixed(2)} ج.م', statusLabel, priorityLabel,
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignment: pw.Alignment.center,
                    headerAlignment: pw.Alignment.center,
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                      verticalInside: pw.BorderSide(color: PdfColors.grey300),
                      left: pw.BorderSide(color: PdfColors.grey400),
                      right: pw.BorderSide(color: PdfColors.grey400),
                      top: pw.BorderSide(color: PdfColors.grey400),
                      bottom: pw.BorderSide(color: PdfColors.grey400),
                    ),
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      'لا توجد سجلات صيانة',
                      style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey500),
                    ),
                  ),
              ]),
            ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'تقرير_الصيانة_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateMaintenancePDF error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PDF Report: Vehicles Fleet Overview
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateVehiclesPDF() async {
    try {
      final font = await _loadCairoFont();
      final watermarkImage = await _loadWatermarkImage();
      final vehicles = await DatabaseService.getAllVehicles();
      final now = DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.now());

      // Pre-build header
      final headerWidgets = await buildPdfHeader(
        title: 'تقرير أسطول المركبات',
        subtitle: '${AppConstants.appName} – $now',
      );

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: font),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
              wrapWithWatermark(watermarkImage, [
                ...headerWidgets,
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Text(
                      'إجمالي المركبات: ${vehicles.length}',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'نشطة: ${vehicles.where((v) => v.status == 'active').length}',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'في الصيانة: ${vehicles.where((v) => v.status == 'maintenance').length}',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                if (vehicles.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: [
                      '#', 'رقم اللوحة', 'الماركة', 'الموديل', 'السنة',
                      'اللون', 'الوقود', 'العداد', 'الحالة',
                    ],
                    data: vehicles.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final v = entry.value;
                      final colorLabel = AppConstants.vehicleColors[v.color] ?? v.color;
                      final fuelLabel = AppConstants.fuelTypes[v.fuelType] ?? v.fuelType;
                      final statusLabel = AppConstants.vehicleStatuses[v.status] ?? v.status;

                      return [
                        '$i', v.plateNumber, v.make, v.model, '${v.year}',
                        colorLabel, fuelLabel, '${v.currentOdometer} كم', statusLabel,
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignment: pw.Alignment.center,
                    headerAlignment: pw.Alignment.center,
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                      verticalInside: pw.BorderSide(color: PdfColors.grey300),
                      left: pw.BorderSide(color: PdfColors.grey400),
                      right: pw.BorderSide(color: PdfColors.grey400),
                      top: pw.BorderSide(color: PdfColors.grey400),
                      bottom: pw.BorderSide(color: PdfColors.grey400),
                    ),
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      'لا توجد مركبات',
                      style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey500),
                    ),
                  ),
              ]),
            ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'تقرير_الأسطول_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateVehiclesPDF error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Excel Report: Fuel Records
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateFuelExcel() async {
    try {
      final records = await DatabaseService.getAllFuelRecords();
      final workbook = Excel.createExcel();
      final sheet = workbook['سجلات الوقود'];

      // Remove the default empty sheet that excel package creates
      workbook.delete('Sheet1');

      // ── Headers ────────────────────────────────────────────────────
      const headers = [
        '#', 'المركبة', 'رقم اللوحة', 'تاريخ التعبئة', 'العداد (كم)',
        'اللترات', 'سعر اللتر (ج.م)', 'الإجمالي (ج.م)', 'نوع الوقود',
        'المحطة', 'الموقع', 'خزان كامل', 'معدل الاستهلاك', 'غير طبيعي', 'ملاحظات',
      ];

      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // ── Data rows ──────────────────────────────────────────────────
      for (var row = 0; row < records.length; row++) {
        final r = records[row];
        final vehicleLabel = r.vehicle != null
            ? '${r.vehicle!.make} ${r.vehicle!.model}'
            : 'غير معروف';
        final plateLabel = r.vehicle?.plateNumber ?? '';
        final dateLabel = DateFormat('dd/MM/yyyy').format(r.fillDate);
        final fuelLabel = AppConstants.fuelTypes[r.fuelType] ?? r.fuelType;
        final consumptionText =
            r.consumptionRate != null ? '${r.consumptionRate!.toStringAsFixed(1)} كم/لتر' : '';

        final values = <CellValue>[
          IntCellValue(row + 1),
          TextCellValue(vehicleLabel),
          TextCellValue(plateLabel),
          TextCellValue(dateLabel),
          IntCellValue(r.odometerReading),
          DoubleCellValue(r.liters),
          DoubleCellValue(r.costPerLiter),
          DoubleCellValue(r.totalCost),
          TextCellValue(fuelLabel),
          TextCellValue(r.stationName ?? ''),
          TextCellValue(r.stationLocation ?? ''),
          TextCellValue(r.fullTank ? 'نعم' : 'لا'),
          TextCellValue(consumptionText),
          TextCellValue((r.isAbnormal ?? false) ? 'نعم' : 'لا'),
          TextCellValue(r.notes ?? ''),
        ];

        for (var col = 0; col < values.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = values[col];
          cell.cellStyle = CellStyle(
            fontSize: 10,
            horizontalAlign: HorizontalAlign.Center,
          );
        }
      }

      final bytes = workbook.save();
      if (bytes == null) {
        debugPrint('ReportService: workbook save returned null');
        return '';
      }
      final fileName = 'سجلات_الوقود_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateFuelExcel error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Excel Report: Checklists
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateChecklistExcel() async {
    try {
      final checklists = await DatabaseService.getAllChecklists();
      final workbook = Excel.createExcel();
      final sheet = workbook['قوائم الفحص'];

      workbook.delete('Sheet1');

      // ── Headers ────────────────────────────────────────────────────
      const headers = [
        '#', 'المركبة', 'رقم اللوحة', 'نوع الفحص', 'تاريخ الفحص',
        'العداد (كم)', 'المفتش', 'عدد البنود', 'بنود مكتملة',
        'بنود بها عيوب', 'التقييم', 'الحالة', 'ملاحظات',
      ];

      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // ── Data rows ──────────────────────────────────────────────────
      for (var row = 0; row < checklists.length; row++) {
        final c = checklists[row];
        final vehicleLabel = c.vehicle != null
            ? '${c.vehicle!.make} ${c.vehicle!.model}'
            : 'غير معروف';
        final plateLabel = c.vehicle?.plateNumber ?? '';
        final typeLabel = Checklist.typeLabel(c.type);
        final dateLabel = DateFormat('dd/MM/yyyy').format(c.inspectionDate);
        final statusLabel = AppConstants.maintenanceStatuses[c.status] ?? c.status;

        final values = <CellValue>[
          IntCellValue(row + 1),
          TextCellValue(vehicleLabel),
          TextCellValue(plateLabel),
          TextCellValue(typeLabel),
          TextCellValue(dateLabel),
          IntCellValue(c.odometerReading),
          TextCellValue(c.inspectorName ?? ''),
          IntCellValue(c.items.length),
          IntCellValue(c.checkedCount),
          IntCellValue(c.defectCount),
          DoubleCellValue(c.overallScore),
          TextCellValue(statusLabel),
          TextCellValue(c.notes ?? ''),
        ];

        for (var col = 0; col < values.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = values[col];
          cell.cellStyle = CellStyle(
            fontSize: 10,
            horizontalAlign: HorizontalAlign.Center,
          );
        }
      }

      final bytes = workbook.save();
      if (bytes == null) {
        debugPrint('ReportService: workbook save returned null');
        return '';
      }
      final fileName = 'قوائم_الفحص_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateChecklistExcel error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PDF Report: Work Orders
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateWorkOrdersPDF() async {
    try {
      final font = await _loadCairoFont();
      final watermarkImage = await _loadWatermarkImage();
      final orders = await DatabaseService.getAllWorkOrders();
      final now = DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.now());

      // Pre-build header
      final headerWidgets = await buildPdfHeader(
        title: 'تقرير أوامر العمل',
        subtitle: '${AppConstants.appName} – $now',
      );

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: font),
      );

      // Pre-calculate summary
      double totalEstimated = 0;
      double totalActual = 0;
      int overBudgetCount = 0;
      for (final o in orders) {
        totalEstimated += o.estimatedCost ?? 0;
        totalActual += o.actualCost ?? 0;
        if (o.isOverBudget) overBudgetCount++;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
              wrapWithWatermark(watermarkImage, [
                ...headerWidgets,
                pw.SizedBox(height: 8),
                pw.Text(
                  'إجمالي الأوامر: ${orders.length}',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                if (orders.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: [
                      '#', 'المركبة', 'رقم اللوحة', 'النوع', 'الحالة',
                      'الأولوية', 'الفني', 'التكلفة المقدرة', 'التكلفة الفعلية', 'الفرق',
                    ],
                    data: orders.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final o = entry.value;
                      final vehicleLabel = o.vehicle != null
                          ? '${o.vehicle!.make} ${o.vehicle!.model}'
                          : 'غير معروف';
                      final plateLabel = o.vehicle?.plateNumber ?? '';
                      final typeLabel = _workOrderTypeLabel(o.type);
                      final statusLabel = _workOrderStatusLabel(o.status);
                      final priorityLabel = AppConstants.priorities[o.priority] ?? o.priority;
                      final est = o.estimatedCost ?? 0;
                      final act = o.actualCost ?? 0;
                      final diff = act - est;

                      return [
                        '$i',
                        vehicleLabel,
                        plateLabel,
                        typeLabel,
                        statusLabel,
                        priorityLabel,
                        o.technicianName ?? '-',
                        '${est.toStringAsFixed(2)} ج.م',
                        '${act.toStringAsFixed(2)} ج.م',
                        '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} ج.م',
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    cellStyle: const pw.TextStyle(fontSize: 7),
                    cellAlignment: pw.Alignment.center,
                    headerAlignment: pw.Alignment.center,
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                      verticalInside: pw.BorderSide(color: PdfColors.grey300),
                      left: pw.BorderSide(color: PdfColors.grey400),
                      right: pw.BorderSide(color: PdfColors.grey400),
                      top: pw.BorderSide(color: PdfColors.grey400),
                      bottom: pw.BorderSide(color: PdfColors.grey400),
                    ),
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      'لا توجد أوامر عمل',
                      style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey500),
                    ),
                  ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Text(
                      'إجمالي الأوامر: ${orders.length}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'إجمالي المقدر: ${totalEstimated.toStringAsFixed(2)} ج.م',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'إجمالي الفعلي: ${totalActual.toStringAsFixed(2)} ج.م',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'تجاوزت الميزانية: $overBudgetCount',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: overBudgetCount > 0 ? PdfColors.red700 : PdfColors.green700,
                      ),
                    ),
                  ],
                ),
              ]),
            ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'تقرير_أوامر_العمل_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateWorkOrdersPDF error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PDF Report: Monthly Cost per Vehicle
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateMonthlyCostPDF() async {
    try {
      final font = await _loadCairoFont();
      final watermarkImage = await _loadWatermarkImage();
      final expenses = await DatabaseService.getAllExpenses();
      final now = DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.now());

      // Pre-build header
      final headerWidgets = await buildPdfHeader(
        title: 'تقرير التكاليف الشهري لكل مركبة',
        subtitle: '${AppConstants.appName} – $now',
      );

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: font),
      );

      // Group by vehicle then by month
      final Map<String, Map<String, _MonthCostRow>> grouped = {};
      for (final e in expenses) {
        final vehicleLabel = e.vehicle != null
            ? '${e.vehicle!.make} ${e.vehicle!.model}'
            : 'غير معروف';
        final plateLabel = e.vehicle?.plateNumber ?? '';
        final key = '$vehicleLabel|$plateLabel';
        final monthKey = DateFormat('yyyy-MM').format(e.date);
        final monthLabel = DateFormat('MM/yyyy').format(e.date);

        grouped.putIfAbsent(key, () => <String, _MonthCostRow>{});

        grouped[key]!.putIfAbsent(monthKey, () => _MonthCostRow(
          vehicleLabel: vehicleLabel,
          plateLabel: plateLabel,
          month: monthLabel,
        ));

        final row = grouped[key]![monthKey]!;
        switch (e.type) {
          case 'maintenance':
            row.maintenance += e.amount;
          case 'fuel':
            row.fuel += e.amount;
          case 'violation':
            row.violations += e.amount;
          case 'insurance':
            row.insurance += e.amount;
          default:
            row.other += e.amount;
        }
      }

      // Flatten into list
      final rows = grouped.values.expand((m) => m.values).toList();
      rows.sort((a, b) => '${a.vehicleLabel}${a.month}'.compareTo('${b.vehicleLabel}${b.month}'));

      // Monthly totals
      final Map<String, _MonthCostRow> monthlyTotals = {};
      for (final row in rows) {
        monthlyTotals.putIfAbsent(row.month, () => _MonthCostRow(
          vehicleLabel: '',
          plateLabel: '',
          month: row.month,
        ));
        final t = monthlyTotals[row.month]!;
        t.maintenance += row.maintenance;
        t.fuel += row.fuel;
        t.violations += row.violations;
        t.insurance += row.insurance;
        t.other += row.other;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
              wrapWithWatermark(watermarkImage, [
                ...headerWidgets,
                pw.SizedBox(height: 8),
                pw.Text(
                  'إجمالي السجلات: ${rows.length}',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                if (rows.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                headers: [
                  '#', 'المركبة', 'رقم اللوحة', 'الشهر',
                  'الصيانة', 'الوقود', 'الغرامات', 'التأمين', 'أخرى', 'الإجمالي',
                ],
                data: rows.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final r = entry.value;
                  final total = r.maintenance + r.fuel + r.violations + r.insurance + r.other;
                  return [
                    '$i',
                    r.vehicleLabel,
                    r.plateLabel,
                    r.month,
                    '${r.maintenance.toStringAsFixed(2)}',
                    '${r.fuel.toStringAsFixed(2)}',
                    '${r.violations.toStringAsFixed(2)}',
                    '${r.insurance.toStringAsFixed(2)}',
                    '${r.other.toStringAsFixed(2)}',
                    '${total.toStringAsFixed(2)} ج.م',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                  verticalInside: pw.BorderSide(color: PdfColors.grey300),
                  left: pw.BorderSide(color: PdfColors.grey400),
                  right: pw.BorderSide(color: PdfColors.grey400),
                  top: pw.BorderSide(color: PdfColors.grey400),
                  bottom: pw.BorderSide(color: PdfColors.grey400),
                ),
              )
            else
              pw.Center(
                child: pw.Text(
                  'لا توجد بيانات مصروفات',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey500),
                ),
              ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'الإجمالي الشهري',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: [
                'الشهر', 'الصيانة', 'الوقود', 'الغرامات', 'التأمين', 'أخرى', 'الإجمالي',
              ],
              data: monthlyTotals.values.map((t) {
                final total = t.maintenance + t.fuel + t.violations + t.insurance + t.other;
                return [
                  t.month,
                  '${t.maintenance.toStringAsFixed(2)}',
                  '${t.fuel.toStringAsFixed(2)}',
                  '${t.violations.toStringAsFixed(2)}',
                  '${t.insurance.toStringAsFixed(2)}',
                  '${t.other.toStringAsFixed(2)}',
                  '${total.toStringAsFixed(2)} ج.م',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                verticalInside: pw.BorderSide(color: PdfColors.grey300),
                left: pw.BorderSide(color: PdfColors.grey400),
                right: pw.BorderSide(color: PdfColors.grey400),
                top: pw.BorderSide(color: PdfColors.grey400),
                bottom: pw.BorderSide(color: PdfColors.grey400),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'الإجمالي الشهري',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: [
                'الشهر', 'الصيانة', 'الوقود', 'الغرامات', 'التأمين', 'أخرى', 'الإجمالي',
              ],
              data: monthlyTotals.values.map((t) {
                final total = t.maintenance + t.fuel + t.violations + t.insurance + t.other;
                return [
                  t.month,
                  '${t.maintenance.toStringAsFixed(2)}',
                  '${t.fuel.toStringAsFixed(2)}',
                  '${t.violations.toStringAsFixed(2)}',
                  '${t.insurance.toStringAsFixed(2)}',
                  '${t.other.toStringAsFixed(2)}',
                  '${total.toStringAsFixed(2)} ج.م',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                verticalInside: pw.BorderSide(color: PdfColors.grey300),
                left: pw.BorderSide(color: PdfColors.grey400),
                right: pw.BorderSide(color: PdfColors.grey400),
                top: pw.BorderSide(color: PdfColors.grey400),
                bottom: pw.BorderSide(color: PdfColors.grey400),
              ),
            ),
              ]),
            ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'تقرير_التكاليف_الشهري_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateMonthlyCostPDF error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Excel Report: Comprehensive Accountant Export
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateComprehensiveExcel() async {
    try {
      final vehicles = await DatabaseService.getAllVehicles();
      final maintenanceRecords = await DatabaseService.getAllMaintenanceRecords();
      final fuelRecords = await DatabaseService.getAllFuelRecords();
      final expenses = await DatabaseService.getAllExpenses();
      final workOrders = await DatabaseService.getAllWorkOrders();

      final workbook = Excel.createExcel();

      // Delete default Sheet1
      workbook.delete('Sheet1');

      // ── Helper to write headers ────────────────────────────────────────
      void writeHeaders(Sheet sheet, List<String> headers) {
        for (var col = 0; col < headers.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
          cell.value = TextCellValue(headers[col]);
          cell.cellStyle = CellStyle(
            bold: true,
            fontSize: 11,
            horizontalAlign: HorizontalAlign.Center,
          );
        }
      }

      // ── Helper to write a data row ──────────────────────────────────────
      void writeRow(Sheet sheet, int rowIndex, List<CellValue> values) {
        for (var col = 0; col < values.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
          cell.value = values[col];
          cell.cellStyle = CellStyle(
            fontSize: 10,
            horizontalAlign: HorizontalAlign.Center,
          );
        }
      }

      // ═══════════════════════════════════════════════════════════════════
      //  Sheet 1: ملخص عام
      // ═══════════════════════════════════════════════════════════════════
      final summarySheet = workbook['ملخص عام'];
      final totalMaintenanceCost = maintenanceRecords.fold<double>(0, (s, r) => s + r.totalCost);
      final totalFuelCost = fuelRecords.fold<double>(0, (s, r) => s + r.totalCost);
      final totalExpenseCost = expenses.fold<double>(0, (s, e) => s + e.amount);
      final totalAllCosts = totalMaintenanceCost + totalFuelCost + totalExpenseCost;
      final activeCount = vehicles.where((v) => v.status == 'active').length;

      writeHeaders(summarySheet, ['البند', 'القيمة']);
      writeRow(summarySheet, 1, [TextCellValue('تاريخ التقرير'), TextCellValue(DateFormat('yyyy-MM-dd').format(DateTime.now()))]);
      writeRow(summarySheet, 2, [TextCellValue('إجمالي المركبات'), IntCellValue(vehicles.length)]);
      writeRow(summarySheet, 3, [TextCellValue('المركبات النشطة'), IntCellValue(activeCount)]);
      writeRow(summarySheet, 4, [TextCellValue('إجمالي تكاليف الصيانة'), DoubleCellValue(totalMaintenanceCost)]);
      writeRow(summarySheet, 5, [TextCellValue('إجمالي تكاليف الوقود'), DoubleCellValue(totalFuelCost)]);
      writeRow(summarySheet, 6, [TextCellValue('إجمالي المصروفات'), DoubleCellValue(totalExpenseCost)]);
      writeRow(summarySheet, 7, [TextCellValue('إجمالي التكاليف الكلية'), DoubleCellValue(totalAllCosts)]);
      writeRow(summarySheet, 8, [TextCellValue('عدد سجلات الصيانة'), IntCellValue(maintenanceRecords.length)]);
      writeRow(summarySheet, 9, [TextCellValue('عدد سجلات الوقود'), IntCellValue(fuelRecords.length)]);
      writeRow(summarySheet, 10, [TextCellValue('عدد أوامر العمل'), IntCellValue(workOrders.length)]);

      // ═══════════════════════════════════════════════════════════════════
      //  Sheet 2: المركبات
      // ═══════════════════════════════════════════════════════════════════
      final vehiclesSheet = workbook['المركبات'];
      writeHeaders(vehiclesSheet, [
        '#', 'رقم اللوحة', 'الماركة', 'الموديل', 'السنة',
        'اللون', 'الوقود', 'العداد (كم)', 'الحالة', 'اسم السائق', 'رقم الرخصة',
      ]);
      for (var row = 0; row < vehicles.length; row++) {
        final v = vehicles[row];
        writeRow(vehiclesSheet, row + 1, [
          IntCellValue(row + 1),
          TextCellValue(v.plateNumber),
          TextCellValue(v.make),
          TextCellValue(v.model),
          IntCellValue(v.year),
          TextCellValue(AppConstants.vehicleColors[v.color] ?? v.color),
          TextCellValue(AppConstants.fuelTypes[v.fuelType] ?? v.fuelType),
          IntCellValue(v.currentOdometer),
          TextCellValue(AppConstants.vehicleStatuses[v.status] ?? v.status),
          TextCellValue(v.driverName ?? ''),
          TextCellValue(v.driverLicenseNumber ?? ''),
        ]);
      }

      // ═══════════════════════════════════════════════════════════════════
      //  Sheet 3: سجلات الصيانة
      // ═══════════════════════════════════════════════════════════════════
      final maintenanceSheet = workbook['سجلات الصيانة'];
      writeHeaders(maintenanceSheet, [
        '#', 'المركبة', 'رقم اللوحة', 'التاريخ', 'الوصف', 'النوع',
        'التكلفة (ج.م)', 'الحالة', 'الأولوية',
      ]);
      for (var row = 0; row < maintenanceRecords.length; row++) {
        final r = maintenanceRecords[row];
        writeRow(maintenanceSheet, row + 1, [
          IntCellValue(row + 1),
          TextCellValue(r.vehicle != null ? '${r.vehicle!.make} ${r.vehicle!.model}' : 'غير معروف'),
          TextCellValue(r.vehicle?.plateNumber ?? ''),
          TextCellValue(DateFormat('dd/MM/yyyy').format(r.maintenanceDate)),
          TextCellValue(r.description),
          TextCellValue(AppConstants.maintenanceTypes[r.type] ?? r.type),
          DoubleCellValue(r.totalCost),
          TextCellValue(AppConstants.maintenanceStatuses[r.status] ?? r.status),
          TextCellValue(AppConstants.priorities[r.priority] ?? r.priority),
        ]);
      }

      // ═══════════════════════════════════════════════════════════════════
      //  Sheet 4: الوقود
      // ═══════════════════════════════════════════════════════════════════
      final fuelSheet = workbook['الوقود'];
      writeHeaders(fuelSheet, [
        '#', 'المركبة', 'رقم اللوحة', 'تاريخ التعبئة', 'العداد (كم)',
        'اللترات', 'سعر اللتر (ج.م)', 'الإجمالي (ج.م)', 'نوع الوقود', 'المحطة',
      ]);
      for (var row = 0; row < fuelRecords.length; row++) {
        final r = fuelRecords[row];
        writeRow(fuelSheet, row + 1, [
          IntCellValue(row + 1),
          TextCellValue(r.vehicle != null ? '${r.vehicle!.make} ${r.vehicle!.model}' : 'غير معروف'),
          TextCellValue(r.vehicle?.plateNumber ?? ''),
          TextCellValue(DateFormat('dd/MM/yyyy').format(r.fillDate)),
          IntCellValue(r.odometerReading),
          DoubleCellValue(r.liters),
          DoubleCellValue(r.costPerLiter),
          DoubleCellValue(r.totalCost),
          TextCellValue(AppConstants.fuelTypes[r.fuelType] ?? r.fuelType),
          TextCellValue(r.stationName ?? ''),
        ]);
      }

      // ═══════════════════════════════════════════════════════════════════
      //  Sheet 5: المصروفات
      // ═══════════════════════════════════════════════════════════════════
      final expensesSheet = workbook['المصروفات'];
      writeHeaders(expensesSheet, [
        '#', 'المركبة', 'رقم اللوحة', 'التاريخ', 'النوع',
        'المبلغ (ج.م)', 'الوصف', 'مقدم الخدمة', 'رقم الفاتورة',
      ]);
      for (var row = 0; row < expenses.length; row++) {
        final e = expenses[row];
        writeRow(expensesSheet, row + 1, [
          IntCellValue(row + 1),
          TextCellValue(e.vehicle != null ? '${e.vehicle!.make} ${e.vehicle!.model}' : 'غير معروف'),
          TextCellValue(e.vehicle?.plateNumber ?? ''),
          TextCellValue(DateFormat('dd/MM/yyyy').format(e.date)),
          TextCellValue(AppConstants.expenseTypes[e.type] ?? e.type),
          DoubleCellValue(e.amount),
          TextCellValue(e.description),
          TextCellValue(e.serviceProvider ?? ''),
          TextCellValue(e.invoiceNumber ?? ''),
        ]);
      }

      // ═══════════════════════════════════════════════════════════════════
      //  Sheet 6: أوامر العمل
      // ═══════════════════════════════════════════════════════════════════
      final ordersSheet = workbook['أوامر العمل'];
      writeHeaders(ordersSheet, [
        '#', 'المركبة', 'رقم اللوحة', 'النوع', 'الحالة',
        'الأولوية', 'الفني', 'التكلفة المقدرة (ج.م)', 'التكلفة الفعلية (ج.م)', 'الفرق (ج.م)',
        'تاريخ البدء', 'تاريخ الاكتمال', 'ملاحظات',
      ]);
      for (var row = 0; row < workOrders.length; row++) {
        final o = workOrders[row];
        final est = o.estimatedCost ?? 0;
        final act = o.actualCost ?? 0;
        final diff = act - est;
        writeRow(ordersSheet, row + 1, [
          IntCellValue(row + 1),
          TextCellValue(o.vehicle != null ? '${o.vehicle!.make} ${o.vehicle!.model}' : 'غير معروف'),
          TextCellValue(o.vehicle?.plateNumber ?? ''),
          TextCellValue(_workOrderTypeLabel(o.type)),
          TextCellValue(_workOrderStatusLabel(o.status)),
          TextCellValue(AppConstants.priorities[o.priority] ?? o.priority),
          TextCellValue(o.technicianName ?? ''),
          DoubleCellValue(est),
          DoubleCellValue(act),
          DoubleCellValue(diff),
          TextCellValue(o.startDate != null ? DateFormat('dd/MM/yyyy').format(o.startDate!) : ''),
          TextCellValue(o.completedDate != null ? DateFormat('dd/MM/yyyy').format(o.completedDate!) : ''),
          TextCellValue(o.notes ?? ''),
        ]);
      }

      final bytes = workbook.save();
      if (bytes == null) {
        debugPrint('ReportService: workbook save returned null');
        return '';
      }
      final fileName = 'تصدير_شامل_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateComprehensiveExcel error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PDF Report: Single Vehicle
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateSingleVehiclePDF(Vehicle vehicle) async {
    try {
      final font = await _loadCairoFont();
      final watermarkImage = await _loadWatermarkImage();
      final vehicleId = vehicle.id ?? 0;
      final now = DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.now());

      // Pre-build header
      final headerWidgets = await buildPdfHeader(
        title: 'تقرير مركبة: ${vehicle.make} ${vehicle.model}',
        subtitle: '${AppConstants.appName} – $now',
      );

      // Fetch vehicle-specific data
      final maintenanceRecords = await DatabaseService.getMaintenanceByVehicleId(vehicleId);
      final fuelRecords = await DatabaseService.getFuelRecordsByVehicleId(vehicleId);
      final allViolations = await DatabaseService.getAllViolations();
      final violations = allViolations.where((v) => v.vehicleId == vehicleId).toList();

      // Calculate totals
      double totalMaintenanceCost = 0;
      for (final r in maintenanceRecords) {
        totalMaintenanceCost += r.totalCost;
      }
      double totalFuelCost = 0;
      for (final f in fuelRecords) {
        totalFuelCost += f.totalCost;
      }
      double totalViolationAmount = 0;
      for (final v in violations) {
        totalViolationAmount += v.amount;
      }

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: font),
      );

      // Common table border style
      const tableBorder = pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300),
        verticalInside: pw.BorderSide(color: PdfColors.grey300),
        left: pw.BorderSide(color: PdfColors.grey400),
        right: pw.BorderSide(color: PdfColors.grey400),
        top: pw.BorderSide(color: PdfColors.grey400),
        bottom: pw.BorderSide(color: PdfColors.grey400),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
              wrapWithWatermark(watermarkImage, [
                ...headerWidgets,
                pw.SizedBox(height: 8),

                // ── Vehicle Info Section ──
                pw.Text(
                  'بيانات المركبة',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['البيان', 'القيمة'],
                  data: [
                    ['رقم اللوحة', vehicle.plateNumber],
                    ['الماركة والموديل', '${vehicle.make} ${vehicle.model}'],
                    ['سنة الصنع', '${vehicle.year}'],
                    ['اللون', AppConstants.vehicleColors[vehicle.color] ?? vehicle.color],
                    ['نوع الوقود', AppConstants.fuelTypes[vehicle.fuelType] ?? vehicle.fuelType],
                    ['العداد الحالي', '${vehicle.currentOdometer} كم'],
                    ['الحالة', AppConstants.vehicleStatuses[vehicle.status] ?? vehicle.status],
                    if (vehicle.vehicleType != null && vehicle.vehicleType!.isNotEmpty)
                      ['نوع المركبة', vehicle.vehicleType!],
                    ['اسم السائق', vehicle.driverName ?? 'غير محدد'],
                  ],
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  border: tableBorder,
                ),
                pw.SizedBox(height: 16),

                // ── Cost Summary ──
                pw.Text(
                  'ملخص التكاليف',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Text(
                      'إجمالي الصيانة: ${totalMaintenanceCost.toStringAsFixed(2)} ج.م',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'إجمالي الوقود: ${totalFuelCost.toStringAsFixed(2)} ج.م',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'إجمالي المخالفات: ${totalViolationAmount.toStringAsFixed(2)} ج.م',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 12),

                // ── Maintenance Records ──
                pw.Text(
                  'سجل الصيانة (${maintenanceRecords.length} سجل)',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                if (maintenanceRecords.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: ['#', 'التاريخ', 'الوصف', 'النوع', 'التكلفة', 'الحالة', 'الأولوية'],
                    data: maintenanceRecords.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final r = entry.value;
                      return [
                        '$i',
                        DateFormat('dd/MM/yyyy').format(r.maintenanceDate),
                        r.description,
                        AppConstants.maintenanceTypes[r.type] ?? r.type,
                        '${r.totalCost.toStringAsFixed(2)} ج.م',
                        AppConstants.maintenanceStatuses[r.status] ?? r.status,
                        AppConstants.priorities[r.priority] ?? r.priority,
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    cellStyle: const pw.TextStyle(fontSize: 7),
                    cellAlignment: pw.Alignment.center,
                    headerAlignment: pw.Alignment.center,
                    border: tableBorder,
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      'لا توجد سجلات صيانة',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500),
                    ),
                  ),
                pw.SizedBox(height: 16),

                // ── Fuel Records ──
                pw.Text(
                  'سجل الوقود (${fuelRecords.length} سجل)',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                if (fuelRecords.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: ['#', 'التاريخ', 'العداد', 'اللترات', 'سعر اللتر', 'الإجمالي', 'المحطة'],
                    data: fuelRecords.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final r = entry.value;
                      return [
                        '$i',
                        DateFormat('dd/MM/yyyy').format(r.fillDate),
                        '${r.odometerReading} كم',
                        '${r.liters.toStringAsFixed(1)} لتر',
                        '${r.costPerLiter.toStringAsFixed(2)} ج.م',
                        '${r.totalCost.toStringAsFixed(2)} ج.م',
                        r.stationName ?? '',
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    cellStyle: const pw.TextStyle(fontSize: 7),
                    cellAlignment: pw.Alignment.center,
                    headerAlignment: pw.Alignment.center,
                    border: tableBorder,
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      'لا توجد سجلات وقود',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500),
                    ),
                  ),
                pw.SizedBox(height: 16),

                // ── Violations ──
                pw.Text(
                  'المخالفات (${violations.length} مخالفة)',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                if (violations.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: ['#', 'التاريخ', 'الوصف', 'النوع', 'المبلغ', 'النقاط', 'الحالة'],
                    data: violations.asMap().entries.map((entry) {
                      final i = entry.key + 1;
                      final v = entry.value;
                      return [
                        '$i',
                        DateFormat('dd/MM/yyyy').format(v.date),
                        v.description,
                        v.type,
                        '${v.amount.toStringAsFixed(2)} ج.م',
                        '${v.points}',
                        v.status,
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    cellStyle: const pw.TextStyle(fontSize: 7),
                    cellAlignment: pw.Alignment.center,
                    headerAlignment: pw.Alignment.center,
                    border: tableBorder,
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      'لا توجد مخالفات',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500),
                    ),
                  ),
              ]),
            ],
        ),
      );

      final bytes = await pdf.save();
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'تقرير_مركبة_${vehicle.plateNumber}_$dateStr.pdf';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateSingleVehiclePDF error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Excel Report: Single Vehicle
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateSingleVehicleExcel(Vehicle vehicle) async {
    try {
      final vehicleId = vehicle.id ?? 0;

      // Fetch vehicle-specific data
      final maintenanceRecords = await DatabaseService.getMaintenanceByVehicleId(vehicleId);
      final fuelRecords = await DatabaseService.getFuelRecordsByVehicleId(vehicleId);
      final allViolations = await DatabaseService.getAllViolations();
      final violations = allViolations.where((v) => v.vehicleId == vehicleId).toList();

      final workbook = Excel.createExcel();

      // ── Sheet 1: Vehicle Info ──
      final infoSheet = workbook['بيانات المركبة'];
      workbook.delete('Sheet1');

      const infoHeaders = ['البيان', 'القيمة'];
      for (var col = 0; col < infoHeaders.length; col++) {
        final cell = infoSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(infoHeaders[col]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      final infoData = [
        ['رقم اللوحة', vehicle.plateNumber],
        ['الماركة', vehicle.make],
        ['الموديل', vehicle.model],
        ['سنة الصنع', '${vehicle.year}'],
        ['اللون', AppConstants.vehicleColors[vehicle.color] ?? vehicle.color],
        ['نوع الوقود', AppConstants.fuelTypes[vehicle.fuelType] ?? vehicle.fuelType],
        ['العداد الحالي', '${vehicle.currentOdometer}'],
        ['الحالة', AppConstants.vehicleStatuses[vehicle.status] ?? vehicle.status],
        if (vehicle.vehicleType != null && vehicle.vehicleType!.isNotEmpty)
          ['نوع المركبة', vehicle.vehicleType!],
        ['اسم السائق', vehicle.driverName ?? 'غير محدد'],
        ['رقم هاتف السائق', vehicle.driverPhone ?? 'غير محدد'],
      ];

      for (var row = 0; row < infoData.length; row++) {
        for (var col = 0; col < infoData[row].length; col++) {
          final cell = infoSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = TextCellValue(infoData[row][col]);
          cell.cellStyle = CellStyle(fontSize: 10, horizontalAlign: HorizontalAlign.Center);
        }
      }

      // ── Sheet 2: Maintenance Records ──
      final maintSheet = workbook['سجل الصيانة'];
      const maintHeaders = [
        '#', 'التاريخ', 'الوصف', 'النوع', 'تكلفة القطع (ج.م)',
        'تكلفة العمالة (ج.م)', 'الإجمالي (ج.م)', 'الحالة', 'الأولوية',
        'مقدم الخدمة', 'رقم الفاتورة', 'العداد', 'قطع الغيار', 'ملاحظات',
      ];
      for (var col = 0; col < maintHeaders.length; col++) {
        final cell = maintSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(maintHeaders[col]);
        cell.cellStyle = CellStyle(bold: true, fontSize: 11, horizontalAlign: HorizontalAlign.Center);
      }

      for (var row = 0; row < maintenanceRecords.length; row++) {
        final r = maintenanceRecords[row];
        final values = <CellValue>[
          IntCellValue(row + 1),
          TextCellValue(DateFormat('dd/MM/yyyy').format(r.maintenanceDate)),
          TextCellValue(r.description),
          TextCellValue(AppConstants.maintenanceTypes[r.type] ?? r.type),
          DoubleCellValue(r.cost),
          DoubleCellValue(r.laborCost ?? 0),
          DoubleCellValue(r.totalCost),
          TextCellValue(AppConstants.maintenanceStatuses[r.status] ?? r.status),
          TextCellValue(AppConstants.priorities[r.priority] ?? r.priority),
          TextCellValue(r.serviceProvider ?? ''),
          TextCellValue(r.invoiceNumber ?? ''),
          IntCellValue(r.odometerReading),
          TextCellValue(r.partsUsed ?? ''),
          TextCellValue(r.notes ?? ''),
        ];
        for (var col = 0; col < values.length; col++) {
          final cell = maintSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = values[col];
          cell.cellStyle = CellStyle(fontSize: 10, horizontalAlign: HorizontalAlign.Center);
        }
      }

      // ── Sheet 3: Fuel Records ──
      final fuelSheet = workbook['سجل الوقود'];
      const fuelHeaders = [
        '#', 'تاريخ التعبئة', 'العداد (كم)', 'اللترات', 'سعر اللتر (ج.م)',
        'الإجمالي (ج.م)', 'المحطة', 'الموقع', 'خزان كامل', 'معدل الاستهلاك', 'ملاحظات',
      ];
      for (var col = 0; col < fuelHeaders.length; col++) {
        final cell = fuelSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(fuelHeaders[col]);
        cell.cellStyle = CellStyle(bold: true, fontSize: 11, horizontalAlign: HorizontalAlign.Center);
      }

      for (var row = 0; row < fuelRecords.length; row++) {
        final r = fuelRecords[row];
        final values = <CellValue>[
          IntCellValue(row + 1),
          TextCellValue(DateFormat('dd/MM/yyyy').format(r.fillDate)),
          IntCellValue(r.odometerReading),
          DoubleCellValue(r.liters),
          DoubleCellValue(r.costPerLiter),
          DoubleCellValue(r.totalCost),
          TextCellValue(r.stationName ?? ''),
          TextCellValue(r.stationLocation ?? ''),
          TextCellValue(r.fullTank ? 'نعم' : 'لا'),
          TextCellValue(r.consumptionRate != null ? '${r.consumptionRate!.toStringAsFixed(1)} كم/لتر' : ''),
          TextCellValue(r.notes ?? ''),
        ];
        for (var col = 0; col < values.length; col++) {
          final cell = fuelSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = values[col];
          cell.cellStyle = CellStyle(fontSize: 10, horizontalAlign: HorizontalAlign.Center);
        }
      }

      // ── Sheet 4: Violations ──
      final violSheet = workbook['المخالفات'];
      const violHeaders = [
        '#', 'التاريخ', 'الوصف', 'النوع', 'المبلغ (ج.م)', 'النقاط', 'الحالة',
      ];
      for (var col = 0; col < violHeaders.length; col++) {
        final cell = violSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(violHeaders[col]);
        cell.cellStyle = CellStyle(bold: true, fontSize: 11, horizontalAlign: HorizontalAlign.Center);
      }

      for (var row = 0; row < violations.length; row++) {
        final v = violations[row];
        final values = <CellValue>[
          IntCellValue(row + 1),
          TextCellValue(DateFormat('dd/MM/yyyy').format(v.date)),
          TextCellValue(v.description),
          TextCellValue(v.type),
          DoubleCellValue(v.amount),
          IntCellValue(v.points),
          TextCellValue(v.status),
        ];
        for (var col = 0; col < values.length; col++) {
          final cell = violSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = values[col];
          cell.cellStyle = CellStyle(fontSize: 10, horizontalAlign: HorizontalAlign.Center);
        }
      }

      final bytes = workbook.save();
      if (bytes == null) {
        debugPrint('ReportService: generateSingleVehicleExcel workbook save returned null');
        return '';
      }
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'مركبة_${vehicle.plateNumber}_$dateStr.xlsx';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateSingleVehicleExcel error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PDF Report: Single Maintenance Record
  // ═════════════════════════════════════════════════════════════════════════

  static Future<String> generateSingleMaintenancePDF(MaintenanceRecord record) async {
    try {
      final font = await _loadCairoFont();
      final watermarkImage = await _loadWatermarkImage();
      final now = DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.now());

      // Pre-build header
      final headerWidgets = await buildPdfHeader(
        title: 'تقرير عطل - ${record.description}',
        subtitle: '${AppConstants.appName} – $now',
      );

      final vehicleLabel = record.vehicle != null
          ? '${record.vehicle!.make} ${record.vehicle!.model}'
          : 'غير معروف';
      final plateLabel = record.vehicle?.plateNumber ?? '';

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: font),
      );

      // Common table border style
      const tableBorder = pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300),
        verticalInside: pw.BorderSide(color: PdfColors.grey300),
        left: pw.BorderSide(color: PdfColors.grey400),
        right: pw.BorderSide(color: PdfColors.grey400),
        top: pw.BorderSide(color: PdfColors.grey400),
        bottom: pw.BorderSide(color: PdfColors.grey400),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
              wrapWithWatermark(watermarkImage, [
                ...headerWidgets,
                pw.SizedBox(height: 8),

                // ── Vehicle Info ──
                pw.Text(
                  'بيانات المركبة',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['البيان', 'القيمة'],
                  data: [
                    ['المركبة', vehicleLabel],
                    ['رقم اللوحة', plateLabel],
                  ],
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  border: tableBorder,
                ),
                pw.SizedBox(height: 16),

                // ── Maintenance Details ──
                pw.Text(
                  'تفاصيل العطل',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['البيان', 'القيمة'],
                  data: [
                    ['التاريخ', DateFormat('dd/MM/yyyy').format(record.maintenanceDate)],
                    ['الوصف', record.description],
                    ['النوع', AppConstants.maintenanceTypes[record.type] ?? record.type],
                    ['الحالة', AppConstants.maintenanceStatuses[record.status] ?? record.status],
                    ['الأولوية', AppConstants.priorities[record.priority] ?? record.priority],
                    ['العداد عند الصيانة', '${record.odometerReading} كم'],
                    ['مقدم الخدمة', record.serviceProvider ?? 'غير محدد'],
                    ['رقم الفاتورة', record.invoiceNumber ?? 'غير محدد'],
                    ['قطع الغيار', record.partsUsed ?? 'لا توجد'],
                    ['ملاحظات', record.notes ?? 'لا توجد'],
                    if (record.nextMaintenanceDate != null)
                      ['تاريخ الصيانة القادمة', DateFormat('dd/MM/yyyy').format(record.nextMaintenanceDate!)],
                    if (record.nextMaintenanceKm != null)
                      ['العداد القادم للصيانة', '${record.nextMaintenanceKm} كم'],
                  ],
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  border: tableBorder,
                ),
                pw.SizedBox(height: 16),

                // ── Cost Breakdown ──
                pw.Text(
                  'تفصيل التكلفة',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['البند', 'المبلغ (ج.م)'],
                  data: [
                    ['تكلفة القطع', record.cost.toStringAsFixed(2)],
                    ['تكلفة العمالة', (record.laborCost ?? 0).toStringAsFixed(2)],
                    ['الإجمالي', record.totalCost.toStringAsFixed(2)],
                  ],
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  border: tableBorder,
                ),
              ]),
            ],
        ),
      );

      final bytes = await pdf.save();
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'عطل_${plateLabel}_$dateStr.pdf';
      return _shareBytes(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateSingleMaintenancePDF error: $e');
      return '';
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  static String _workOrderTypeLabel(String type) {
    switch (type) {
      case 'maintenance': return 'صيانة';
      case 'repair': return 'إصلاح';
      case 'inspection': return 'فحص';
      default: return type;
    }
  }

  static String _workOrderStatusLabel(String status) {
    switch (status) {
      case 'open': return 'مفتوح';
      case 'in_progress': return 'قيد التنفيذ';
      case 'completed': return 'مكتمل';
      default: return status;
    }
  }
}

// ── Helper class for monthly cost grouping ───────────────────────────────
class _MonthCostRow {
  String vehicleLabel;
  String plateLabel;
  String month;
  double maintenance;
  double fuel;
  double violations;
  double insurance;
  double other;

  _MonthCostRow({
    required this.vehicleLabel,
    required this.plateLabel,
    required this.month,
    this.maintenance = 0,
    this.fuel = 0,
    this.violations = 0,
    this.insurance = 0,
    this.other = 0,
  });
}
