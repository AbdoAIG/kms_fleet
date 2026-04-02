import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

type RouteContext = {
  params: Promise<{ id: string }>;
};

// GET /api/vehicles/[id]/details - Get vehicle with all maintenance records and cost stats
export async function GET(
  request: NextRequest,
  context: RouteContext
) {
  try {
    const { id } = await context.params;

    const vehicle = await db.vehicle.findUnique({
      where: { id },
    });

    if (!vehicle) {
      return NextResponse.json(
        { error: 'المركبة غير موجودة' },
        { status: 404 }
      );
    }

    const maintenanceRecords = await db.maintenanceRecord.findMany({
      where: { vehicleId: id },
      orderBy: { maintenanceDate: 'desc' },
    });

    // Calculate stats
    const totalCost = maintenanceRecords.reduce((sum, r) => sum + r.cost, 0);
    const avgCost = maintenanceRecords.length > 0 ? totalCost / maintenanceRecords.length : 0;

    return NextResponse.json({
      vehicle,
      maintenanceRecords,
      stats: {
        totalCost: Math.round(totalCost * 100) / 100,
        avgCost: Math.round(avgCost * 100) / 100,
        recordsCount: maintenanceRecords.length,
      },
    });
  } catch (error) {
    console.error('Error fetching vehicle details:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب تفاصيل المركبة' },
      { status: 500 }
    );
  }
}
