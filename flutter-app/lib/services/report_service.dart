import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist.dart';
import '../models/fuel_record.dart';
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

class ReportService {
  ReportService._();

  // ── Font loading ─────────────────────────────────────────────────────────

  /// Loads the Cairo-Regular.ttf bundled font for Arabic PDF text.
  static Future<pw.Font> _loadCairoFont() async {
    final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  /// Saves [bytes] to a temporary file named [fileName] inside the system
  /// temp directory and then opens the system share sheet.
  ///
  /// Returns the file path on success, or an empty string on failure.
  static Future<String> _saveAndShare(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: '');
      return file.path;
    } catch (e) {
      debugPrint('ReportService: error saving/sharing file: $e');
      return '';
    }
  }

  /// Saves an [Excel] workbook to a temporary file and shares it.
  static Future<String> _saveAndShareExcel(
    Excel workbook,
    String fileName,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      final bytes = workbook.save();
      if (bytes == null) {
        debugPrint('ReportService: workbook save returned null');
        return '';
      }
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: '');
      return file.path;
    } catch (e) {
      debugPrint('ReportService: error saving/sharing Excel: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PDF Report: Maintenance Records
  // ═════════════════════════════════════════════════════════════════════════

  /// Generates a PDF report of all maintenance records and shares it.
  ///
  /// Returns the file path, or an empty string on failure.
  static Future<String> generateMaintenancePDF() async {
    try {
      final font = await _loadCairoFont();
      final records = await DatabaseService.getAllMaintenanceRecords();
      final now = DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.now());

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font, // Cairo-Regular for everything (single-weight font)
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            // ── Header ────────────────────────────────────────────────
            pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'تقرير سجلات الصيانة',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${AppConstants.appName} – $now',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),

            // ── Summary ───────────────────────────────────────────────
            pw.Text(
              'إجمالي السجلات: ${records.length}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),

            // ── Table ─────────────────────────────────────────────────
            if (records.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headers: [
                  '#',
                  'المركبة',
                  'التاريخ',
                  'الوصف',
                  'النوع',
                  'التكلفة',
                  'الحالة',
                  'الأولوية',
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
                    '$i',
                    vehicleLabel,
                    dateLabel,
                    r.description,
                    typeLabel,
                    '${r.totalCost.toStringAsFixed(2)} ج.م',
                    statusLabel,
                    priorityLabel,
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
                rowDecoration: pw.BoxDecoration(
                  colorFn: (index) =>
                      index.isEven ? PdfColors.grey100 : PdfColors.white,
                ),
              )
            else
              pw.Center(
                child: pw.Text(
                  'لا توجد سجلات صيانة',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey500),
                ),
              ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'تقرير_الصيانة_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      return _saveAndShare(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateMaintenancePDF error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  PDF Report: Vehicles Fleet Overview
  // ═════════════════════════════════════════════════════════════════════════

  /// Generates a PDF of the vehicle fleet overview and shares it.
  static Future<String> generateVehiclesPDF() async {
    try {
      final font = await _loadCairoFont();
      final vehicles = await DatabaseService.getAllVehicles();
      final now = DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.now());

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: font),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            // ── Header ────────────────────────────────────────────────
            pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'تقرير أسطول المركبات',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${AppConstants.appName} – $now',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 12),

            // ── Summary row ───────────────────────────────────────────
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

            // ── Table ─────────────────────────────────────────────────
            if (vehicles.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headers: [
                  '#',
                  'رقم اللوحة',
                  'الماركة',
                  'الموديل',
                  'السنة',
                  'اللون',
                  'الوقود',
                  'العداد',
                  'الحالة',
                ],
                data: vehicles.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final v = entry.value;
                  final colorLabel =
                      AppConstants.vehicleColors[v.color] ?? v.color;
                  final fuelLabel =
                      AppConstants.fuelTypes[v.fuelType] ?? v.fuelType;
                  final statusLabel =
                      AppConstants.vehicleStatuses[v.status] ?? v.status;

                  return [
                    '$i',
                    v.plateNumber,
                    v.make,
                    v.model,
                    '${v.year}',
                    colorLabel,
                    fuelLabel,
                    '${v.currentOdometer} كم',
                    statusLabel,
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
                rowDecoration: pw.BoxDecoration(
                  colorFn: (index) =>
                      index.isEven ? PdfColors.grey100 : PdfColors.white,
                ),
              )
            else
              pw.Center(
                child: pw.Text(
                  'لا توجد مركبات',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey500),
                ),
              ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'تقرير_الأسطول_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      return _saveAndShare(bytes, fileName);
    } catch (e) {
      debugPrint('ReportService: generateVehiclesPDF error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Excel Report: Fuel Records
  // ═════════════════════════════════════════════════════════════════════════

  /// Generates an Excel report of all fuel records and shares it.
  static Future<String> generateFuelExcel() async {
    try {
      final records = await DatabaseService.getAllFuelRecords();
      final workbook = Excel.createExcel();
      final sheet = workbook['سجلات الوقود'];

      // Remove the default empty sheet that excel package creates
      workbook.delete('Sheet1');

      // ── Headers ────────────────────────────────────────────────────
      const headers = [
        '#',
        'المركبة',
        'رقم اللوحة',
        'تاريخ التعبئة',
        'العداد (كم)',
        'اللترات',
        'سعر اللتر (ج.م)',
        'الإجمالي (ج.م)',
        'نوع الوقود',
        'المحطة',
        'الموقع',
        'خزان كامل',
        'معدل الاستهلاك',
        'غير طبيعي',
        'ملاحظات',
      ];

      final headerCellStyle = CellValuetype.text;
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
          TextCellValue('${row + 1}'),
          TextCellValue(vehicleLabel),
          TextCellValue(plateLabel),
          TextCellValue(dateLabel),
          TextCellValue('${r.odometerReading}'),
          TextCellValue(r.liters.toStringAsFixed(1)),
          TextCellValue(r.costPerLiter.toStringAsFixed(2)),
          TextCellValue(r.totalCost.toStringAsFixed(2)),
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

      // ── Auto-fit column widths (approximate) ───────────────────────
      for (var col = 0; col < headers.length; col++) {
        sheet.setColWidth(col, 18);
      }

      final fileName = 'سجلات_الوقود_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      return _saveAndShareExcel(workbook, fileName);
    } catch (e) {
      debugPrint('ReportService: generateFuelExcel error: $e');
      return '';
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Excel Report: Checklists
  // ═════════════════════════════════════════════════════════════════════════

  /// Generates an Excel report of all checklists and shares it.
  static Future<String> generateChecklistExcel() async {
    try {
      final checklists = await DatabaseService.getAllChecklists();
      final workbook = Excel.createExcel();
      final sheet = workbook['قوائم الفحص'];

      workbook.delete('Sheet1');

      // ── Headers ────────────────────────────────────────────────────
      const headers = [
        '#',
        'المركبة',
        'رقم اللوحة',
        'نوع الفحص',
        'تاريخ الفحص',
        'العداد (كم)',
        'المفتش',
        'عدد البنود',
        'بنود مكتملة',
        'بنود بها عيوب',
        'التقييم',
        'الحالة',
        'ملاحظات',
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
          TextCellValue('${row + 1}'),
          TextCellValue(vehicleLabel),
          TextCellValue(plateLabel),
          TextCellValue(typeLabel),
          TextCellValue(dateLabel),
          TextCellValue('${c.odometerReading}'),
          TextCellValue(c.inspectorName ?? ''),
          TextCellValue('${c.items.length}'),
          TextCellValue('${c.checkedCount}'),
          TextCellValue('${c.defectCount}'),
          TextCellValue(c.overallScore.toStringAsFixed(1)),
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

      // ── Column widths ──────────────────────────────────────────────
      for (var col = 0; col < headers.length; col++) {
        sheet.setColWidth(col, 18);
      }

      final fileName = 'قوائم_الفحص_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      return _saveAndShareExcel(workbook, fileName);
    } catch (e) {
      debugPrint('ReportService: generateChecklistExcel error: $e');
      return '';
    }
  }
}
