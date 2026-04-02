import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

// DELETE /api/data/clear - Clear all vehicles and maintenance records
export async function DELETE() {
  try {
    // Delete all maintenance records first (though cascade should handle this)
    const deletedMaintenance = await db.maintenanceRecord.deleteMany({});

    // Delete all vehicles
    const deletedVehicles = await db.vehicle.deleteMany({});

    // Log activity
    await db.activityLog.create({
      data: {
        action: 'DELETE',
        entity: 'VEHICLE',
        details: `حذف جميع البيانات: ${deletedVehicles.count} سيارة، ${deletedMaintenance.count} سجل صيانة`,
      },
    });

    return NextResponse.json({
      success: true,
      message: 'تم حذف جميع البيانات بنجاح',
      deletedVehicles: deletedVehicles.count,
      deletedMaintenance: deletedMaintenance.count,
    });
  } catch (error) {
    console.error('Error clearing data:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء حذف البيانات' },
      { status: 500 }
    );
  }
}
