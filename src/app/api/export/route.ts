import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { logActivity } from '@/app/api/activity-log/route';

// Helper: convert value to CSV-safe string
function csvEscape(val: unknown): string {
  if (val === null || val === undefined) return '';
  const str = String(val);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

// Helper: build CSV content with BOM for Arabic encoding
function buildCsv(headers: string[], rows: string[][]): string {
  const bom = '\uFEFF'; // UTF-8 BOM for proper Arabic display in Excel
  const headerLine = headers.join(',');
  const dataLines = rows.map((row) => row.map(csvEscape).join(','));
  return bom + [headerLine, ...dataLines].join('\n');
}

// GET /api/export?type=vehicles|maintenance|reports
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const type = searchParams.get('type') || '';

    let csvContent: string;
    let filename: string;

    switch (type) {
      case 'vehicles': {
        const vehicles = await db.vehicle.findMany({
          include: {
            _count: { select: { maintenanceRecords: true } },
          },
          orderBy: { createdAt: 'desc' },
        });

        const statusMap: Record<string, string> = {
          ACTIVE: 'نشط',
          MAINTENANCE: 'في الصيانة',
          OUT_OF_SERVICE: 'خارج الخدمة',
          SOLD: 'مباع',
        };

        const fuelMap: Record<string, string> = {
          PETROL: 'بنزين',
          DIESEL: 'ديزل',
          ELECTRIC: 'كهرباء',
          HYBRID: 'هجين',
        };

        const headers = [
          'رقم اللوحة',
          'الشركة المصنعة',
          'الموديل',
          'السنة',
          'اللون',
          'رقم الهيكل',
          'الحالة',
          'القسم',
          'اسم السائق',
          'هاتف السائق',
          'نوع الوقود',
          'عدد سجلات الصيانة',
          'تاريخ الإنشاء',
        ];

        const rows = vehicles.map((v) => [
          v.plateNumber,
          v.make,
          v.model,
          String(v.year),
          v.color || '',
          v.vin || '',
          statusMap[v.status] || v.status,
          v.department || '',
          v.driverName || '',
          v.driverPhone || '',
          fuelMap[v.fuelType || ''] || v.fuelType || '',
          String(v._count.maintenanceRecords),
          v.createdAt.toISOString().split('T')[0],
        ]);

        csvContent = buildCsv(headers, rows);
        filename = 'vehicles_export.csv';
        break;
      }

      case 'maintenance': {
        const records = await db.maintenanceRecord.findMany({
          include: {
            vehicle: {
              select: { plateNumber: true, make: true, model: true },
            },
          },
          orderBy: { maintenanceDate: 'desc' },
        });

        const typeMap: Record<string, string> = {
          OIL_CHANGE: 'تغيير زيت',
          TIRE: 'إطارات',
          ELECTRICAL: 'كهرباء',
          MECHANICAL: 'ميكانيكا',
          BODYWORK: 'هيكل ودهان',
          AC: 'تكييف',
          TRANSMISSION: 'ناقل الحركة',
          BRAKES: 'فرامل',
          FILTER: 'فلاتر',
          BATTERY: 'بطارية',
          SUSPENSION: 'تعليق',
          OTHER: 'أخرى',
        };

        const statusMap: Record<string, string> = {
          PENDING: 'معلق',
          IN_PROGRESS: 'قيد التنفيذ',
          COMPLETED: 'مكتمل',
          CANCELLED: 'ملغي',
        };

        const priorityMap: Record<string, string> = {
          LOW: 'منخفض',
          NORMAL: 'عادي',
          HIGH: 'مرتفع',
          URGENT: 'عاجل',
        };

        const headers = [
          'رقم المركبة',
          'المركبة',
          'تاريخ الصيانة',
          'الوصف',
          'النوع',
          'التكلفة',
          'تكلفة العمالة',
          'تكلفة القطع',
          'قراءة العداد',
          'مقدم الخدمة',
          'رقم الفاتورة',
          'الأولوية',
          'الحالة',
          'تاريخ الصيانة القادمة',
          'ملاحظات',
        ];

        const rows = records.map((r) => [
          r.vehicle.plateNumber,
          `${r.vehicle.make} ${r.vehicle.model}`,
          r.maintenanceDate.toISOString().split('T')[0],
          r.description,
          typeMap[r.type] || r.type,
          String(r.cost),
          r.laborCost ? String(r.laborCost) : '',
          r.partsCost ? String(r.partsCost) : '',
          r.kilometerReading ? String(r.kilometerReading) : '',
          r.serviceProvider || '',
          r.invoiceNumber || '',
          priorityMap[r.priority] || r.priority,
          statusMap[r.status] || r.status,
          r.nextMaintenanceDate
            ? r.nextMaintenanceDate.toISOString().split('T')[0]
            : '',
          r.notes || '',
        ]);

        csvContent = buildCsv(headers, rows);
        filename = 'maintenance_export.csv';
        break;
      }

      case 'reports': {
        // Maintenance type breakdown with costs
        const costByType = await db.maintenanceRecord.groupBy({
          by: ['type'],
          _sum: { cost: true, laborCost: true, partsCost: true },
          _count: true,
          orderBy: { _sum: { cost: 'desc' } },
        });

        const typeMap: Record<string, string> = {
          OIL_CHANGE: 'تغيير زيت',
          TIRE: 'إطارات',
          ELECTRICAL: 'كهرباء',
          MECHANICAL: 'ميكانيكا',
          BODYWORK: 'هيكل ودهان',
          AC: 'تكييف',
          TRANSMISSION: 'ناقل الحركة',
          BRAKES: 'فرامل',
          FILTER: 'فلاتر',
          BATTERY: 'بطارية',
          SUSPENSION: 'تعليق',
          OTHER: 'أخرى',
        };

        const headers = [
          'نوع الصيانة',
          'عدد السجلات',
          'إجمالي التكلفة',
          'تكلفة العمالة',
          'تكلفة القطع',
          'متوسط التكلفة',
        ];

        const rows = costByType.map((item) => [
          typeMap[item.type] || item.type,
          String(item._count),
          String(item._sum.cost ?? 0),
          String(item._sum.laborCost ?? 0),
          String(item._sum.partsCost ?? 0),
          item._count > 0
            ? String(Math.round((item._sum.cost ?? 0) / item._count))
            : '0',
        ]);

        csvContent = buildCsv(headers, rows);
        filename = 'maintenance_report.csv';
        break;
      }

      default:
        return NextResponse.json(
          { error: 'نوع التصدير غير صالح. الأنواع المتاحة: vehicles, maintenance, reports' },
          { status: 400 }
        );
    }

    // Log export activity
    await logActivity({
      action: 'EXPORT',
      entity: type === 'vehicles' ? 'VEHICLE' : type === 'maintenance' ? 'MAINTENANCE' : 'SETTINGS',
      details: `تصدير بيانات: ${type}`,
    });

    return new NextResponse(csvContent, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="${filename}"`,
      },
    });
  } catch (error) {
    console.error('Export error:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء تصدير البيانات' },
      { status: 500 }
    );
  }
}
