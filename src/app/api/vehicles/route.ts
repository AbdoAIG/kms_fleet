import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { Prisma } from '@prisma/client';

// GET /api/vehicles - List vehicles with search, filter, pagination
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const search = searchParams.get('search') || '';
    const status = searchParams.get('status') || '';
    const department = searchParams.get('department') || '';
    const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '20', 10)));
    const sortBy = searchParams.get('sortBy') || 'createdAt';
    const sortDir = searchParams.get('sortDir') || 'desc';

    // Build where clause
    const where: Prisma.VehicleWhereInput = {};

    if (search) {
      where.OR = [
        { plateNumber: { contains: search, mode: 'insensitive' } },
        { make: { contains: search, mode: 'insensitive' } },
        { model: { contains: search, mode: 'insensitive' } },
        { driverName: { contains: search, mode: 'insensitive' } },
        { vin: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (status) {
      where.status = status;
    }

    if (department) {
      where.department = { contains: department, mode: 'insensitive' };
    }

    // Build order clause
    const validSortFields = ['plateNumber', 'make', 'model', 'year', 'status', 'department', 'driverName', 'createdAt', 'updatedAt'];
    const orderByField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
    const orderByDirection = sortDir === 'asc' ? 'asc' : 'desc';

    const [vehicles, total] = await Promise.all([
      db.vehicle.findMany({
        where,
        include: {
          _count: {
            select: { maintenanceRecords: true },
          },
        },
        orderBy: { [orderByField]: orderByDirection },
        skip: (page - 1) * limit,
        take: limit,
      }),
      db.vehicle.count({ where }),
    ]);

    const pages = Math.ceil(total / limit);

    return NextResponse.json({
      vehicles,
      total,
      pages,
      page,
      limit,
    });
  } catch (error) {
    console.error('Error fetching vehicles:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب المركبات' },
      { status: 500 }
    );
  }
}

// POST /api/vehicles - Create a new vehicle
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    // Validate required fields
    const { plateNumber, make, model, year } = body;

    if (!plateNumber || !make || !model || !year) {
      return NextResponse.json(
        { error: 'الحقول المطلوبة: رقم اللوحة، الشركة المصنعة، الموديل، السنة' },
        { status: 400 }
      );
    }

    if (typeof year !== 'number' || year < 1900 || year > 2100) {
      return NextResponse.json(
        { error: 'السنة يجب أن تكون رقماً بين 1900 و 2100' },
        { status: 400 }
      );
    }

    // Check for duplicate plate number
    const existingVehicle = await db.vehicle.findUnique({
      where: { plateNumber },
    });

    if (existingVehicle) {
      return NextResponse.json(
        { error: 'رقم اللوحة مسجل بالفعل' },
        { status: 409 }
      );
    }

    // Check for duplicate VIN if provided
    if (body.vin) {
      const existingVin = await db.vehicle.findUnique({
        where: { vin: body.vin },
      });

      if (existingVin) {
        return NextResponse.json(
          { error: 'رقم الهيكل مسجل بالفعل' },
          { status: 409 }
        );
      }
    }

    const vehicle = await db.vehicle.create({
      data: {
        plateNumber,
        make,
        model,
        year,
        color: body.color || null,
        vin: body.vin || null,
        status: body.status || 'ACTIVE',
        department: body.department || null,
        driverName: body.driverName || null,
        driverPhone: body.driverPhone || null,
        fuelType: body.fuelType || null,
        notes: body.notes || null,
      },
      include: {
        _count: {
          select: { maintenanceRecords: true },
        },
      },
    });

    return NextResponse.json(vehicle, { status: 201 });
  } catch (error) {
    console.error('Error creating vehicle:', error);

    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2002') {
        const target = (error.meta?.target as string[]) || [];
        if (target.includes('plateNumber')) {
          return NextResponse.json(
            { error: 'رقم اللوحة مسجل بالفعل' },
            { status: 409 }
          );
        }
        if (target.includes('vin')) {
          return NextResponse.json(
            { error: 'رقم الهيكل مسجل بالفعل' },
            { status: 409 }
          );
        }
      }
    }

    return NextResponse.json(
      { error: 'حدث خطأ أثناء إنشاء المركبة' },
      { status: 500 }
    );
  }
}
