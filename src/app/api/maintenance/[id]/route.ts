import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { Prisma } from '@prisma/client';

type RouteContext = {
  params: Promise<{ id: string }>;
};

// GET /api/maintenance/[id] - Get single maintenance record with vehicle data
export async function GET(
  request: NextRequest,
  context: RouteContext
) {
  try {
    const { id } = await context.params;

    const record = await db.maintenanceRecord.findUnique({
      where: { id },
      include: {
        vehicle: {
          select: {
            id: true,
            plateNumber: true,
            make: true,
            model: true,
            year: true,
            color: true,
            status: true,
            department: true,
            driverName: true,
            driverPhone: true,
          },
        },
      },
    });

    if (!record) {
      return NextResponse.json(
        { error: 'سجل الصيانة غير موجود' },
        { status: 404 }
      );
    }

    return NextResponse.json(record);
  } catch (error) {
    console.error('Error fetching maintenance record:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب سجل الصيانة' },
      { status: 500 }
    );
  }
}

// PUT /api/maintenance/[id] - Update maintenance record
export async function PUT(
  request: NextRequest,
  context: RouteContext
) {
  try {
    const { id } = await context.params;
    const body = await request.json();

    // Check record exists
    const existingRecord = await db.maintenanceRecord.findUnique({
      where: { id },
    });

    if (!existingRecord) {
      return NextResponse.json(
        { error: 'سجل الصيانة غير موجود' },
        { status: 404 }
      );
    }

    // Validate cost if provided
    if (body.cost !== undefined && (typeof body.cost !== 'number' || body.cost < 0)) {
      return NextResponse.json(
        { error: 'التكلفة يجب أن تكون رقماً صحيحاً أو عشرياً أكبر من الصفر' },
        { status: 400 }
      );
    }

    // Validate maintenanceDate if provided
    let maintenanceDate: Date | undefined;
    if (body.maintenanceDate !== undefined) {
      maintenanceDate = new Date(body.maintenanceDate);
      if (isNaN(maintenanceDate.getTime())) {
        return NextResponse.json(
          { error: 'تاريخ الصيانة غير صالح' },
          { status: 400 }
        );
      }
    }

    let nextMaintenanceDate: Date | null | undefined;
    if (body.nextMaintenanceDate !== undefined) {
      nextMaintenanceDate = body.nextMaintenanceDate ? new Date(body.nextMaintenanceDate) : null;
    }

    // Check vehicle exists if vehicleId is being changed
    if (body.vehicleId) {
      const vehicleExists = await db.vehicle.findUnique({
        where: { id: body.vehicleId },
      });
      if (!vehicleExists) {
        return NextResponse.json(
          { error: 'المركبة المحددة غير موجودة' },
          { status: 404 }
        );
      }
    }

    const record = await db.maintenanceRecord.update({
      where: { id },
      data: {
        vehicleId: body.vehicleId !== undefined ? body.vehicleId : undefined,
        maintenanceDate: maintenanceDate !== undefined ? maintenanceDate : undefined,
        description: body.description !== undefined ? body.description : undefined,
        type: body.type !== undefined ? body.type : undefined,
        cost: body.cost !== undefined ? body.cost : undefined,
        kilometerReading: body.kilometerReading !== undefined ? (body.kilometerReading ?? null) : undefined,
        serviceProvider: body.serviceProvider !== undefined ? (body.serviceProvider || null) : undefined,
        invoiceNumber: body.invoiceNumber !== undefined ? (body.invoiceNumber || null) : undefined,
        laborCost: body.laborCost !== undefined ? (body.laborCost ?? null) : undefined,
        partsCost: body.partsCost !== undefined ? (body.partsCost ?? null) : undefined,
        nextMaintenanceDate: nextMaintenanceDate !== undefined ? nextMaintenanceDate : undefined,
        nextMaintenanceKm: body.nextMaintenanceKm !== undefined ? (body.nextMaintenanceKm ?? null) : undefined,
        priority: body.priority !== undefined ? body.priority : undefined,
        status: body.status !== undefined ? body.status : undefined,
        notes: body.notes !== undefined ? (body.notes || null) : undefined,
      },
      include: {
        vehicle: {
          select: {
            id: true,
            plateNumber: true,
            make: true,
            model: true,
          },
        },
      },
    });

    return NextResponse.json(record);
  } catch (error) {
    console.error('Error updating maintenance record:', error);

    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2003') {
        return NextResponse.json(
          { error: 'المركبة المحددة غير موجودة' },
          { status: 400 }
        );
      }
    }

    return NextResponse.json(
      { error: 'حدث خطأ أثناء تحديث سجل الصيانة' },
      { status: 500 }
    );
  }
}

// DELETE /api/maintenance/[id] - Delete maintenance record
export async function DELETE(
  request: NextRequest,
  context: RouteContext
) {
  try {
    const { id } = await context.params;

    // Check record exists
    const existingRecord = await db.maintenanceRecord.findUnique({
      where: { id },
    });

    if (!existingRecord) {
      return NextResponse.json(
        { error: 'سجل الصيانة غير موجود' },
        { status: 404 }
      );
    }

    await db.maintenanceRecord.delete({
      where: { id },
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting maintenance record:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء حذف سجل الصيانة' },
      { status: 500 }
    );
  }
}
