import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { Prisma } from '@prisma/client';

type RouteContext = {
  params: Promise<{ id: string }>;
};

// GET /api/vehicles/[id] - Get single vehicle with recent maintenance records
export async function GET(
  request: NextRequest,
  context: RouteContext
) {
  try {
    const { id } = await context.params;

    const vehicle = await db.vehicle.findUnique({
      where: { id },
      include: {
        _count: {
          select: { maintenanceRecords: true },
        },
        maintenanceRecords: {
          orderBy: { maintenanceDate: 'desc' },
          take: 10,
        },
      },
    });

    if (!vehicle) {
      return NextResponse.json(
        { error: 'المركبة غير موجودة' },
        { status: 404 }
      );
    }

    return NextResponse.json(vehicle);
  } catch (error) {
    console.error('Error fetching vehicle:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب بيانات المركبة' },
      { status: 500 }
    );
  }
}

// PUT /api/vehicles/[id] - Update vehicle
export async function PUT(
  request: NextRequest,
  context: RouteContext
) {
  try {
    const { id } = await context.params;
    const body = await request.json();

    // Check vehicle exists
    const existingVehicle = await db.vehicle.findUnique({
      where: { id },
    });

    if (!existingVehicle) {
      return NextResponse.json(
        { error: 'المركبة غير موجودة' },
        { status: 404 }
      );
    }

    // Check for duplicate plate number if changing
    if (body.plateNumber && body.plateNumber !== existingVehicle.plateNumber) {
      const duplicatePlate = await db.vehicle.findUnique({
        where: { plateNumber: body.plateNumber },
      });
      if (duplicatePlate) {
        return NextResponse.json(
          { error: 'رقم اللوحة مسجل بالفعل' },
          { status: 409 }
        );
      }
    }

    // Check for duplicate VIN if changing
    if (body.vin && body.vin !== existingVehicle.vin) {
      const duplicateVin = await db.vehicle.findUnique({
        where: { vin: body.vin },
      });
      if (duplicateVin) {
        return NextResponse.json(
          { error: 'رقم الهيكل مسجل بالفعل' },
          { status: 409 }
        );
      }
    }

    // Validate year if provided
    if (body.year !== undefined && (typeof body.year !== 'number' || body.year < 1900 || body.year > 2100)) {
      return NextResponse.json(
        { error: 'السنة يجب أن تكون رقماً بين 1900 و 2100' },
        { status: 400 }
      );
    }

    const vehicle = await db.vehicle.update({
      where: { id },
      data: {
        plateNumber: body.plateNumber !== undefined ? body.plateNumber : undefined,
        make: body.make !== undefined ? body.make : undefined,
        model: body.model !== undefined ? body.model : undefined,
        year: body.year !== undefined ? body.year : undefined,
        color: body.color !== undefined ? (body.color || null) : undefined,
        vin: body.vin !== undefined ? (body.vin || null) : undefined,
        status: body.status !== undefined ? body.status : undefined,
        department: body.department !== undefined ? (body.department || null) : undefined,
        driverName: body.driverName !== undefined ? (body.driverName || null) : undefined,
        driverPhone: body.driverPhone !== undefined ? (body.driverPhone || null) : undefined,
        fuelType: body.fuelType !== undefined ? (body.fuelType || null) : undefined,
        notes: body.notes !== undefined ? (body.notes || null) : undefined,
      },
      include: {
        _count: {
          select: { maintenanceRecords: true },
        },
      },
    });

    return NextResponse.json(vehicle);
  } catch (error) {
    console.error('Error updating vehicle:', error);

    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2002') {
        return NextResponse.json(
          { error: 'رقم اللوحة أو رقم الهيكل مسجل بالفعل' },
          { status: 409 }
        );
      }
    }

    return NextResponse.json(
      { error: 'حدث خطأ أثناء تحديث بيانات المركبة' },
      { status: 500 }
    );
  }
}

// DELETE /api/vehicles/[id] - Delete vehicle (cascade deletes maintenance records)
export async function DELETE(
  request: NextRequest,
  context: RouteContext
) {
  try {
    const { id } = await context.params;

    // Check vehicle exists
    const existingVehicle = await db.vehicle.findUnique({
      where: { id },
    });

    if (!existingVehicle) {
      return NextResponse.json(
        { error: 'المركبة غير موجودة' },
        { status: 404 }
      );
    }

    await db.vehicle.delete({
      where: { id },
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting vehicle:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء حذف المركبة' },
      { status: 500 }
    );
  }
}
