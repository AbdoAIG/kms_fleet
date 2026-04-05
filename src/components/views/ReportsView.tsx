'use client'

import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { type ComponentType } from 'react'
import {
  DollarSign,
  TrendingUp,
  ArrowUpCircle,
  Car,
  BarChart3,
  PieChart as PieChartIcon,
  Activity,
  FileText,
  AlertTriangle,
  Calendar,
  Wrench,
  Trophy,
  Hash,
  Truck,
} from 'lucide-react'
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Skeleton } from '@/components/ui/skeleton'
import { ScrollArea } from '@/components/ui/scroll-area'
import {
  formatCurrency,
  formatDate,
  getMaintenanceTypeLabel,
  getMaintenanceStatusLabel,
} from '@/lib/constants'
import {
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts'

/* ═══════════════════════════════════════════════════
   Chart Colors
   ═══════════════════════════════════════════════════ */
const CHART_COLORS = [
  '#10b981', '#f59e0b', '#ef4444', '#14b8a6', '#f97316',
  '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16', '#6366f1',
  '#0ea5e9', '#a855f7',
]

const STATUS_COLORS: Record<string, string> = {
  PENDING: '#f59e0b',
  IN_PROGRESS: '#3b82f6',
  COMPLETED: '#10b981',
  CANCELLED: '#ef4444',
}

/* ═══════════════════════════════════════════════════
   Types
   ═══════════════════════════════════════════════════ */
interface MaintenanceRecord {
  id: string
  vehicleId: string
  maintenanceDate: string
  description: string
  type: string
  cost: number
  status: string
  priority: string
  vehicle: {
    id: string
    plateNumber: string
    make: string
    model: string
  }
}

interface Vehicle {
  id: string
  plateNumber: string
  make: string
  model: string
  year: number
  status: string
  _count?: { maintenanceRecords: number }
}

/* ═══════════════════════════════════════════════════
   Helpers
   ═══════════════════════════════════════════════════ */
function formatMonthLabel(monthKey: string): string {
  const [year, month] = monthKey.split('-')
  const date = new Date(parseInt(year), parseInt(month) - 1)
  return new Intl.DateTimeFormat('ar-EG', {
    month: 'short',
    year: 'numeric',
  }).format(date)
}

function formatMonthShort(monthKey: string): string {
  const [year, month] = monthKey.split('-')
  const date = new Date(parseInt(year), parseInt(month) - 1)
  return new Intl.DateTimeFormat('ar-EG', { month: 'short' }).format(date)
}

function getLast12Months(): string[] {
  const months: string[] = []
  const now = new Date()
  for (let i = 11; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
    months.push(
      `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
    )
  }
  return months
}

/* ═══════════════════════════════════════════════════
   Skeleton Components
   ═══════════════════════════════════════════════════ */
function StatCardSkeleton() {
  return (
    <Card>
      <CardContent className="flex items-center gap-4">
        <Skeleton className="w-12 h-12 rounded-xl" />
        <div className="flex-1 space-y-2">
          <Skeleton className="h-4 w-28" />
          <Skeleton className="h-7 w-20" />
          <Skeleton className="h-3 w-16" />
        </div>
      </CardContent>
    </Card>
  )
}

function ChartSkeleton() {
  return (
    <Card>
      <CardHeader>
        <Skeleton className="h-5 w-48" />
        <Skeleton className="h-4 w-64" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-[320px] w-full rounded-lg" />
      </CardContent>
    </Card>
  )
}

function TableSkeleton() {
  return (
    <Card>
      <CardHeader>
        <Skeleton className="h-5 w-56" />
        <Skeleton className="h-4 w-72" />
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-12 w-full rounded-md" />
          ))}
        </div>
      </CardContent>
    </Card>
  )
}

function VehicleCardSkeleton() {
  return (
    <Card>
      <CardContent className="p-5 space-y-4">
        <div className="flex items-center gap-3">
          <Skeleton className="w-10 h-10 rounded-lg" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-36" />
            <Skeleton className="h-3 w-24" />
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-14 rounded-lg" />
          ))}
        </div>
      </CardContent>
    </Card>
  )
}

/* ═══════════════════════════════════════════════════
   Summary Stat Card
   ═══════════════════════════════════════════════════ */
function SummaryCard({
  title,
  value,
  subtitle,
  icon: Icon,
  bgColor,
  iconColor,
}: {
  title: string
  value: string
  subtitle: string
  icon: ComponentType<{ className?: string }>
  bgColor: string
  iconColor: string
}) {
  return (
    <Card className="hover:shadow-md transition-shadow duration-200">
      <CardContent className="flex items-center gap-4">
        <div
          className={`w-12 h-12 rounded-xl ${bgColor} flex items-center justify-center shrink-0`}
        >
          <Icon className={`w-6 h-6 ${iconColor}`} />
        </div>
        <div className="min-w-0">
          <p className="text-sm text-muted-foreground truncate">{title}</p>
          <p className="text-xl sm:text-2xl font-bold tracking-tight truncate">
            {value}
          </p>
          <p className="text-xs text-muted-foreground truncate">{subtitle}</p>
        </div>
      </CardContent>
    </Card>
  )
}

/* ═══════════════════════════════════════════════════
   Custom Chart Tooltips
   ═══════════════════════════════════════════════════ */
function CurrencyTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean
  payload?: Array<{ value: number; name: string }>
  label?: string
}) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-popover text-popover-foreground border rounded-lg shadow-lg p-3 text-sm min-w-[140px]">
      <p className="font-semibold mb-1">{label}</p>
      {payload.map((entry, i) => (
        <p key={i} className="text-muted-foreground flex items-center gap-2">
          <span
            className="w-2.5 h-2.5 rounded-full shrink-0"
            style={{ backgroundColor: entry.name === 'التكلفة' ? '#10b981' : undefined }}
          />
          {formatCurrency(entry.value)}
        </p>
      ))}
    </div>
  )
}

function PieTooltip({
  active,
  payload,
}: {
  active?: boolean
  payload?: Array<{ name: string; value: number; payload?: { fill: string } }>
}) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-popover text-popover-foreground border rounded-lg shadow-lg p-3 text-sm min-w-[140px]">
      <div className="flex items-center gap-2 mb-1">
        <span
          className="w-3 h-3 rounded-full shrink-0"
          style={{ backgroundColor: payload[0].payload?.fill }}
        />
        <span className="font-semibold">{payload[0].name}</span>
      </div>
      <p className="text-muted-foreground">{formatCurrency(payload[0].value)}</p>
    </div>
  )
}

function StatusTooltip({
  active,
  payload,
}: {
  active?: boolean
  payload?: Array<{ name: string; value: number; payload?: { fill: string } }>
}) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-popover text-popover-foreground border rounded-lg shadow-lg p-3 text-sm min-w-[140px]">
      <div className="flex items-center gap-2 mb-1">
        <span
          className="w-3 h-3 rounded-full shrink-0"
          style={{ backgroundColor: payload[0].payload?.fill }}
        />
        <span className="font-semibold">{payload[0].name}</span>
      </div>
      <p className="text-muted-foreground">
        {payload[0].value} سجل
      </p>
    </div>
  )
}

/* ═══════════════════════════════════════════════════
   Custom Pie Legend
   ═══════════════════════════════════════════════════ */
function CustomPieLegend({
  payload,
  total,
}: {
  payload?: Array<{ value: string; color: string }>
  total: number
}) {
  if (!payload) return null
  return (
    <div className="flex flex-wrap justify-center gap-x-4 gap-y-2 mt-2">
      {payload.map((entry, i) => (
        <div key={i} className="flex items-center gap-1.5 text-xs">
          <span
            className="w-2.5 h-2.5 rounded-full shrink-0"
            style={{ backgroundColor: entry.color }}
          />
          <span className="text-muted-foreground">
            {entry.value}
          </span>
        </div>
      ))}
    </div>
  )
}

/* ═══════════════════════════════════════════════════
   Empty State
   ═══════════════════════════════════════════════════ */
function EmptyState({ message }: { message: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-muted-foreground text-sm">
      <BarChart3 className="w-10 h-10 mb-2 opacity-40" />
      <p>{message}</p>
    </div>
  )
}

/* ═══════════════════════════════════════════════════
   MAIN COMPONENT
   ═══════════════════════════════════════════════════ */
export default function ReportsView() {
  /* ── Data Fetching ── */
  const { data: maintenanceRes, isLoading: maintenanceLoading } = useQuery<{
    records: MaintenanceRecord[]
    total: number
  }>({
    queryKey: ['maintenance-reports'],
    queryFn: () =>
      fetch('/api/maintenance?limit=1000').then((r) => {
        if (!r.ok) throw new Error('Failed to fetch')
        return r.json()
      }),
  })

  const { data: vehiclesRes } = useQuery<{
    vehicles: Vehicle[]
    total: number
  }>({
    queryKey: ['vehicles-reports'],
    queryFn: () =>
      fetch('/api/vehicles?limit=1000').then((r) => {
        if (!r.ok) throw new Error('Failed to fetch')
        return r.json()
      }),
  })

  const records = maintenanceRes?.records ?? []
  const vehicles = vehiclesRes?.vehicles ?? []

  /* ── Computed Data ── */
  const computed = useMemo(() => {
    const totalCost = records.reduce((s, r) => s + r.cost, 0)
    const avgCost = records.length > 0 ? totalCost / records.length : 0
    const highestCost = records.length > 0
      ? Math.max(...records.map((r) => r.cost))
      : 0

    // Unique vehicles that have maintenance records
    const vehicleIds = new Set(records.map((r) => r.vehicleId))
    const vehiclesServiced = vehicleIds.size

    // Group by type for pie chart
    const typeMap = new Map<string, number>()
    records.forEach((r) => {
      typeMap.set(r.type, (typeMap.get(r.type) ?? 0) + r.cost)
    })
    const typePieData = Array.from(typeMap.entries())
      .map(([type, total]) => ({
        name: getMaintenanceTypeLabel(type),
        value: Math.round(total),
        type,
      }))
      .sort((a, b) => b.value - a.value)

    // Group by month for trend (last 12 months)
    const monthKeys = getLast12Months()
    const monthMap = new Map<string, number>()
    monthKeys.forEach((m) => monthMap.set(m, 0))
    records.forEach((r) => {
      const key = `${new Date(r.maintenanceDate).getFullYear()}-${String(
        new Date(r.maintenanceDate).getMonth() + 1
      ).padStart(2, '0')}`
      if (monthMap.has(key)) {
        monthMap.set(key, monthMap.get(key)! + r.cost)
      }
    })
    const monthlyTrend = monthKeys.map((m) => ({
      month: m,
      name: formatMonthShort(m),
      total: Math.round(monthMap.get(m) ?? 0),
    }))

    // Group by vehicle for cost comparison
    const vehicleMap = new Map<
      string,
      {
        vehicleId: string
        plateNumber: string
        make: string
        model: string
        totalCost: number
        recordCount: number
        records: MaintenanceRecord[]
      }
    >()
    records.forEach((r) => {
      const existing = vehicleMap.get(r.vehicleId)
      if (existing) {
        existing.totalCost += r.cost
        existing.recordCount++
        existing.records.push(r)
      } else {
        vehicleMap.set(r.vehicleId, {
          vehicleId: r.vehicleId,
          plateNumber: r.vehicle.plateNumber,
          make: r.vehicle.make,
          model: r.vehicle.model,
          totalCost: r.cost,
          recordCount: 1,
          records: [r],
        })
      }
    })
    const vehicleCostData = Array.from(vehicleMap.values())
      .sort((a, b) => b.totalCost - a.totalCost)
      .slice(0, 10)

    // Top 10 vehicles by cost for horizontal bar chart
    const vehicleBarData = vehicleCostData
      .map((v) => ({
        name: `${v.make} ${v.model}`,
        plate: v.plateNumber,
        total: Math.round(v.totalCost),
      }))
      .reverse() // reverse for horizontal bar (bottom to top)

    // Status distribution
    const statusMap = new Map<string, number>()
    records.forEach((r) => {
      statusMap.set(r.status, (statusMap.get(r.status) ?? 0) + 1)
    })
    const statusPieData = Array.from(statusMap.entries())
      .map(([status, count]) => ({
        name: getMaintenanceStatusLabel(status),
        value: count,
        status,
      }))
      .sort((a, b) => b.value - a.value)

    // Top vehicles table data (top 10)
    const topVehiclesTable = vehicleCostData.map((v, i) => ({
      rank: i + 1,
      plateNumber: v.plateNumber,
      make: v.make,
      model: v.model,
      totalRecords: v.recordCount,
      totalCost: v.totalCost,
      avgCost: v.totalCost / v.recordCount,
    }))

    // Maintenance type breakdown table
    const typeBreakdownMap = new Map<
      string,
      { costs: number[]; count: number; total: number }
    >()
    records.forEach((r) => {
      const existing = typeBreakdownMap.get(r.type)
      if (existing) {
        existing.costs.push(r.cost)
        existing.count++
        existing.total += r.cost
      } else {
        typeBreakdownMap.set(r.type, {
          costs: [r.cost],
          count: 1,
          total: r.cost,
        })
      }
    })
    const typeBreakdown = Array.from(typeBreakdownMap.entries())
      .map(([type, data]) => ({
        type,
        label: getMaintenanceTypeLabel(type),
        count: data.count,
        totalCost: data.total,
        avgCost: data.total / data.count,
        minCost: Math.min(...data.costs),
        maxCost: Math.max(...data.costs),
        percentage: totalCost > 0 ? (data.total / totalCost) * 100 : 0,
      }))
      .sort((a, b) => b.totalCost - a.totalCost)

    // Vehicle cost comparison cards (active vehicles with records)
    const activeVehicles = vehicles.filter((v) => v.status === 'ACTIVE')
    const vehicleComparisonCards = activeVehicles
      .map((v) => {
        const vData = vehicleMap.get(v.id)
        if (!vData) return null
        const typeCount = new Map<string, number>()
        vData.records.forEach((r) => {
          typeCount.set(r.type, (typeCount.get(r.type) ?? 0) + 1)
        })
        const mostCommonType = Array.from(typeCount.entries()).sort(
          (a, b) => b[1] - a[1]
        )[0]?.[0]
        const sortedRecords = [...vData.records].sort(
          (a, b) => new Date(b.maintenanceDate).getTime() - new Date(a.maintenanceDate).getTime()
        )
        return {
          plateNumber: v.plateNumber,
          make: v.make,
          model: v.model,
          year: v.year,
          totalCost: vData.totalCost,
          recordCount: vData.recordCount,
          mostCommonType: mostCommonType
            ? getMaintenanceTypeLabel(mostCommonType)
            : '-',
          lastMaintenanceDate: sortedRecords[0]?.maintenanceDate,
          avgCost: vData.totalCost / vData.recordCount,
        }
      })
      .filter(Boolean)
      .sort((a, b) => (b?.totalCost ?? 0) - (a?.totalCost ?? 0)) as Array<{
        plateNumber: string
        make: string
        model: string
        year: number
        totalCost: number
        recordCount: number
        mostCommonType: string
        lastMaintenanceDate: string
        avgCost: number
      }>

    return {
      totalCost,
      avgCost,
      highestCost,
      vehiclesServiced,
      typePieData,
      monthlyTrend,
      vehicleBarData,
      statusPieData,
      topVehiclesTable,
      typeBreakdown,
      vehicleComparisonCards,
    }
  }, [records, vehicles])

  /* ── Loading State ── */
  if (maintenanceLoading) {
    return (
      <div className="space-y-6">
        {/* Header skeleton */}
        <div className="space-y-2">
          <Skeleton className="h-8 w-64" />
          <Skeleton className="h-4 w-96" />
        </div>
        {/* Stat cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <StatCardSkeleton key={i} />
          ))}
        </div>
        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {Array.from({ length: 4 }).map((_, i) => (
            <ChartSkeleton key={i} />
          ))}
        </div>
        {/* Tables */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {Array.from({ length: 2 }).map((_, i) => (
            <TableSkeleton key={i} />
          ))}
        </div>
        {/* Vehicle cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <VehicleCardSkeleton key={i} />
          ))}
        </div>
      </div>
    )
  }

  /* ── Render ── */
  return (
    <div className="space-y-6">
      {/* ═══════════ Page Header ═══════════ */}
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">
          التقارير والتحليلات
        </h1>
        <p className="text-muted-foreground mt-1">
          تقارير شاملة عن تكاليف الصيانة وأداء الأسطول
        </p>
      </div>

      {/* ═══════════ Summary Cards Row ═══════════ */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <SummaryCard
          title="إجمالي التكاليف"
          value={formatCurrency(computed.totalCost)}
          subtitle={`${records.length} سجل صيانة`}
          icon={DollarSign}
          bgColor="bg-emerald-50 dark:bg-emerald-950/50"
          iconColor="text-emerald-600 dark:text-emerald-400"
        />
        <SummaryCard
          title="متوسط تكلفة الصيانة"
          value={formatCurrency(computed.avgCost)}
          subtitle="لكل سجل"
          icon={TrendingUp}
          bgColor="bg-blue-50 dark:bg-blue-950/50"
          iconColor="text-blue-600 dark:text-blue-400"
        />
        <SummaryCard
          title="أعلى تكلفة صيانة"
          value={formatCurrency(computed.highestCost)}
          subtitle="سجل واحد"
          icon={ArrowUpCircle}
          bgColor="bg-amber-50 dark:bg-amber-950/50"
          iconColor="text-amber-600 dark:text-amber-400"
        />
        <SummaryCard
          title="عدد السيارات المخدومة"
          value={computed.vehiclesServiced}
          subtitle={`من ${vehicles.length} سيارة`}
          icon={Car}
          bgColor="bg-purple-50 dark:bg-purple-950/50"
          iconColor="text-purple-600 dark:text-purple-400"
        />
      </div>

      {/* ═══════════ Charts Section (2x2 Grid) ═══════════ */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* ── 1. Cost Distribution by Maintenance Type (Donut) ── */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <PieChartIcon className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
              <CardTitle>توزيع التكاليف حسب نوع الصيانة</CardTitle>
            </div>
            <CardDescription>
              نسبة تكلفة كل نوع صيانة من إجمالي التكاليف
            </CardDescription>
          </CardHeader>
          <CardContent>
            {computed.typePieData.length > 0 ? (
              <div>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={computed.typePieData}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={110}
                      paddingAngle={3}
                      dataKey="value"
                      nameKey="name"
                      stroke="none"
                    >
                      {computed.typePieData.map((_, index) => (
                        <Cell
                          key={`cell-${index}`}
                          fill={CHART_COLORS[index % CHART_COLORS.length]}
                        />
                      ))}
                    </Pie>
                    <Tooltip content={<PieTooltip />} />
                    <Legend
                      content={<CustomPieLegend payload={undefined} total={computed.totalCost} />}
                      wrapperStyle={{ fontSize: '12px' }}
                    />
                  </PieChart>
                </ResponsiveContainer>
                <div className="flex flex-wrap justify-center gap-x-4 gap-y-2 mt-2">
                  {computed.typePieData.map((entry, i) => (
                    <div key={i} className="flex items-center gap-1.5 text-xs">
                      <span
                        className="w-2.5 h-2.5 rounded-full shrink-0"
                        style={{
                          backgroundColor: CHART_COLORS[i % CHART_COLORS.length],
                        }}
                      />
                      <span className="text-muted-foreground">{entry.name}</span>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <EmptyState message="لا توجد بيانات متاحة" />
            )}
          </CardContent>
        </Card>

        {/* ── 2. Monthly Cost Trend (Line Chart) ── */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Activity className="w-5 h-5 text-amber-600 dark:text-amber-400" />
              <CardTitle>اتجاه التكاليف الشهرية</CardTitle>
            </div>
            <CardDescription>
              تطور تكاليف الصيانة خلال آخر 12 شهر
            </CardDescription>
          </CardHeader>
          <CardContent>
            {computed.monthlyTrend.some((d) => d.total > 0) ? (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart
                  data={computed.monthlyTrend}
                  margin={{ top: 5, right: 10, left: 10, bottom: 5 }}
                >
                  <defs>
                    <linearGradient
                      id="reportLineGradient"
                      x1="0"
                      y1="0"
                      x2="0"
                      y2="1"
                    >
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.25} />
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0.02} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis
                    dataKey="name"
                    tick={{ fontSize: 11, fill: 'var(--foreground)' }}
                    axisLine={false}
                    tickLine={false}
                    angle={-30}
                    textAnchor="end"
                    height={60}
                    interval={0}
                  />
                  <YAxis
                    tick={{ fontSize: 12, fill: 'var(--foreground)' }}
                    tickFormatter={(v: number) =>
                      v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v)
                    }
                    width={55}
                    axisLine={false}
                    tickLine={false}
                  />
                  <Tooltip
                    content={<CurrencyTooltip />}
                    labelFormatter={(label: string) => {
                      const match = computed.monthlyTrend.find(
                        (d) => d.name === label
                      )
                      return match ? formatMonthLabel(match.month) : label
                    }}
                  />
                  <Line
                    type="monotone"
                    dataKey="total"
                    name="التكلفة"
                    stroke="#10b981"
                    strokeWidth={2.5}
                    dot={{
                      r: 3.5,
                      fill: '#10b981',
                      strokeWidth: 2,
                      stroke: 'var(--background)',
                    }}
                    activeDot={{
                      r: 6,
                      fill: '#10b981',
                      strokeWidth: 2,
                      stroke: 'var(--background)',
                    }}
                    fill="url(#reportLineGradient)"
                  />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <EmptyState message="لا توجد بيانات متاحة" />
            )}
          </CardContent>
        </Card>

        {/* ── 3. Cost by Vehicle (Horizontal Bar) ── */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Trophy className="w-5 h-5 text-purple-600 dark:text-purple-400" />
              <CardTitle>التكاليف حسب المركبة</CardTitle>
            </div>
            <CardDescription>
              أعلى 10 مركبات من حيث تكاليف الصيانة
            </CardDescription>
          </CardHeader>
          <CardContent>
            {computed.vehicleBarData.length > 0 ? (
              <ResponsiveContainer width="100%" height={320}>
                <BarChart
                  data={computed.vehicleBarData}
                  layout="vertical"
                  margin={{
                    top: 5,
                    right: 20,
                    left: 10,
                    bottom: 5,
                  }}
                >
                  <CartesianGrid
                    strokeDasharray="3 3"
                    horizontal={false}
                  />
                  <XAxis
                    type="number"
                    tick={{ fontSize: 12, fill: 'var(--foreground)' }}
                    tickFormatter={(v: number) =>
                      v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v)
                    }
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    type="category"
                    dataKey="name"
                    tick={{ fontSize: 11, fill: 'var(--foreground)' }}
                    width={120}
                    axisLine={false}
                    tickLine={false}
                  />
                  <Tooltip
                    content={({ active, payload }) => {
                      if (!active || !payload?.length) return null
                      const data = payload[0].payload as {
                        plate: string
                        total: number
                      }
                      return (
                        <div className="bg-popover text-popover-foreground border rounded-lg shadow-lg p-3 text-sm">
                          <p className="font-semibold">{data.plate}</p>
                          <p className="text-muted-foreground">
                            {formatCurrency(data.total)}
                          </p>
                        </div>
                      )
                    }}
                  />
                  <Bar
                    dataKey="total"
                    radius={[0, 6, 6, 0]}
                    maxBarSize={28}
                  >
                    {computed.vehicleBarData.map((_, index) => (
                      <Cell
                        key={`cell-${index}`}
                        fill={CHART_COLORS[index % CHART_COLORS.length]}
                      />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <EmptyState message="لا توجد بيانات متاحة" />
            )}
          </CardContent>
        </Card>

        {/* ── 4. Maintenance Status Distribution (Pie) ── */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Hash className="w-5 h-5 text-sky-600 dark:text-sky-400" />
              <CardTitle>توزيع حالات الصيانة</CardTitle>
            </div>
            <CardDescription>
              عدد سجلات الصيانة حسب الحالة
            </CardDescription>
          </CardHeader>
          <CardContent>
            {computed.statusPieData.length > 0 ? (
              <div>
                <ResponsiveContainer width="100%" height={260}>
                  <PieChart>
                    <Pie
                      data={computed.statusPieData}
                      cx="50%"
                      cy="50%"
                      innerRadius={55}
                      outerRadius={100}
                      paddingAngle={3}
                      dataKey="value"
                      nameKey="name"
                      stroke="none"
                    >
                      {computed.statusPieData.map((entry) => (
                        <Cell
                          key={`status-${entry.status}`}
                          fill={STATUS_COLORS[entry.status] ?? '#6b7280'}
                        />
                      ))}
                    </Pie>
                    <Tooltip content={<StatusTooltip />} />
                  </PieChart>
                </ResponsiveContainer>
                <div className="flex flex-wrap justify-center gap-x-4 gap-y-2 mt-2">
                  {computed.statusPieData.map((entry) => (
                    <div
                      key={entry.status}
                      className="flex items-center gap-1.5 text-xs"
                    >
                      <span
                        className="w-2.5 h-2.5 rounded-full shrink-0"
                        style={{
                          backgroundColor:
                            STATUS_COLORS[entry.status] ?? '#6b7280',
                        }}
                      />
                      <span className="text-muted-foreground">
                        {entry.name} ({entry.value})
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <EmptyState message="لا توجد بيانات متاحة" />
            )}
          </CardContent>
        </Card>
      </div>

      {/* ═══════════ Detailed Tables Section ═══════════ */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* ── Top Vehicles by Maintenance Cost Table ── */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Trophy className="w-5 h-5 text-amber-600 dark:text-amber-400" />
              <CardTitle>أعلى المركبات تكلفة صيانة</CardTitle>
            </div>
            <CardDescription>
              ترتيب المركبات حسب إجمالي تكاليف الصيانة
            </CardDescription>
          </CardHeader>
          <CardContent className="p-0 px-2 pb-2">
            {computed.topVehiclesTable.length > 0 ? (
              <ScrollArea className="max-h-[400px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-center w-12">#</TableHead>
                      <TableHead className="text-right">رقم اللوحة</TableHead>
                      <TableHead className="text-right">المركبة</TableHead>
                      <TableHead className="text-center">السجلات</TableHead>
                      <TableHead className="text-left">إجمالي التكلفة</TableHead>
                      <TableHead className="text-left">متوسط التكلفة</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {computed.topVehiclesTable.map((v) => (
                      <TableRow key={v.plateNumber}>
                        <TableCell className="text-center">
                          <span
                            className={`inline-flex items-center justify-center w-6 h-6 rounded-full text-xs font-bold ${
                              v.rank === 1
                                ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
                                : v.rank === 2
                                  ? 'bg-slate-100 text-slate-600 dark:bg-slate-800/30 dark:text-slate-400'
                                  : v.rank === 3
                                    ? 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400'
                                    : 'bg-muted text-muted-foreground'
                            }`}
                          >
                            {v.rank}
                          </span>
                        </TableCell>
                        <TableCell className="font-mono text-sm text-right font-medium">
                          {v.plateNumber}
                        </TableCell>
                        <TableCell className="text-right text-sm">
                          {v.make} {v.model}
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge variant="secondary" className="font-mono">
                            {v.totalRecords}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-left font-semibold text-sm">
                          {formatCurrency(v.totalCost)}
                        </TableCell>
                        <TableCell className="text-left text-sm text-muted-foreground">
                          {formatCurrency(v.avgCost)}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </ScrollArea>
            ) : (
              <EmptyState message="لا توجد بيانات متاحة" />
            )}
          </CardContent>
        </Card>

        {/* ── Maintenance Type Breakdown Table ── */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <FileText className="w-5 h-5 text-teal-600 dark:text-teal-400" />
              <CardTitle>تفصيل أنواع الصيانة</CardTitle>
            </div>
            <CardDescription>
              إحصائيات مفصلة لكل نوع صيانة
            </CardDescription>
          </CardHeader>
          <CardContent className="p-0 px-2 pb-2">
            {computed.typeBreakdown.length > 0 ? (
              <ScrollArea className="max-h-[400px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-right">نوع الصيانة</TableHead>
                      <TableHead className="text-center">العدد</TableHead>
                      <TableHead className="text-left">إجمالي التكلفة</TableHead>
                      <TableHead className="text-left">المتوسط</TableHead>
                      <TableHead className="text-left">الأقل</TableHead>
                      <TableHead className="text-left">الأعلى</TableHead>
                      <TableHead className="text-center">النسبة</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {computed.typeBreakdown.map((item, i) => (
                      <TableRow key={item.type}>
                        <TableCell className="text-right">
                          <div className="flex items-center gap-2">
                            <span
                              className="w-2.5 h-2.5 rounded-full shrink-0"
                              style={{
                                backgroundColor:
                                  CHART_COLORS[i % CHART_COLORS.length],
                              }}
                            />
                            <span className="text-sm font-medium">
                              {item.label}
                            </span>
                          </div>
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge variant="secondary" className="font-mono">
                            {item.count}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-left font-semibold text-sm">
                          {formatCurrency(item.totalCost)}
                        </TableCell>
                        <TableCell className="text-left text-sm text-muted-foreground">
                          {formatCurrency(item.avgCost)}
                        </TableCell>
                        <TableCell className="text-left text-sm text-muted-foreground">
                          {formatCurrency(item.minCost)}
                        </TableCell>
                        <TableCell className="text-left text-sm text-muted-foreground">
                          {formatCurrency(item.maxCost)}
                        </TableCell>
                        <TableCell className="text-center">
                          <div className="flex items-center gap-1.5 justify-center">
                            <div className="w-12 h-1.5 bg-muted rounded-full overflow-hidden">
                              <div
                                className="h-full rounded-full"
                                style={{
                                  width: `${Math.min(item.percentage, 100)}%`,
                                  backgroundColor:
                                    CHART_COLORS[i % CHART_COLORS.length],
                                }}
                              />
                            </div>
                            <span className="text-xs text-muted-foreground min-w-[36px] text-left">
                              {item.percentage.toFixed(1)}%
                            </span>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                    {/* Total row */}
                    {computed.typeBreakdown.length > 0 && (
                      <TableRow className="bg-muted/50 font-semibold">
                        <TableCell className="text-right">
                          الإجمالي
                        </TableCell>
                        <TableCell className="text-center">
                          {records.length}
                        </TableCell>
                        <TableCell className="text-left">
                          {formatCurrency(computed.totalCost)}
                        </TableCell>
                        <TableCell className="text-left">
                          {formatCurrency(computed.avgCost)}
                        </TableCell>
                        <TableCell className="text-left">-</TableCell>
                        <TableCell className="text-left">-</TableCell>
                        <TableCell className="text-center">100%</TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </ScrollArea>
            ) : (
              <EmptyState message="لا توجد بيانات متاحة" />
            )}
          </CardContent>
        </Card>
      </div>

      {/* ═══════════ Vehicle Cost Comparison Cards ═══════════ */}
      {computed.vehicleComparisonCards.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-4">
            <Truck className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
            <h2 className="text-lg font-semibold">مقارنة تكاليف المركبات</h2>
            <span className="text-sm text-muted-foreground">
              ({computed.vehicleComparisonCards.length} مركبة نشطة)
            </span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {computed.vehicleComparisonCards.map((v) => (
              <Card
                key={v.plateNumber}
                className="hover:shadow-md transition-shadow duration-200"
              >
                <CardContent className="p-5">
                  {/* Vehicle header */}
                  <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-lg bg-indigo-50 dark:bg-indigo-950/50 flex items-center justify-center shrink-0">
                      <Car className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                    </div>
                    <div className="min-w-0">
                      <p className="font-semibold text-sm truncate">
                        {v.make} {v.model} ({v.year})
                      </p>
                      <p className="text-xs text-muted-foreground font-mono">
                        {v.plateNumber}
                      </p>
                    </div>
                  </div>

                  {/* Stats grid */}
                  <div className="grid grid-cols-2 gap-3">
                    <div className="bg-muted/50 rounded-lg p-3">
                      <div className="flex items-center gap-1.5 mb-1">
                        <DollarSign className="w-3.5 h-3.5 text-emerald-500" />
                        <span className="text-xs text-muted-foreground">
                          إجمالي التكلفة
                        </span>
                      </div>
                      <p className="text-sm font-bold truncate">
                        {formatCurrency(v.totalCost)}
                      </p>
                    </div>
                    <div className="bg-muted/50 rounded-lg p-3">
                      <div className="flex items-center gap-1.5 mb-1">
                        <Wrench className="w-3.5 h-3.5 text-blue-500" />
                        <span className="text-xs text-muted-foreground">
                          عدد السجلات
                        </span>
                      </div>
                      <p className="text-sm font-bold">{v.recordCount}</p>
                    </div>
                    <div className="bg-muted/50 rounded-lg p-3">
                      <div className="flex items-center gap-1.5 mb-1">
                        <Activity className="w-3.5 h-3.5 text-amber-500" />
                        <span className="text-xs text-muted-foreground">
                          أكثر نوع صيانة
                        </span>
                      </div>
                      <p className="text-sm font-semibold truncate">
                        {v.mostCommonType}
                      </p>
                    </div>
                    <div className="bg-muted/50 rounded-lg p-3">
                      <div className="flex items-center gap-1.5 mb-1">
                        <Calendar className="w-3.5 h-3.5 text-purple-500" />
                        <span className="text-xs text-muted-foreground">
                          آخر صيانة
                        </span>
                      </div>
                      <p className="text-xs font-medium truncate">
                        {v.lastMaintenanceDate
                          ? formatDate(v.lastMaintenanceDate)
                          : '-'}
                      </p>
                    </div>
                  </div>

                  {/* Average cost bar */}
                  <div className="mt-3 pt-3 border-t">
                    <div className="flex items-center justify-between text-xs mb-1.5">
                      <span className="text-muted-foreground">
                        متوسط التكلفة لكل سجل
                      </span>
                      <span className="font-semibold">
                        {formatCurrency(v.avgCost)}
                      </span>
                    </div>
                    <div className="w-full h-1.5 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full bg-indigo-500 transition-all duration-500"
                        style={{
                          width: `${Math.min(
                            (v.avgCost / (computed.highestCost || 1)) * 100,
                            100
                          )}%`,
                        }}
                      />
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* ═══════════ Empty state when no records at all ═══════════ */}
      {records.length === 0 && !maintenanceLoading && (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-20 text-center">
            <div className="w-16 h-16 rounded-2xl bg-rose-50 dark:bg-rose-950/50 flex items-center justify-center mb-4">
              <AlertTriangle className="w-8 h-8 text-rose-600 dark:text-rose-400" />
            </div>
            <h3 className="text-lg font-semibold mb-2">لا توجد بيانات للتقرير</h3>
            <p className="text-muted-foreground text-sm max-w-md">
              لم يتم تسجيل أي سجلات صيانة بعد. ابدأ بإضافة سجلات الصيانة
              لتظهر التقارير والتحليلات هنا.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
