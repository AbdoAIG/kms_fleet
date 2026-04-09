import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

// Helper function to log activity - can be imported by other routes
export async function logActivity(params: {
  userId?: string;
  action: string;
  entity: string;
  entityId?: string;
  details?: string;
}) {
  try {
    await db.activityLog.create({
      data: {
        userId: params.userId || null,
        action: params.action,
        entity: params.entity,
        entityId: params.entityId || null,
        details: params.details || null,
      },
    });
  } catch (error) {
    console.error('Error logging activity:', error);
  }
}

// GET /api/activity-log
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10));
    const limit = Math.min(50, Math.max(1, parseInt(searchParams.get('limit') || '50', 10)));
    const entity = searchParams.get('entity') || '';
    const action = searchParams.get('action') || '';
    const userId = searchParams.get('userId') || '';

    // Build where clause
    const where: Record<string, unknown> = {};

    if (entity) {
      where.entity = entity;
    }

    if (action) {
      where.action = action;
    }

    if (userId) {
      where.userId = userId;
    }

    const [logs, total] = await Promise.all([
      db.activityLog.findMany({
        where: Object.keys(where).length > 0 ? where : undefined,
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
              role: true,
              avatar: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      db.activityLog.count({
        where: Object.keys(where).length > 0 ? where : undefined,
      }),
    ]);

    const pages = Math.ceil(total / limit);

    return NextResponse.json({
      logs,
      total,
      pages,
      page,
      limit,
    });
  } catch (error) {
    console.error('Error fetching activity logs:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب سجل الأنشطة' },
      { status: 500 }
    );
  }
}
