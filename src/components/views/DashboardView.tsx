'use client'

import { type ComponentType } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  Car,
  Wrench,
  DollarSign,
  CheckCircle,
  AlertTriangle,
  TrendingUp,
  Activity,
  Calendar,
  BarChart3,
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
  getPriorityLabel,
} from '@/lib/constants'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  AreaChart,
  Area,
  Cell,
} from 'recharts'

/* ─── Chart Colors ─── */
const CHART_COLORS = [
  '#10b981',
  '#f59e0b',
  '#ef4444',
  '#14b8a6',
  '#f97316',
  '#8b5cf6',
  '#06b6d4',
  '#ec4899',
  '#84cc16',
  '#6366f1',
]

/* ─── Types ─── */
interface DashboardData {
  stats: {
    totalVehicles: number
    activeVehicles: number
    maintenanceRecords: number
    totalCost: number
  }
  costByType: { type: string; total: number }[]
  monthlyTrend: { month: string; total: number }[]
  recentRecords: Array<{
    id: string
    description: string
    type: string
    cost: number
    maintenanceDate: string
    status: string
    priority: string
    vehicle: {
      plateNumber: string
      make: string
      model: string
    }
  }>
  upcomingMaintenance: Array<{
    id: string
    description: string
    type: string
    priority: string
    nextMaintenanceDate: string | null
    vehicle: {
      id: string
      plateNumber: string
      make: string
      model: string
    }
  }>
}

/* ─── Helpers ─── */
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

function getStatusClasses(status: string): string {
  switch (status) {
    case 'COMPLETED':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
    case 'PENDING':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
    case 'IN_PROGRESS':
      return 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-400'
    case 'CANCELLED':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

function getPriorityClasses(priority: string): string {
  switch (priority) {
    case 'URGENT':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    case 'HIGH':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
    case 'NORMAL':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
    case 'LOW':
      return 'bg-slate-100 text-slate-600 dark:bg-slate-900/30 dark:text-slate-400'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

/* ─── Stat Card Skeleton ─── */
function StatCardSkeleton() {
  return (
    <Card>
      <CardContent className="flex items-center gap-4">
        <Skeleton className="w-12 h-12 rounded-lg" />
        <div className="flex-1 space-y-2">
          <Skeleton className="h-4 w-24" />
          <Skeleton className="h-7 w-16" />
        </div>
      </CardContent>
    </Card>
  )
}

/* ─── Chart Skeleton ─── */
function ChartSkeleton() {
  return (
    <Card>
      <CardHeader>
        <Skeleton className="h-5 w-40" />
        <Skeleton className="h-4 w-56" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-[300px] w-full rounded-lg" />
      </CardContent>
    </Card>
  )
}

/* ─── Table Skeleton ─── */
function TableSkeleton() {
  return (
    <Card>
      <CardHeader>
        <Skeleton className="h-5 w-48" />
        <Skeleton className="h-4 w-64" />
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-12 w-full rounded-md" />
          ))}
        </div>
      </CardContent>
    </Card>
  )
}

/* ─── Stat Card ─── */
function StatCard({
  title,
  value,
  icon: Icon,
  bgColor,
  iconColor,
}: {
  title: string
  value: string | number
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
          <p className="text-2xl font-bold tracking-tight truncate">{value}</p>
        </div>
      </CardContent>
    </Card>
  )
}

/* ─── Custom Tooltip for Charts ─── */
function ChartTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean
  payload?: Array<{ value: number }>
  label?: string
}) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-popover text-popover-foreground border rounded-lg shadow-lg p-3 text-sm">
      <p className="font-semibold mb-1">{label}</p>
      <p className="text-muted-foreground">
        {formatCurrency(payload[0].value)}
      </p>
    </div>
  )
}

/* ─── Main Dashboard View ─── */
export default function DashboardView() {
  const { data, isLoading, isError } = useQuery<DashboardData>({
    queryKey: ['dashboard-stats'],
    queryFn: () =>
      fetch('/api/dashboard/stats').then((r) => {
        if (!r.ok) throw new Error('Failed to fetch')
        return r.json()
      }),
  })

  const stats = data?.stats

  const barChartData = data?.costByType.map((item) => ({
    name: getMaintenanceTypeLabel(item.type),
    value: Math.round(item.total),
  }))

  const areaChartData = data?.monthlyTrend.map((item) => ({
    ...item,
    name: formatMonthShort(item.month),
  }))

  /* ── Loading State ── */
  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <StatCardSkeleton key={i} />
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <ChartSkeleton />
          <ChartSkeleton />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            <TableSkeleton />
          </div>
          <Card>
            <CardHeader>
              <Skeleton className="h-5 w-36" />
              <Skeleton className="h-4 w-48" />
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {Array.from({ length: 3 }).map((_, i) => (
                  <Skeleton key={i} className="h-20 w-full rounded-lg" />
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    )
  }

  /* ── Error State ── */
  if (isError) {
    return (
      <Card className="border-destructive">
        <CardContent className="flex flex-col items-center justify-center py-16 text-center">
          <AlertTriangle className="w-12 h-12 text-destructive mb-4" />
          <h3 className="text-lg font-semibold mb-2">
            حدث خطأ أثناء تحميل البيانات
          </h3>
          <p className="text-muted-foreground text-sm">
            يرجى المحاولة مرة أخرى لاحقاً
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      {/* ── Stats Cards Row ── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="إجمالي السيارات"
          value={stats?.totalVehicles ?? 0}
          icon={Car}
          bgColor="bg-emerald-50 dark:bg-emerald-950/50"
          iconColor="text-emerald-600 dark:text-emerald-400"
        />
        <StatCard
          title="سيارات نشطة"
          value={stats?.activeVehicles ?? 0}
          icon={CheckCircle}
          bgColor="bg-green-50 dark:bg-green-950/50"
          iconColor="text-green-600 dark:text-green-400"
        />
        <StatCard
          title="سجلات الصيانة"
          value={stats?.maintenanceRecords ?? 0}
          icon={Wrench}
          bgColor="bg-amber-50 dark:bg-amber-950/50"
          iconColor="text-amber-600 dark:text-amber-400"
        />
        <StatCard
          title="إجمالي التكاليف"
          value={formatCurrency(stats?.totalCost ?? 0)}
          icon={DollarSign}
          bgColor="bg-rose-50 dark:bg-rose-950/50"
          iconColor="text-rose-600 dark:text-rose-400"
        />
      </div>

      {/* ── Charts Section ── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Bar Chart – Cost by Maintenance Type */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
              <CardTitle>التكاليف حسب نوع الصيانة</CardTitle>
            </div>
            <CardDescription>
              توزيع تكاليف الصيانة على الأنواع المختلفة
            </CardDescription>
          </CardHeader>
          <CardContent>
            {barChartData && barChartData.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart
                  data={barChartData}
                  margin={{ top: 5, right: 10, left: 10, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis
                    dataKey="name"
                    tick={{ fontSize: 11, fill: 'var(--foreground)' }}
                    angle={-25}
                    textAnchor="end"
                    height={70}
                    interval={0}
                  />
                  <YAxis
                    tick={{ fontSize: 12, fill: 'var(--foreground)' }}
                    tickFormatter={(v: number) =>
                      `${(v / 1000).toFixed(0)}k`
                    }
                    width={55}
                  />
                  <Tooltip content={<ChartTooltip />} />
                  <Bar
                    dataKey="value"
                    radius={[6, 6, 0, 0]}
                    maxBarSize={48}
                  >
                    {barChartData.map((_, index) => (
                      <Cell
                        key={`cell-${index}`}
                        fill={CHART_COLORS[index % CHART_COLORS.length]}
                      />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex items-center justify-center h-[300px] text-muted-foreground text-sm">
                <div className="text-center">
                  <BarChart3 className="w-10 h-10 mx-auto mb-2 opacity-40" />
                  <p>لا توجد بيانات متاحة</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Area Chart – Monthly Cost Trend */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Activity className="w-5 h-5 text-amber-600 dark:text-amber-400" />
              <CardTitle>اتجاه التكاليف الشهرية</CardTitle>
            </div>
            <CardDescription>
              تطور تكاليف الصيانة خلال الأشهر الستة الماضية
            </CardDescription>
          </CardHeader>
          <CardContent>
            {areaChartData && areaChartData.some((d) => d.total > 0) ? (
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart
                  data={areaChartData}
                  margin={{ top: 5, right: 10, left: 10, bottom: 5 }}
                >
                  <defs>
                    <linearGradient
                      id="costGradient"
                      x1="0"
                      y1="0"
                      x2="0"
                      y2="1"
                    >
                      <stop
                        offset="5%"
                        stopColor="#10b981"
                        stopOpacity={0.3}
                      />
                      <stop
                        offset="95%"
                        stopColor="#10b981"
                        stopOpacity={0.02}
                      />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis
                    dataKey="name"
                    tick={{ fontSize: 12, fill: 'var(--foreground)' }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    tick={{ fontSize: 12, fill: 'var(--foreground)' }}
                    tickFormatter={(v: number) =>
                      `${(v / 1000).toFixed(0)}k`
                    }
                    width={55}
                    axisLine={false}
                    tickLine={false}
                  />
                  <Tooltip
                    content={<ChartTooltip />}
                    labelFormatter={(label: string) => {
                      const match = areaChartData?.find(
                        (d) => d.name === label
                      )
                      return match ? formatMonthLabel(match.month) : label
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="total"
                    stroke="#10b981"
                    strokeWidth={2.5}
                    fill="url(#costGradient)"
                    dot={{
                      r: 4,
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
                  />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex items-center justify-center h-[300px] text-muted-foreground text-sm">
                <div className="text-center">
                  <Activity className="w-10 h-10 mx-auto mb-2 opacity-40" />
                  <p>لا توجد بيانات متاحة</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* ── Recent Records + Upcoming Maintenance ── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Maintenance Records Table */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <div className="flex items-center gap-2">
              <Wrench className="w-5 h-5 text-amber-600 dark:text-amber-400" />
              <CardTitle>أحدث سجلات الصيانة</CardTitle>
            </div>
            <CardDescription>
              آخر 5 سجلات صيانة مسجلة في النظام
            </CardDescription>
          </CardHeader>
          <CardContent className="p-0 px-2 pb-2">
            {data?.recentRecords && data.recentRecords.length > 0 ? (
              <ScrollArea className="max-h-96">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-right">المركبة</TableHead>
                      <TableHead className="text-right">
                        نوع الصيانة
                      </TableHead>
                      <TableHead className="text-right">التكلفة</TableHead>
                      <TableHead className="text-right">التاريخ</TableHead>
                      <TableHead className="text-right">الحالة</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {data.recentRecords.map((record) => (
                      <TableRow key={record.id}>
                        <TableCell className="font-medium text-right">
                          <div>
                            <p className="text-sm">
                              {record.vehicle.make} {record.vehicle.model}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              {record.vehicle.plateNumber}
                            </p>
                          </div>
                        </TableCell>
                        <TableCell className="text-right">
                          <span className="text-sm">
                            {getMaintenanceTypeLabel(record.type)}
                          </span>
                        </TableCell>
                        <TableCell className="text-right font-semibold">
                          {formatCurrency(record.cost)}
                        </TableCell>
                        <TableCell className="text-right text-sm text-muted-foreground">
                          {formatDate(record.maintenanceDate)}
                        </TableCell>
                        <TableCell className="text-right">
                          <Badge
                            variant="secondary"
                            className={getStatusClasses(record.status)}
                          >
                            {getMaintenanceStatusLabel(record.status)}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </ScrollArea>
            ) : (
              <div className="flex items-center justify-center py-16 text-muted-foreground text-sm">
                <div className="text-center">
                  <Wrench className="w-10 h-10 mx-auto mb-2 opacity-40" />
                  <p>لا توجد سجلات صيانة حتى الآن</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Upcoming Maintenance Alerts */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-amber-500" />
              <CardTitle>صيانة قادمة</CardTitle>
            </div>
            <CardDescription>
              سيارات تحتاج صيانة خلال 30 يوم
            </CardDescription>
          </CardHeader>
          <CardContent>
            {data?.upcomingMaintenance &&
            data.upcomingMaintenance.length > 0 ? (
              <ScrollArea className="max-h-96">
                <div className="space-y-3">
                  {data.upcomingMaintenance.map((record) => (
                    <div
                      key={record.id}
                      className="flex items-start gap-3 p-3 rounded-xl border border-amber-200/50 bg-amber-50/50 dark:border-amber-800/30 dark:bg-amber-950/20 transition-colors hover:bg-amber-100/50 dark:hover:bg-amber-950/40"
                    >
                      <div className="w-9 h-9 rounded-lg bg-amber-100 dark:bg-amber-900/40 flex items-center justify-center shrink-0 mt-0.5">
                        <Calendar className="w-4 h-4 text-amber-600 dark:text-amber-400" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-semibold truncate">
                          {record.vehicle.make} {record.vehicle.model}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {record.vehicle.plateNumber}
                        </p>
                        <div className="flex items-center gap-2 mt-1.5 flex-wrap">
                          {record.nextMaintenanceDate && (
                            <span className="text-xs text-amber-700 dark:text-amber-400 flex items-center gap-1">
                              <Calendar className="w-3 h-3" />
                              {formatDate(record.nextMaintenanceDate)}
                            </span>
                          )}
                          <Badge
                            variant="outline"
                            className={`text-xs border-0 ${getPriorityClasses(record.priority)}`}
                          >
                            {getPriorityLabel(record.priority)}
                          </Badge>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </ScrollArea>
            ) : (
              <div className="flex items-center justify-center py-12 text-muted-foreground text-sm">
                <div className="text-center">
                  <CheckCircle className="w-10 h-10 mx-auto mb-2 text-emerald-300 opacity-60" />
                  <p>لا توجد صيانة قادمة</p>
                  <p className="text-xs mt-1">جميع السيارات في حالة جيدة</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
