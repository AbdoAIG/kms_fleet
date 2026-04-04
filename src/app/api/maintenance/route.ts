import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { Prisma } from '@prisma/client';

// GET /api/maintenance - List all maintenance records with search, filter, pagination
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const search = searchParams.get('search') || '';
    const vehicleId = searchParams.get('vehicleId') || '';
    const type = searchParams.get('type') || '';
    const status = searchParams.get('status') || '';
    const priority = searchParams.get('priority') || '';
    const startDate = searchParams.get('startDate') || '';
    const endDate = searchParams.get('endDate') || '';
    const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '20', 10)));
    const sortBy = searchParams.get('sortBy') || 'maintenanceDate';
    const sortDir = searchParams.get('sortDir') || 'desc';

    // Build where clause
    const where: Prisma.MaintenanceRecordWhereInput = {};

    if (search) {
      where.OR = [
        { description: { contains: search, mode: 'insensitive' } },
        { serviceProvider: { contains: search, mode: 'insensitive' } },
        { invoiceNumber: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (vehicleId) {
      where.vehicleId = vehicleId;
    }

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

    // Build order clause
    const validSortFields = [
      'maintenanceDate', 'type', 'cost', 'status', 'priority',
      'kilometerReading', 'createdAt', 'updatedAt',
    ];
    const orderByField = validSortFields.includes(sortBy) ? sortBy : 'maintenanceDate';
    const orderByDirection = sortDir === 'asc' ? 'asc' : 'desc';

    const [records, total] = await Promise.all([
      db.maintenanceRecord.findMany({
        where,
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
        orderBy: { [orderByField]: orderByDirection },
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
    });
  } catch (error) {
    console.error('Error fetching maintenance records:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب سجلات الصيانة' },
      { status: 500 }
    );
  }
}

// POST /api/maintenance - Create a new maintenance record
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    // Validate required fields
    const { vehicleId, maintenanceDate, description, type, cost } = body;

    if (!vehicleId || !maintenanceDate || !description || !type || cost === undefined) {
      return NextResponse.json(
        { error: 'الحقول المطلوبة: معرف المركبة، تاريخ الصيانة، الوصف، النوع، التكلفة' },
        { status: 400 }
      );
    }

    // Validate cost
    if (typeof cost !== 'number' || cost < 0) {
      return NextResponse.json(
        { error: 'التكلفة يجب أن تكون رقماً صحيحاً أو عشرياً أكبر من الصفر' },
        { status: 400 }
      );
    }

    // Check vehicle exists
    const vehicle = await db.vehicle.findUnique({
      where: { id: vehicleId },
    });

    if (!vehicle) {
      return NextResponse.json(
        { error: 'المركبة غير موجودة' },
        { status: 404 }
      );
    }

    // Validate maintenanceDate
    const maintenanceDateObj = new Date(maintenanceDate);
    if (isNaN(maintenanceDateObj.getTime())) {
      return NextResponse.json(
        { error: 'تاريخ الصيانة غير صالح' },
        { status: 400 }
      );
    }

    const record = await db.maintenanceRecord.create({
      data: {
        vehicleId,
        maintenanceDate: maintenanceDateObj,
        description,
        type,
        cost,
        kilometerReading: body.kilometerReading !== undefined ? body.kilometerReading : null,
        serviceProvider: body.serviceProvider || null,
        invoiceNumber: body.invoiceNumber || null,
        laborCost: body.laborCost !== undefined ? body.laborCost : null,
        partsCost: body.partsCost !== undefined ? body.partsCost : null,
        nextMaintenanceDate: body.nextMaintenanceDate ? new Date(body.nextMaintenanceDate) : null,
        nextMaintenanceKm: body.nextMaintenanceKm !== undefined ? body.nextMaintenanceKm : null,
        priority: body.priority || 'NORMAL',
        status: body.status || 'COMPLETED',
        notes: body.notes || null,
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

    return NextResponse.json(record, { status: 201 });
  } catch (error) {
    console.error('Error creating maintenance record:', error);

    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2003') {
        return NextResponse.json(
          { error: 'المركبة المحددة غير موجودة' },
          { status: 400 }
        );
      }
    }

    return NextResponse.json(
      { error: 'حدث خطأ أثناء إنشاء سجل الصيانة' },
      { status: 500 }
    );
  }
}
