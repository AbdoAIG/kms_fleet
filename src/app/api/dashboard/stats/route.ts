import { db } from '@/lib/db'
import { NextResponse } from 'next/server'

export async function GET() {
  try {
    const now = new Date()
    const thirtyDaysFromNow = new Date()
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30)

    // Start of month 6 months ago
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1)

    const [
      totalVehicles,
      activeVehicles,
      maintenanceRecords,
      costResult,
      costByType,
      recentRecords,
      allUpcoming,
      allMonthlyRecords,
    ] = await Promise.all([
      db.vehicle.count(),
      db.vehicle.count({ where: { status: 'ACTIVE' } }),
      db.maintenanceRecord.count(),
      db.maintenanceRecord.aggregate({ _sum: { cost: true } }),
      db.maintenanceRecord.groupBy({
        by: ['type'],
        _sum: { cost: true },
        orderBy: { _sum: { cost: 'desc' } },
      }),
      db.maintenanceRecord.findMany({
        take: 5,
        orderBy: { maintenanceDate: 'desc' },
        include: {
          vehicle: {
            select: { plateNumber: true, make: true, model: true },
          },
        },
      }),
      db.maintenanceRecord.findMany({
        where: {
          status: { not: 'CANCELLED' },
          nextMaintenanceDate: { gte: now, lte: thirtyDaysFromNow },
        },
        orderBy: { nextMaintenanceDate: 'asc' },
        include: {
          vehicle: {
            select: { id: true, plateNumber: true, make: true, model: true },
          },
        },
      }),
      db.maintenanceRecord.findMany({
        where: { maintenanceDate: { gte: sixMonthsAgo } },
        select: { maintenanceDate: true, cost: true },
      }),
    ])

    /* ── Monthly Trend (last 6 months) ── */
    const months: string[] = []
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      months.push(
        `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
      )
    }

    const monthlyMap: Record<string, number> = {}
    months.forEach((m) => (monthlyMap[m] = 0))
    allMonthlyRecords.forEach((r) => {
      const key = `${r.maintenanceDate.getFullYear()}-${String(
        r.maintenanceDate.getMonth() + 1
      ).padStart(2, '0')}`
      if (key in monthlyMap) {
        monthlyMap[key] += r.cost
      }
    })

    const monthlyTrend = months.map((m) => ({ month: m, total: monthlyMap[m] }))

    /* ── Upcoming Maintenance (deduplicated by vehicle) ── */
    const seenVehicles = new Set<string>()
    const upcomingMaintenance = []
    for (const record of allUpcoming) {
      if (!seenVehicles.has(record.vehicleId)) {
        seenVehicles.add(record.vehicleId)
        upcomingMaintenance.push({
          id: record.id,
          description: record.description,
          type: record.type,
          priority: record.priority,
          nextMaintenanceDate: record.nextMaintenanceDate,
          vehicle: record.vehicle,
        })
        if (upcomingMaintenance.length >= 5) break
      }
    }

    return NextResponse.json({
      stats: {
        totalVehicles,
        activeVehicles,
        maintenanceRecords,
        totalCost: costResult._sum.cost ?? 0,
      },
      costByType: costByType.map((item) => ({
        type: item.type,
        total: item._sum.cost ?? 0,
      })),
      monthlyTrend,
      recentRecords,
      upcomingMaintenance,
    })
  } catch (error) {
    console.error('Dashboard stats error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch dashboard stats' },
      { status: 500 }
    )
  }
}
