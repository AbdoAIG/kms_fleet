import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { Prisma } from '@prisma/client';

type RouteContext = {
  params: Promise<{ id: string }>;
};

// GET /api/vehicles/[id]/maintenance - List maintenance records for a specific vehicle
export async function GET(
  request: NextRequest,
  context: RouteContext
) {
  try {
    const { id } = await context.params;
    const { searchParams } = request.nextUrl;

    const type = searchParams.get('type') || '';
    const status = searchParams.get('status') || '';
    const priority = searchParams.get('priority') || '';
    const startDate = searchParams.get('startDate') || '';
    const endDate = searchParams.get('endDate') || '';
    const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '20', 10)));

    // Check vehicle exists
    const vehicle = await db.vehicle.findUnique({
      where: { id },
    });

    if (!vehicle) {
      return NextResponse.json(
        { error: 'المركبة غير موجودة' },
        { status: 404 }
      );
    }

    // Build where clause
    const where: Prisma.MaintenanceRecordWhereInput = {
      vehicleId: id,
    };

    if (type) {
      where.type = type;
    }

    if (status) {
      where.status = status;
    }

    if (priority) {
      where.priority = priority;
    }

    if (startDate || endDate) {
      where.maintenanceDate = {};
      if (startDate) {
        where.maintenanceDate.gte = new Date(startDate);
      }
      if (endDate) {
        where.maintenanceDate.lte = new Date(endDate);
      }
    }

    const [records, total] = await Promise.all([
      db.maintenanceRecord.findMany({
        where,
        orderBy: { maintenanceDate: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      db.maintenanceRecord.count({ where }),
    ]);

    const pages = Math.ceil(total / limit);

    return NextResponse.json({
      records,
      total,
      pages,
      page,
      limit,
      vehicle,
    });
  } catch (error) {
    console.error('Error fetching vehicle maintenance records:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب سجلات الصيانة' },
      { status: 500 }
    );
  }
}
