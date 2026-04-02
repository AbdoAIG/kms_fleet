import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

// GET /api/notifications - Compute notifications from current data
export async function GET() {
  try {
    const now = new Date();
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

    const [
      vehiclesWithNextMaintenance,
      overdueMaintenance,
      pendingRecords,
      highPriorityRecords,
    ] = await Promise.all([
      // Vehicles with upcoming maintenance (nextMaintenanceDate within 30 days)
      db.maintenanceRecord.findMany({
        where: {
          status: { not: 'CANCELLED' },
          nextMaintenanceDate: { gte: now, lte: thirtyDaysFromNow },
        },
        include: {
          vehicle: {
            select: { id: true, plateNumber: true, make: true, model: true },
          },
        },
        orderBy: { nextMaintenanceDate: 'asc' },
      }),

      // Vehicles with overdue maintenance (nextMaintenanceDate in past)
      db.maintenanceRecord.findMany({
        where: {
          status: { not: 'CANCELLED' },
          nextMaintenanceDate: { lt: now },
        },
        include: {
          vehicle: {
            select: { id: true, plateNumber: true, make: true, model: true },
          },
        },
        orderBy: { nextMaintenanceDate: 'asc' },
      }),

      // Maintenance records with status PENDING or IN_PROGRESS
      db.maintenanceRecord.findMany({
        where: {
          status: { in: ['PENDING', 'IN_PROGRESS'] },
        },
        include: {
          vehicle: {
            select: { id: true, plateNumber: true, make: true, model: true },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),

      // High-priority and urgent maintenance records
      db.maintenanceRecord.findMany({
        where: {
          priority: { in: ['HIGH', 'URGENT'] },
          status: { in: ['PENDING', 'IN_PROGRESS'] },
        },
        include: {
          vehicle: {
            select: { id: true, plateNumber: true, make: true, model: true },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const notifications: Array<{
      id: string;
      type: string;
      title: string;
      message: string;
      date: Date | null;
      entityType: string;
      entityId: string;
      vehicleId?: string;
      vehiclePlate?: string;
    }> = [];

    let notifId = 0;

    // 1. Overdue maintenance notifications (most urgent)
    const seenOverdueVehicles = new Set<string>();
    for (const record of overdueMaintenance) {
      if (seenOverdueVehicles.has(record.vehicleId)) continue;
      seenOverdueVehicles.add(record.vehicleId);

      notifId++;
      const daysOverdue = Math.floor(
        (now.getTime() - (record.nextMaintenanceDate?.getTime() ?? now.getTime())) /
          (1000 * 60 * 60 * 24)
      );

      notifications.push({
        id: `overdue-${notifId}`,
        type: 'OVERDUE',
        title: 'صيانة متأخرة',
        message: `المركبة ${record.vehicle.plateNumber} (${record.vehicle.make} ${record.vehicle.model}) - صيانة متأخرة منذ ${daysOverdue} يوم`,
        date: record.nextMaintenanceDate,
        entityType: 'VEHICLE',
        entityId: record.vehicleId,
        vehicleId: record.vehicleId,
        vehiclePlate: record.vehicle.plateNumber,
      });
    }

    // 2. Upcoming maintenance notifications
    const seenUpcomingVehicles = new Set<string>();
    for (const record of vehiclesWithNextMaintenance) {
      if (seenOverdueVehicles.has(record.vehicleId)) continue;
      if (seenUpcomingVehicles.has(record.vehicleId)) continue;
      seenUpcomingVehicles.add(record.vehicleId);

      notifId++;
      const daysLeft = Math.floor(
        ((record.nextMaintenanceDate?.getTime() ?? 0) - now.getTime()) /
          (1000 * 60 * 60 * 24)
      );

      notifications.push({
        id: `upcoming-${notifId}`,
        type: 'UPCOMING',
        title: 'صيانة قادمة',
        message: `المركبة ${record.vehicle.plateNumber} (${record.vehicle.make} ${record.vehicle.model}) - صيانة مقررة خلال ${daysLeft} يوم`,
        date: record.nextMaintenanceDate,
        entityType: 'VEHICLE',
        entityId: record.vehicleId,
        vehicleId: record.vehicleId,
        vehiclePlate: record.vehicle.plateNumber,
      });
    }

    // 3. Pending / In-Progress maintenance notifications
    for (const record of pendingRecords) {
      notifId++;
      const statusLabel = record.status === 'PENDING' ? 'معلقة' : 'قيد التنفيذ';

      notifications.push({
        id: `pending-${notifId}`,
        type: record.status === 'IN_PROGRESS' ? 'IN_PROGRESS' : 'PENDING',
        title: `صيانة ${statusLabel}`,
        message: `${record.description} - ${record.vehicle.plateNumber} (${record.vehicle.make} ${record.vehicle.model})`,
        date: record.maintenanceDate,
        entityType: 'MAINTENANCE',
        entityId: record.id,
        vehicleId: record.vehicleId,
        vehiclePlate: record.vehicle.plateNumber,
      });
    }

    // 4. High-priority / urgent notifications (already covered by pending, but add priority emphasis)
    const seenHighPriority = new Set<string>();
    for (const record of highPriorityRecords) {
      if (seenHighPriority.has(record.id)) continue;
      seenHighPriority.add(record.id);

      notifId++;
      const priorityLabel = record.priority === 'URGENT' ? 'عاجل' : 'مرتفع';

      notifications.push({
        id: `priority-${notifId}`,
        type: record.priority === 'URGENT' ? 'URGENT' : 'HIGH_PRIORITY',
        title: `أولوية ${priorityLabel}`,
        message: `${record.description} - ${record.vehicle.plateNumber} (${record.vehicle.make} ${record.vehicle.model})`,
        date: record.createdAt,
        entityType: 'MAINTENANCE',
        entityId: record.id,
        vehicleId: record.vehicleId,
        vehiclePlate: record.vehicle.plateNumber,
      });
    }

    // Summary counts
    const summary = {
      overdue: seenOverdueVehicles.size,
      upcoming: seenUpcomingVehicles.size,
      pending: pendingRecords.filter((r) => r.status === 'PENDING').length,
      inProgress: pendingRecords.filter((r) => r.status === 'IN_PROGRESS').length,
      highPriority: highPriorityRecords.length,
      total: notifications.length,
    };

    return NextResponse.json({
      notifications,
      summary,
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب الإشعارات' },
      { status: 500 }
    );
  }
}
