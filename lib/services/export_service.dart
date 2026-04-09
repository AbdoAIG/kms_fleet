import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class ExportService {
  ExportService._();

  static pw.Font? _cachedFont;

  // ===================== FONT LOADING =====================

  static Future<pw.Font> _loadArabicFont() async {
    if (_cachedFont != null) return _cachedFont!;
    final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
    final byteData = fontData.buffer.asByteData();
    _cachedFont = pw.Font.ttf(byteData);
    return _cachedFont!;
  }

  static Future<pw.ThemeData> _buildTheme() async {
    final font = await _loadArabicFont();
    // استخدام خط Cairo لكل الأوزان (bold, italic) لتجنب Helvetica التي لا تدعم العربية
    return pw.ThemeData.withFont(
      base: font,
      bold: font,
      italic: font,
      boldItalic: font,
    );
  }

  // ===================== COLOR HELPERS =====================

  /// Blend a PdfColor with white background at given opacity
  static PdfColor _pdfColorOpacity(PdfColor color, double opacity) {
    return PdfColor(
      color.red * opacity + (1.0 - opacity),
      color.green * opacity + (1.0 - opacity),
      color.blue * opacity + (1.0 - opacity),
    );
  }

  // ===================== PDF EXPORT =====================

  /// تصدير تقرير PDF شامل
  static Future<String> exportMaintenancePdf() async {
    final vehicles = await DatabaseService.getAllVehicles();
    final records = await DatabaseService.getAllMaintenanceRecords();
    final stats = await DatabaseService.getDashboardStats();
    final typeData = await DatabaseService.getMaintenanceByType();
    final vehicleData = await DatabaseService.getVehicleMaintenanceCosts();

    final theme = await _buildTheme();
    final pdf = pw.Document(theme: theme);
    final rtl = pw.TextDirection.rtl;

    pdf.addPage(
      pw.MultiPage(
        textDirection: rtl,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(rtl),
        footer: (context) => _buildPdfFooter(context, rtl),
        build: (context) => [
          // عنوان التقرير
          pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text('تقرير صيانة الأسطول الشامل',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                    textDirection: rtl),
                pw.SizedBox(height: 4),
                pw.Text(AppFormatters.formatDate(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600), textDirection: rtl),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // بطاقات الإحصائيات
          _buildStatsSection(stats, rtl),
          pw.SizedBox(height: 20),

          // جدول تكاليف المركبات
          if (vehicleData.isNotEmpty) ...[
            _buildSectionTitle('تكاليف الصيانة حسب المركبة', rtl),
            pw.SizedBox(height: 8),
            _buildVehicleCostTable(vehicleData, rtl),
            pw.SizedBox(height: 16),
          ],

          // جدول الأنواع
          if (typeData.isNotEmpty) ...[
            _buildSectionTitle('توزيع التكاليف حسب نوع الصيانة', rtl),
            pw.SizedBox(height: 8),
            _buildTypeCostTable(typeData, rtl),
            pw.SizedBox(height: 16),
          ],

          // تفاصيل سجلات الصيانة
          _buildSectionTitle('تفاصيل سجلات الصيانة', rtl),
          pw.SizedBox(height: 8),
          _buildMaintenanceDetailsTable(records, rtl),
          pw.SizedBox(height: 16),

          // جدول المركبات
          _buildSectionTitle('قائمة المركبات', rtl),
          pw.SizedBox(height: 8),
          _buildVehiclesTable(vehicles, rtl),
        ],
      ),
    );

    return await _saveAndSharePdf(pdf, 'تقرير_صيانة_الأسطول');
  }

  /// تصدير تقرير PDF لمركبة محددة
  static Future<String> exportVehiclePdf(int vehicleId) async {
    final vehicle = await DatabaseService.getVehicleById(vehicleId);
    if (vehicle == null) throw Exception('المركبة غير موجودة');

    final records = await DatabaseService.getMaintenanceByVehicleId(vehicleId);
    final completed = records.where((r) => r.status == 'completed').toList();
    double totalCost = 0;
    for (final r in completed) {
      totalCost += r.totalCost;
    }

    final theme = await _buildTheme();
    final pdf = pw.Document(theme: theme);
    final rtl = pw.TextDirection.rtl;

    pdf.addPage(
      pw.MultiPage(
        textDirection: rtl,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(rtl),
        footer: (context) => _buildPdfFooter(context, rtl),
        build: (context) => [
          pw.Center(
            child: pw.Text('تقرير صيانة مركبة',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                textDirection: rtl),
          ),
          pw.SizedBox(height: 20),
          _buildVehicleInfoCard(vehicle, totalCost, completed.length, rtl),
          pw.SizedBox(height: 20),
          if (records.isNotEmpty) ...[
            _buildSectionTitle('سجل الصيانة', rtl),
            pw.SizedBox(height: 8),
            _buildSingleVehicleRecordsTable(records, rtl),
          ] else ...[
            pw.Center(
              child: pw.Text('لا توجد سجلات صيانة لهذه المركبة',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey500), textDirection: rtl),
            ),
          ],
        ],
      ),
    );

    return await _saveAndSharePdf(pdf, 'تقرير_صيانة_${vehicle.plateNumber}');
  }

  // ===================== EXCEL EXPORT =====================

  /// تصدير البيانات إلى Excel
  static Future<String> exportExcel() async {
    final vehicles = await DatabaseService.getAllVehicles();
    final records = await DatabaseService.getAllMaintenanceRecords();
    final stats = await DatabaseService.getDashboardStats();
    final typeData = await DatabaseService.getMaintenanceByType();

    final excel = Excel.createExcel();

    _buildVehiclesSheet(excel, vehicles);
    _buildMaintenanceSheet(excel, records);
    _buildStatsSheet(excel, stats, typeData);

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل في إنشاء ملف Excel');

    return await _saveAndShareBytes(
      Uint8List.fromList(bytes),
      'بيانات_الأسطول.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // ===================== PDF HEADER / FOOTER =====================

  static pw.Widget _buildPdfHeader(pw.TextDirection rtl) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal300, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('KMS Fleet - نظام إدارة الأسطول',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700),
              textDirection: rtl),
          pw.Text(AppConstants.appNameAr,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600), textDirection: rtl),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context, pw.TextDirection rtl) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500), textDirection: rtl),
        ],
      ),
    );
  }

  // ===================== PDF SECTION BUILDERS =====================

  static pw.Widget _buildSectionTitle(String title, pw.TextDirection rtl) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.teal200),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
          textDirection: rtl),
    );
  }

  static pw.Widget _buildStatsSection(Map<String, dynamic> stats, pw.TextDirection rtl) {
    final totalCost = (stats['totalCost'] as num?)?.toDouble() ?? 0;
    final vehicleCount = stats['vehicleCount'] as int? ?? 0;
    final pendingRecords = stats['pendingRecords'] as int? ?? 0;
    final maintenanceVehicles = stats['maintenanceVehicles'] as int? ?? 0;

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatBox('إجمالي المركبات', '$vehicleCount', PdfColors.teal700, rtl),
        _buildStatBox('تكاليف الصيانة', AppFormatters.formatCurrency(totalCost), PdfColors.orange700, rtl),
        _buildStatBox('معلقة', '$pendingRecords', PdfColors.red700, rtl),
        _buildStatBox('في الصيانة', '$maintenanceVehicles', PdfColors.amber700, rtl),
      ],
    );
  }

  static pw.Widget _buildStatBox(String title, String value, PdfColor color, pw.TextDirection rtl) {
    final bgColor = _pdfColorOpacity(color, 0.08);
    final borderColor = _pdfColorOpacity(color, 0.3);

    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 9, color: color, fontWeight: pw.FontWeight.bold), textDirection: rtl),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 13, color: color, fontWeight: pw.FontWeight.bold), textDirection: rtl),
        ],
      ),
    );
  }

  // ===================== PDF TABLE BUILDER =====================

  /// Generic table builder compatible with pdf 3.12+
  static pw.Widget _buildPdfTable({
    required List<String> headers,
    required List<List<pw.Widget>> dataRows,
    required List<double> columnWidths,
    pw.TextDirection rtl = pw.TextDirection.rtl,
    bool showTotalRow = false,
    List<pw.Widget>? totalRow,
  }) {
    final allRows = <pw.TableRow>[];

    // Header row
    allRows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.teal700),
      children: headers
          .map((h) => pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h,
                    style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    textDirection: rtl,
                    textAlign: pw.TextAlign.center),
              ))
          .toList(),
    ));

    // Data rows
    for (int i = 0; i < dataRows.length; i++) {
      final isEven = i % 2 == 0;
      allRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey50 : PdfColors.white),
        children: dataRows[i],
      ));
    }

    // Total row
    if (showTotalRow && totalRow != null) {
      allRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfColors.teal50,
          border: pw.Border(top: pw.BorderSide(color: PdfColors.teal300, width: 1.5)),
        ),
        children: totalRow,
      ));
    }

    // Build columnWidths map
    final widths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < columnWidths.length; i++) {
      widths[i] = pw.FixedColumnWidth(columnWidths[i]);
    }

    return pw.Table(
      columnWidths: widths,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: allRows,
    );
  }

  static pw.Widget _buildCell(String text, {double fontSize = 9, pw.FontWeight? fontWeight, PdfColor? textColor, pw.TextAlign? textAlign, pw.TextDirection? textDirection}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
        ),
        textDirection: textDirection,
        textAlign: textAlign ?? pw.TextAlign.center,
      ),
    );
  }

  // ===================== PDF VEHICLE COST TABLE =====================

  static pw.Widget _buildVehicleCostTable(List<Map<String, dynamic>> data, pw.TextDirection rtl) {
    final dataRows = <List<pw.Widget>>[];
    double grandTotal = 0;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final cost = (item['total_cost'] as num?)?.toDouble() ?? 0;
      grandTotal += cost;

      dataRows.add([
        _buildCell('${i + 1}'),
        _buildCell('${item['make']} ${item['model']}', textDirection: rtl, textAlign: pw.TextAlign.right),
        _buildCell('${item['plate_number']}'),
        _buildCell('${item['record_count']}'),
        _buildCell(AppFormatters.formatCurrency(cost), fontWeight: pw.FontWeight.bold),
      ]);
    }

    return _buildPdfTable(
      headers: ['#', 'المركبة', 'رقم اللوحة', 'العمليات', 'التكلفة الإجمالية'],
      dataRows: dataRows,
      columnWidths: [25, 120, 70, 45, 80],
      rtl: rtl,
      showTotalRow: true,
      totalRow: [
        _buildCell(''),
        _buildCell(''),
        _buildCell(''),
        _buildCell('الإجمالي', fontWeight: pw.FontWeight.bold, textDirection: rtl),
        _buildCell(AppFormatters.formatCurrency(grandTotal), fontWeight: pw.FontWeight.bold, textColor: PdfColors.teal800),
      ],
    );
  }

  // ===================== PDF TYPE COST TABLE =====================

  static pw.Widget _buildTypeCostTable(List<Map<String, dynamic>> data, pw.TextDirection rtl) {
    final dataRows = <List<pw.Widget>>[];
    double total = 0;

    for (final item in data) {
      final cost = (item['total_cost'] as num?)?.toDouble() ?? 0;
      total += cost;
      final type = AppConstants.maintenanceTypes[item['type'] ?? 'other'] ?? '';

      dataRows.add([
        _buildCell(type, textDirection: rtl, textAlign: pw.TextAlign.right),
        _buildCell('${item['count']}'),
        _buildCell(AppFormatters.formatCurrency(cost), fontWeight: pw.FontWeight.bold),
      ]);
    }

    return _buildPdfTable(
      headers: ['نوع الصيانة', 'عدد العمليات', 'التكلفة'],
      dataRows: dataRows,
      columnWidths: [120, 60, 80],
      rtl: rtl,
      showTotalRow: true,
      totalRow: [
        _buildCell('الإجمالي', fontWeight: pw.FontWeight.bold, textDirection: rtl),
        _buildCell(''),
        _buildCell(AppFormatters.formatCurrency(total), fontWeight: pw.FontWeight.bold, textColor: PdfColors.teal800),
      ],
    );
  }

  // ===================== PDF MAINTENANCE DETAILS TABLE =====================

  static pw.Widget _buildMaintenanceDetailsTable(List<MaintenanceRecord> records, pw.TextDirection rtl) {
    final dataRows = <List<pw.Widget>>[];

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final vehicleName = r.vehicle != null ? '${r.vehicle!.make} ${r.vehicle!.model}' : 'غير معروف';
      final type = AppConstants.maintenanceTypes[r.type] ?? '';
      final status = AppConstants.maintenanceStatuses[r.status] ?? '';

      PdfColor statusColor = PdfColors.grey700;
      if (r.status == 'completed') {
        statusColor = PdfColors.green700;
      } else if (r.status == 'pending') {
        statusColor = PdfColors.orange700;
      } else if (r.status == 'urgent') {
        statusColor = PdfColors.red700;
      }

      dataRows.add([
        _buildCell('${i + 1}', fontSize: 8),
        _buildCell(vehicleName, fontSize: 8, textDirection: rtl, textAlign: pw.TextAlign.right),
        _buildCell(type, fontSize: 8, textDirection: rtl, textAlign: pw.TextAlign.right),
        _buildCell(AppFormatters.formatDate(r.maintenanceDate), fontSize: 8),
        _buildCell(AppFormatters.formatCurrency(r.totalCost), fontSize: 8, fontWeight: pw.FontWeight.bold),
        _buildCell(status, fontSize: 8, textColor: statusColor, textDirection: rtl),
      ]);
    }

    return _buildPdfTable(
      headers: ['#', 'المركبة', 'النوع', 'التاريخ', 'التكلفة', 'الحالة'],
      dataRows: dataRows,
      columnWidths: [20, 80, 50, 55, 55, 50],
      rtl: rtl,
    );
  }

  // ===================== PDF VEHICLES TABLE =====================

  static pw.Widget _buildVehiclesTable(List<Vehicle> vehicles, pw.TextDirection rtl) {
    final dataRows = <List<pw.Widget>>[];

    for (int i = 0; i < vehicles.length; i++) {
      final v = vehicles[i];
      final status = AppConstants.vehicleStatuses[v.status] ?? '';

      dataRows.add([
        _buildCell('${i + 1}', fontSize: 8),
        _buildCell('${v.make} ${v.model}', fontSize: 8, textDirection: rtl, textAlign: pw.TextAlign.right),
        _buildCell(v.plateNumber, fontSize: 8),
        _buildCell('${v.year}', fontSize: 8),
        _buildCell(status, fontSize: 8, textDirection: rtl),
        _buildCell(AppFormatters.formatOdometer(v.currentOdometer), fontSize: 8),
      ]);
    }

    return _buildPdfTable(
      headers: ['#', 'المركبة', 'رقم اللوحة', 'السنة', 'الحالة', 'عداد الكيلومترات'],
      dataRows: dataRows,
      columnWidths: [20, 80, 60, 35, 40, 55],
      rtl: rtl,
    );
  }

  // ===================== PDF SINGLE VEHICLE RECORDS TABLE =====================

  static pw.Widget _buildSingleVehicleRecordsTable(List<MaintenanceRecord> records, pw.TextDirection rtl) {
    final dataRows = <List<pw.Widget>>[];

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final type = AppConstants.maintenanceTypes[r.type] ?? '';
      final status = AppConstants.maintenanceStatuses[r.status] ?? '';

      dataRows.add([
        _buildCell('${i + 1}', fontSize: 8),
        _buildCell(AppFormatters.formatDate(r.maintenanceDate), fontSize: 8),
        _buildCell(type, fontSize: 8, textDirection: rtl, textAlign: pw.TextAlign.right),
        _buildCell(r.description, fontSize: 8, textDirection: rtl, textAlign: pw.TextAlign.right),
        _buildCell(AppFormatters.formatCurrency(r.totalCost), fontSize: 8, fontWeight: pw.FontWeight.bold),
        _buildCell(status, fontSize: 8, textDirection: rtl),
      ]);
    }

    return _buildPdfTable(
      headers: ['#', 'التاريخ', 'النوع', 'الوصف', 'التكلفة', 'الحالة'],
      dataRows: dataRows,
      columnWidths: [20, 55, 45, 100, 55, 45],
      rtl: rtl,
    );
  }

  // ===================== PDF VEHICLE INFO CARD =====================

  static pw.Widget _buildVehicleInfoCard(Vehicle vehicle, double totalCost, int completedCount, pw.TextDirection rtl) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal300),
        borderRadius: pw.BorderRadius.circular(10),
        color: PdfColors.teal50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('${vehicle.make} ${vehicle.model} ${vehicle.year}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
              textDirection: rtl),
          pw.SizedBox(height: 4),
          pw.Text(vehicle.plateNumber,
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: pw.WrapAlignment.center,
            children: [
              _buildInfoItem('عدد عمليات الصيانة', '$completedCount', rtl),
              _buildInfoItem('إجمالي التكاليف', AppFormatters.formatCurrency(totalCost), rtl),
              _buildInfoItem('عداد الكيلومترات', AppFormatters.formatOdometer(vehicle.currentOdometer), rtl),
              _buildInfoItem('الحالة', AppConstants.vehicleStatuses[vehicle.status] ?? '', rtl),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoItem(String label, String value, pw.TextDirection rtl) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600), textDirection: rtl),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
            textDirection: rtl),
      ],
    );
  }

  // ===================== EXCEL HELPERS =====================

  static void _setCell(Sheet sheet, int col, int row, dynamic value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value;
  }

  static void _buildVehiclesSheet(Excel excel, List<Vehicle> vehicles) {
    final sheet = excel['المركبات'];
    final headers = ['#', 'المركبة', 'رقم اللوحة', 'السنة', 'اللون', 'نوع الوقود', 'عداد الكيلومترات', 'الحالة', 'ملاحظات'];

    for (int col = 0; col < headers.length; col++) {
      _setCell(sheet, col, 0, TextCellValue(headers[col]));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = CellStyle(bold: true);
    }

    for (int i = 0; i < vehicles.length; i++) {
      final v = vehicles[i];
      final row = i + 1;
      _setCell(sheet, 0, row, TextCellValue('${i + 1}'));
      _setCell(sheet, 1, row, TextCellValue('${v.make} ${v.model}'));
      _setCell(sheet, 2, row, TextCellValue(v.plateNumber));
      _setCell(sheet, 3, row, IntCellValue(v.year));
      _setCell(sheet, 4, row, TextCellValue(AppConstants.vehicleColors[v.color] ?? v.color));
      _setCell(sheet, 5, row, TextCellValue(AppConstants.fuelTypes[v.fuelType] ?? v.fuelType));
      _setCell(sheet, 6, row, IntCellValue(v.currentOdometer));
      _setCell(sheet, 7, row, TextCellValue(AppConstants.vehicleStatuses[v.status] ?? v.status));
      _setCell(sheet, 8, row, TextCellValue(v.notes ?? ''));
    }
  }

  static void _buildMaintenanceSheet(Excel excel, List<MaintenanceRecord> records) {
    final sheet = excel['سجلات الصيانة'];
    final headers = ['#', 'المركبة', 'رقم اللوحة', 'تاريخ الصيانة', 'النوع', 'الوصف', 'التكلفة', 'تكلفة العمالة', 'التكلفة الكلية', 'مقدم الخدمة', 'رقم الفاتورة', 'الأولوية', 'الحالة', 'عداد الكيلومترات', 'ملاحظات'];

    for (int col = 0; col < headers.length; col++) {
      _setCell(sheet, col, 0, TextCellValue(headers[col]));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = CellStyle(bold: true);
    }

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final row = i + 1;
      final vehicleName = r.vehicle != null ? '${r.vehicle!.make} ${r.vehicle!.model}' : '';
      final plateNumber = r.vehicle?.plateNumber ?? '';

      _setCell(sheet, 0, row, TextCellValue('${i + 1}'));
      _setCell(sheet, 1, row, TextCellValue(vehicleName));
      _setCell(sheet, 2, row, TextCellValue(plateNumber));
      _setCell(sheet, 3, row, TextCellValue(AppFormatters.formatDate(r.maintenanceDate)));
      _setCell(sheet, 4, row, TextCellValue(AppConstants.maintenanceTypes[r.type] ?? ''));
      _setCell(sheet, 5, row, TextCellValue(r.description));
      _setCell(sheet, 6, row, DoubleCellValue(r.cost));
      _setCell(sheet, 7, row, DoubleCellValue(r.laborCost ?? 0));
      _setCell(sheet, 8, row, DoubleCellValue(r.totalCost));
      _setCell(sheet, 9, row, TextCellValue(r.serviceProvider ?? ''));
      _setCell(sheet, 10, row, TextCellValue(r.invoiceNumber ?? ''));
      _setCell(sheet, 11, row, TextCellValue(AppConstants.priorities[r.priority] ?? ''));
      _setCell(sheet, 12, row, TextCellValue(AppConstants.maintenanceStatuses[r.status] ?? ''));
      _setCell(sheet, 13, row, IntCellValue(r.odometerReading));
      _setCell(sheet, 14, row, TextCellValue(r.notes ?? ''));
    }
  }

  static void _buildStatsSheet(Excel excel, Map<String, dynamic> stats, List<Map<String, dynamic>> typeData) {
    final sheet = excel['الإحصائيات'];

    _setCell(sheet, 0, 0, TextCellValue('ملخص الإحصائيات'));
    _setCell(sheet, 1, 0, TextCellValue('القيمة'));

    final summaryData = [
      ['إجمالي المركبات', '${stats['vehicleCount'] ?? 0}'],
      ['المركبات النشطة', '${stats['activeVehicles'] ?? 0}'],
      ['المركبات في الصيانة', '${stats['maintenanceVehicles'] ?? 0}'],
      ['إجمالي تكاليف الصيانة', '${(stats['totalCost'] as num?)?.toDouble() ?? 0}'],
      ['سجلات معلقة', '${stats['pendingRecords'] ?? 0}'],
      ['سجلات قيد التنفيذ', '${stats['inProgressRecords'] ?? 0}'],
      ['سجلات عاجلة', '${stats['urgentRecords'] ?? 0}'],
    ];

    for (int i = 0; i < summaryData.length; i++) {
      _setCell(sheet, 0, i + 1, TextCellValue(summaryData[i][0]));
      _setCell(sheet, 1, i + 1, TextCellValue(summaryData[i][1]));
    }

    // Type breakdown
    final startRow = summaryData.length + 3;
    _setCell(sheet, 0, startRow, TextCellValue('توزيع التكاليف حسب النوع'));
    _setCell(sheet, 1, startRow, TextCellValue('العدد'));
    _setCell(sheet, 2, startRow, TextCellValue('التكلفة'));

    for (int i = 0; i < typeData.length; i++) {
      final item = typeData[i];
      final type = AppConstants.maintenanceTypes[item['type'] ?? 'other'] ?? '';
      _setCell(sheet, 0, startRow + i + 1, TextCellValue(type));
      _setCell(sheet, 1, startRow + i + 1, TextCellValue('${item['count'] ?? 0}'));
      _setCell(sheet, 2, startRow + i + 1, TextCellValue('${item['total_cost'] ?? 0}'));
    }
  }

  // ===================== FILE HELPERS =====================

  static Future<String> _saveAndSharePdf(pw.Document pdf, String fileName) async {
    if (!kIsWeb && Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
    }

    final bytes = await pdf.save();
    final directory = await _getDownloadsDirectory();
    final filePath = '$directory/$fileName.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(filePath)], subject: fileName);
    return filePath;
  }

  static Future<String> _saveAndShareBytes(Uint8List bytes, String fileName, String mimeType) async {
    if (!kIsWeb && Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
    }

    final directory = await _getDownloadsDirectory();
    final filePath = '$directory/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(filePath)], subject: fileName);
    return filePath;
  }

  static Future<String> _getDownloadsDirectory() async {
    if (kIsWeb) return '.';
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return dir?.path ?? '/storage/emulated/0/Download';
    }
    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
    // Windows / macOS / Linux
    final dir = await getDownloadsDirectory();
    return dir?.path ?? (await getApplicationDocumentsDirectory()).path;
  }
}
