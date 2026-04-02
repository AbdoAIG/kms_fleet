'use client'

import { useQuery } from '@tanstack/react-query'
import {
  Hash, User, Phone, Fuel, Building2, Calendar, DollarSign,
  Wrench, Palette, X, Car,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Separator } from '@/components/ui/separator'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from '@/components/ui/sheet'
import {
  formatCurrency,
  formatDate,
  getMaintenanceTypeLabel,
  getMaintenanceStatusLabel,
  getVehicleStatusLabel,
  getPriorityLabel,
} from '@/lib/constants'

/* ─── Types ─── */
interface Vehicle {
  id: string
  plateNumber: string
  make: string
  model: string
  year: number
  color: string | null
  vin: string | null
  status: string
  department: string | null
  driverName: string | null
  driverPhone: string | null
  fuelType: string | null
  notes: string | null
  createdAt: string
  updatedAt: string
}

interface MaintenanceRecord {
  id: string
  maintenanceDate: string
  description: string
  type: string
  cost: number
  status: string
  priority: string
  serviceProvider: string | null
  kilometerReading: number | null
  notes: string | null
}

interface VehicleDetailsResponse {
  vehicle: Vehicle
  maintenanceRecords: MaintenanceRecord[]
  stats: {
    totalCost: number
    avgCost: number
    recordsCount: number
  }
}

/* ─── Status Helpers ─── */
function getStatusClasses(status: string): string {
  switch (status) {
    case 'ACTIVE':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
    case 'MAINTENANCE':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
    case 'OUT_OF_SERVICE':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    case 'SOLD':
      return 'bg-gray-100 text-gray-600 dark:bg-gray-900/30 dark:text-gray-400'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

function getStatusDotColor(status: string): string {
  switch (status) {
    case 'ACTIVE': return 'bg-emerald-500'
    case 'MAINTENANCE': return 'bg-amber-500'
    case 'OUT_OF_SERVICE': return 'bg-red-500'
    case 'SOLD': return 'bg-gray-400'
    default: return 'bg-gray-400'
  }
}

function getMaintenanceStatusClasses(status: string): string {
  switch (status) {
    case 'COMPLETED': return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
    case 'PENDING': return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
    case 'IN_PROGRESS': return 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-400'
    case 'CANCELLED': return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    default: return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

function getPriorityClasses(priority: string): string {
  switch (priority) {
    case 'URGENT': return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    case 'HIGH': return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
    case 'NORMAL': return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
    case 'LOW': return 'bg-slate-100 text-slate-600 dark:bg-slate-900/30 dark:text-slate-400'
    default: return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

function getTypeBorderColor(type: string): string {
  const colors: Record<string, string> = {
    OIL_CHANGE: 'border-r-emerald-500',
    TIRE: 'border-r-amber-500',
    ELECTRICAL: 'border-r-blue-500',
    MECHANICAL: 'border-r-purple-500',
    BRAKES: 'border-r-red-500',
    BODYWORK: 'border-r-orange-500',
    AC: 'border-r-cyan-500',
    TRANSMISSION: 'border-r-indigo-500',
    FILTER: 'border-r-teal-500',
    BATTERY: 'border-r-yellow-500',
    SUSPENSION: 'border-r-pink-500',
    OTHER: 'border-r-gray-500',
  }
  return colors[type] || 'border-r-gray-500'
}

function getFuelLabel(value: string): string {
  const labels: Record<string, string> = {
    PETROL: 'بنزين',
    DIESEL: 'ديزل',
    ELECTRIC: 'كهربائي',
    HYBRID: 'هجين',
  }
  return labels[value] || value
}

/* ─── Component ─── */
interface VehicleDetailsDialogProps {
  vehicleId: string
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function VehicleDetailsDialog({
  vehicleId,
  open,
  onOpenChange,
}: VehicleDetailsDialogProps) {
  const { data, isLoading } = useQuery<VehicleDetailsResponse>({
    queryKey: ['vehicle-details', vehicleId],
    queryFn: () =>
      fetch(`/api/vehicles/${vehicleId}/details`).then((r) => {
        if (!r.ok) throw new Error('Failed to fetch vehicle details')
        return r.json()
      }),
    enabled: open && !!vehicleId,
  })

  const vehicle = data?.vehicle
  const records = data?.maintenanceRecords || []
  const stats = data?.stats

  // Sort records by date (newest first)
  const sortedRecords = [...records].sort(
    (a, b) => new Date(b.maintenanceDate).getTime() - new Date(a.maintenanceDate).getTime()
  )

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent
        side="left"
        className="w-full sm:max-w-2xl p-0 overflow-hidden"
        dir="rtl"
      >
        <SheetHeader className="sr-only">
          <SheetTitle>تفاصيل المركبة</SheetTitle>
          <SheetDescription>عرض بيانات المركبة وسجل الصيانة</SheetDescription>
        </SheetHeader>

        {isLoading ? (
          <div className="p-6 space-y-6">
            <div className="space-y-3">
              <Skeleton className="h-8 w-48" />
              <Skeleton className="h-4 w-64" />
            </div>
            <Separator />
            <div className="grid grid-cols-2 gap-4">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="space-y-2">
                  <Skeleton className="h-3 w-16" />
                  <Skeleton className="h-5 w-24" />
                </div>
              ))}
            </div>
            <Separator />
            <div className="space-y-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <Skeleton key={i} className="h-24 w-full rounded-lg" />
              ))}
            </div>
          </div>
        ) : vehicle ? (
          <ScrollArea className="h-full">
            <div className="p-6 space-y-6">
              {/* ── Vehicle Header ── */}
              <div>
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-12 h-12 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 flex items-center justify-center shrink-0">
                      <Car className="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <h2 className="text-xl font-bold text-foreground">
                          {vehicle.plateNumber}
                        </h2>
                        {vehicle.color && (
                          <span
                            className="w-4 h-4 rounded-full border-2 border-gray-300 dark:border-gray-600 inline-block shrink-0"
                            style={{ backgroundColor: vehicle.color }}
                            title={vehicle.color}
                          />
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground mt-0.5">
                        {vehicle.make} {vehicle.model} • {vehicle.year}
                      </p>
                    </div>
                  </div>
                  <Badge
                    variant="outline"
                    className={`shrink-0 text-xs ${getStatusClasses(vehicle.status)}`}
                  >
                    <span className={`w-1.5 h-1.5 rounded-full ${getStatusDotColor(vehicle.status)} inline-block ml-1.5`} />
                    {getVehicleStatusLabel(vehicle.status)}
                  </Badge>
                </div>
              </div>

              <Separator />

              {/* ── Vehicle Info Grid ── */}
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                {vehicle.color && (
                  <InfoItem
                    icon={<Palette className="w-4 h-4 text-muted-foreground" />}
                    label="اللون"
                    value={vehicle.color}
                  />
                )}
                {vehicle.vin && (
                  <InfoItem
                    icon={<Hash className="w-4 h-4 text-muted-foreground" />}
                    label="رقم الشاصي"
                    value={vehicle.vin}
                    dir="ltr"
                  />
                )}
                {vehicle.fuelType && (
                  <InfoItem
                    icon={<Fuel className="w-4 h-4 text-muted-foreground" />}
                    label="نوع الوقود"
                    value={getFuelLabel(vehicle.fuelType)}
                  />
                )}
                {vehicle.department && (
                  <InfoItem
                    icon={<Building2 className="w-4 h-4 text-muted-foreground" />}
                    label="القسم"
                    value={vehicle.department}
                  />
                )}
                {vehicle.driverName && (
                  <InfoItem
                    icon={<User className="w-4 h-4 text-muted-foreground" />}
                    label="السائق"
                    value={vehicle.driverName}
                  />
                )}
                {vehicle.driverPhone && (
                  <InfoItem
                    icon={<Phone className="w-4 h-4 text-muted-foreground" />}
                    label="الهاتف"
                    value={vehicle.driverPhone}
                    dir="ltr"
                  />
                )}
              </div>

              {/* ── Cost Summary Card ── */}
              {stats && (
                <>
                  <Separator />
                  <Card className="border-emerald-200 dark:border-emerald-800 bg-emerald-50/30 dark:bg-emerald-950/20">
                    <CardHeader className="pb-3 pt-4 px-4">
                      <CardTitle className="text-sm font-semibold flex items-center gap-2">
                        <DollarSign className="w-4 h-4 text-emerald-600" />
                        ملخص التكاليف
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="px-4 pb-4">
                      <div className="grid grid-cols-3 gap-4">
                        <div className="text-center">
                          <p className="text-xs text-muted-foreground">إجمالي التكاليف</p>
                          <p className="text-lg font-bold text-emerald-700 dark:text-emerald-400 mt-0.5">
                            {formatCurrency(stats.totalCost)}
                          </p>
                        </div>
                        <div className="text-center">
                          <p className="text-xs text-muted-foreground">متوسط التكلفة</p>
                          <p className="text-lg font-bold text-foreground mt-0.5">
                            {formatCurrency(stats.avgCost)}
                          </p>
                        </div>
                        <div className="text-center">
                          <p className="text-xs text-muted-foreground">عدد السجلات</p>
                          <p className="text-lg font-bold text-foreground mt-0.5">
                            {stats.recordsCount}
                          </p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </>
              )}

              {/* ── Notes ── */}
              {vehicle.notes && (
                <>
                  <Separator />
                  <div>
                    <h3 className="text-sm font-semibold text-foreground mb-2">ملاحظات</h3>
                    <p className="text-sm text-muted-foreground leading-relaxed bg-muted/50 rounded-lg p-3">
                      {vehicle.notes}
                    </p>
                  </div>
                </>
              )}

              {/* ── Maintenance Timeline ── */}
              <Separator />
              <div>
                <h3 className="text-sm font-semibold text-foreground mb-4 flex items-center gap-2">
                  <Wrench className="w-4 h-4 text-emerald-600" />
                  سجل الصيانة
                  <Badge variant="secondary" className="text-xs px-2 py-0">
                    {sortedRecords.length} سجل
                  </Badge>
                </h3>

                {sortedRecords.length > 0 ? (
                  <div className="space-y-3">
                    {sortedRecords.map((record) => (
                      <div
                        key={record.id}
                        className={`border-r-4 ${getTypeBorderColor(record.type)} rounded-lg bg-card border shadow-sm p-4 hover:shadow-md transition-shadow`}
                      >
                        <div className="flex items-start justify-between gap-3 mb-2">
                          <div className="flex items-center gap-2 flex-wrap">
                            <Badge variant="secondary" className="text-xs px-2 py-0">
                              {getMaintenanceTypeLabel(record.type)}
                            </Badge>
                            <Badge
                              variant="outline"
                              className={`text-xs px-2 py-0 ${getMaintenanceStatusClasses(record.status)}`}
                            >
                              {getMaintenanceStatusLabel(record.status)}
                            </Badge>
                            <Badge
                              variant="outline"
                              className={`text-xs px-2 py-0 ${getPriorityClasses(record.priority)}`}
                            >
                              {getPriorityLabel(record.priority)}
                            </Badge>
                          </div>
                          <span className="text-xs text-muted-foreground whitespace-nowrap flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            {formatDate(record.maintenanceDate)}
                          </span>
                        </div>
                        <p className="text-sm font-medium text-foreground mb-1">
                          {record.description}
                        </p>
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-bold text-emerald-700 dark:text-emerald-400">
                            {formatCurrency(record.cost)}
                          </span>
                          {record.serviceProvider && (
                            <span className="text-xs text-muted-foreground">
                              {record.serviceProvider}
                            </span>
                          )}
                        </div>
                        {record.kilometerReading && (
                          <p className="text-xs text-muted-foreground mt-1.5">
                            قراءة العداد: {record.kilometerReading.toLocaleString('ar-EG')} كم
                          </p>
                        )}
                        {record.notes && (
                          <p className="text-xs text-muted-foreground mt-1 bg-muted/50 rounded px-2 py-1">
                            {record.notes}
                          </p>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
                    <Wrench className="w-10 h-10 mb-2 opacity-40" />
                    <p className="text-sm">لا توجد سجلات صيانة لهذه المركبة</p>
                  </div>
                )}
              </div>
            </div>
          </ScrollArea>
        ) : (
          <div className="flex items-center justify-center h-full text-muted-foreground">
            <p className="text-sm">لم يتم العثور على المركبة</p>
          </div>
        )}
      </SheetContent>
    </Sheet>
  )
}

/* ─── Info Item Sub-component ─── */
function InfoItem({
  icon,
  label,
  value,
  dir,
}: {
  icon: React.ReactNode
  label: string
  value: string
  dir?: string
}) {
  return (
    <div className="flex items-start gap-2.5">
      <div className="mt-0.5 shrink-0">{icon}</div>
      <div className="min-w-0">
        <p className="text-xs text-muted-foreground">{label}</p>
        <p className="text-sm font-medium text-foreground truncate" dir={dir}>
          {value}
        </p>
      </div>
    </div>
  )
}
