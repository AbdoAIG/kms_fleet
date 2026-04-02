'use client'

import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import {
  Building2, Settings as SettingsIcon, Database, Activity, Trash2,
  Upload, Globe, Palette, Info, AlertTriangle, CheckCircle, Clock, Car, Wrench,
  RefreshCw, Shield, Download,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Skeleton } from '@/components/ui/skeleton'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import {
  formatCurrency,
  formatNumber,
  formatDate,
} from '@/lib/constants'

/* ─── Zod Schema for Company Info ─── */
const companyFormSchema = z.object({
  companyName: z.string().min(1, 'اسم الشركة مطلوب'),
  phone: z.string().optional().default(''),
  email: z.string().email('بريد إلكتروني غير صالح').optional().default('').or(z.literal('')),
  website: z.string().optional().default(''),
  address: z.string().optional().default(''),
})

type CompanyFormValues = z.infer<typeof companyFormSchema>

/* ─── Types ─── */
interface ActivityLogEntry {
  id: string
  action: string
  entity: string
  entityId: string | null
  details: string | null
  user: { id: string; name: string; email: string; role: string } | null
  createdAt: string
}

interface ActivityLogResponse {
  logs: ActivityLogEntry[]
  total: number
  pages: number
  page: number
  limit: number
}

interface DashboardStats {
  stats: {
    totalVehicles: number
    activeVehicles: number
    maintenanceRecords: number
    totalCost: number
  }
}

/* ─── Currencies ─── */
const CURRENCIES = [
  { value: 'EGP', label: 'جنيه مصري (EGP)', flag: '🇪🇬' },
  { value: 'SAR', label: 'ريال سعودي (SAR)', flag: '🇸🇦' },
  { value: 'USD', label: 'دولار أمريكي (USD)', flag: '🇺🇸' },
  { value: 'AED', label: 'درهم إماراتي (AED)', flag: '🇦🇪' },
  { value: 'KWD', label: 'دينار كويتي (KWD)', flag: '🇰🇼' },
]

/* ─── System Info Data ─── */
const SYSTEM_INFO = [
  { label: 'إصدار التطبيق', value: '2.0.0', icon: Info },
  { label: 'الإطار', value: 'Next.js 16', icon: Globe },
  { label: 'قاعدة البيانات', value: 'SQLite + Prisma', icon: Database },
  { label: 'واجهة المستخدم', value: 'shadcn/ui + Tailwind CSS', icon: Palette },
]

/* ─── Activity Helpers ─── */
function getActivityIcon(action: string, entity: string) {
  if (action === 'CREATE') return <CheckCircle className="w-4 h-4 text-emerald-500" />
  if (action === 'DELETE') return <Trash2 className="w-4 h-4 text-red-500" />
  if (action === 'UPDATE') return <RefreshCw className="w-4 h-4 text-blue-500" />
  if (action === 'LOGIN') return <Info className="w-4 h-4 text-slate-500" />
  if (action === 'EXPORT') return <Download className="w-4 h-4 text-purple-500" />
  if (action === 'SEED') return <Upload className="w-4 h-4 text-teal-500" />
  if (entity === 'VEHICLE') return <Car className="w-4 h-4 text-purple-500" />
  if (entity === 'MAINTENANCE') return <Wrench className="w-4 h-4 text-amber-500" />
  return <Activity className="w-4 h-4 text-slate-500" />
}

function getActionLabel(action: string, entity: string, details: string | null) {
  if (details) return details
  const actionLabels: Record<string, string> = {
    CREATE: 'إنشاء',
    UPDATE: 'تعديل',
    DELETE: 'حذف',
    LOGIN: 'تسجيل دخول',
    LOGOUT: 'تسجيل خروج',
    EXPORT: 'تصدير',
    SEED: 'إضافة بيانات تجريبية',
  }
  const entityLabels: Record<string, string> = {
    VEHICLE: 'مركبة',
    MAINTENANCE: 'سجل صيانة',
    USER: 'مستخدم',
    SETTINGS: 'إعدادات',
  }
  const a = actionLabels[action] || action
  const e = entityLabels[entity] || entity
  return `${a}: ${e}`
}

/* ─── Company Info Section ─── */
function CompanyInfoSection() {
  const queryClient = useQueryClient()

  const { data: settings, isLoading: loadingSettings } = useQuery({
    queryKey: ['settings'],
    queryFn: () =>
      fetch('/api/settings').then((r) => {
        if (!r.ok) throw new Error('Failed to fetch settings')
        return r.json()
      }),
  })

  const form = useForm<CompanyFormValues>({
    resolver: zodResolver(companyFormSchema),
    defaultValues: {
      companyName: '',
      phone: '',
      email: '',
      website: '',
      address: '',
    },
  })

  useEffect(() => {
    if (settings) {
      form.reset({
        companyName: settings.companyName || '',
        phone: settings.phone || '',
        email: settings.email || '',
        website: settings.website || '',
        address: settings.address || '',
      })
    }
  }, [settings, form])

  const saveMutation = useMutation({
    mutationFn: (data: CompanyFormValues) =>
      fetch('/api/settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      }).then((r) => {
        if (!r.ok) return r.json().then((err) => { throw new Error(err.error || 'حدث خطأ') })
        return r.json()
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings'] })
      toast.success('تم حفظ معلومات الشركة بنجاح')
    },
    onError: (error: Error) => {
      toast.error(error.message || 'حدث خطأ أثناء الحفظ')
    },
  })

  function onSubmit(data: CompanyFormValues) {
    saveMutation.mutate(data)
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <Building2 className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
          <CardTitle>معلومات الشركة</CardTitle>
        </div>
        <CardDescription>بيانات الشركة الأساسية التي تظهر في النظام</CardDescription>
      </CardHeader>
      <CardContent>
        {loadingSettings ? (
          <div className="space-y-4">
            <Skeleton className="h-10 w-full" />
            <Skeleton className="h-10 w-full" />
            <Skeleton className="h-10 w-full" />
          </div>
        ) : (
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="companyName"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>اسم الشركة *</FormLabel>
                      <FormControl>
                        <Input placeholder="اسم الشركة" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="phone"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>رقم الهاتف</FormLabel>
                      <FormControl>
                        <Input placeholder="رقم الهاتف" dir="ltr" className="text-left" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>البريد الإلكتروني</FormLabel>
                      <FormControl>
                        <Input placeholder="email@company.com" dir="ltr" className="text-left" type="email" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="website"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>الموقع الإلكتروني</FormLabel>
                      <FormControl>
                        <Input placeholder="www.company.com" dir="ltr" className="text-left" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="address"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>العنوان</FormLabel>
                    <FormControl>
                      <Input placeholder="عنوان الشركة" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <Button
                type="submit"
                disabled={saveMutation.isPending}
                className="bg-emerald-600 hover:bg-emerald-700 text-white"
              >
                {saveMutation.isPending ? (
                  <span className="flex items-center gap-2">
                    <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    جاري الحفظ...
                  </span>
                ) : (
                  <span className="flex items-center gap-1.5">
                    <Upload className="w-4 h-4" />
                    حفظ المعلومات
                  </span>
                )}
              </Button>
            </form>
          </Form>
        )}
      </CardContent>
    </Card>
  )
}

/* ─── System Preferences Section ─── */
function SystemPreferencesSection() {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <SettingsIcon className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
          <CardTitle>تفضيلات النظام</CardTitle>
        </div>
        <CardDescription>إعدادات العرض والعملة في النظام</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label>العملة الافتراضية</Label>
            <Select defaultValue="EGP">
              <SelectTrigger>
                <SelectValue placeholder="اختر العملة" />
              </SelectTrigger>
              <SelectContent>
                {CURRENCIES.map((c) => (
                  <SelectItem key={c.value} value={c.value}>
                    <span className="flex items-center gap-2">
                      <span>{c.flag}</span>
                      {c.label}
                    </span>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label>لغة العرض</Label>
            <div className="flex items-center h-10 px-3 rounded-md border bg-muted/50">
              <span className="text-sm font-medium">🇪🇬 العربية</span>
              <Badge variant="secondary" className="mr-auto text-xs">الافتراضي</Badge>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

/* ─── Data Management Section ─── */
function DataManagementSection() {
  const queryClient = useQueryClient()
  const [showClearDialog, setShowClearDialog] = useState(false)

  const { data: dashboardData, isLoading: loadingStats } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats'],
    queryFn: () =>
      fetch('/api/dashboard/stats').then((r) => {
        if (!r.ok) throw new Error('Failed to fetch stats')
        return r.json()
      }),
  })

  const seedMutation = useMutation({
    mutationFn: () =>
      fetch('/api/seed', { method: 'POST' }).then((r) => r.json()),
    onSuccess: (data) => {
      queryClient.invalidateQueries()
      if (data.seeded) {
        toast.success(`تم إضافة البيانات التجريبية بنجاح (${data.vehiclesCount} سيارة، ${data.recordsCount} سجل)`)
      } else {
        toast.info(data.message || 'البيانات موجودة بالفعل')
      }
    },
    onError: () => {
      toast.error('حدث خطأ أثناء إضافة البيانات التجريبية')
    },
  })

  const clearMutation = useMutation({
    mutationFn: () =>
      fetch('/api/data/clear', { method: 'DELETE' }).then((r) => {
        if (!r.ok) throw new Error('Failed to clear data')
        return r.json()
      }),
    onSuccess: () => {
      queryClient.invalidateQueries()
      setShowClearDialog(false)
      toast.success('تم حذف جميع البيانات بنجاح')
    },
    onError: () => {
      toast.error('حدث خطأ أثناء حذف البيانات')
    },
  })

  function downloadCSV(type: 'vehicles' | 'maintenance' | 'reports') {
    toast.info('جاري تجهيز ملف التصدير...')
    fetch(`/api/export?type=${type}`)
      .then((r) => {
        if (!r.ok) throw new Error('Export failed')
        return r.blob()
      })
      .then((blob) => {
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `fleet_${type}_${new Date().toISOString().slice(0, 10)}.csv`
        document.body.appendChild(a)
        a.click()
        window.URL.revokeObjectURL(url)
        document.body.removeChild(a)
        toast.success('تم تصدير الملف بنجاح')
      })
      .catch(() => {
        toast.error('حدث خطأ أثناء تصدير البيانات')
      })
  }

  const vehicleCount = dashboardData?.stats?.totalVehicles ?? 0
  const recordCount = dashboardData?.stats?.maintenanceRecords ?? 0

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Database className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
            <CardTitle>إدارة البيانات</CardTitle>
          </div>
          <CardDescription>إدارة بيانات النظام والنسخ الاحتياطي</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Database Stats */}
          <div className="grid grid-cols-2 gap-4">
            {loadingStats ? (
              <>
                <Skeleton className="h-20 w-full rounded-lg" />
                <Skeleton className="h-20 w-full rounded-lg" />
              </>
            ) : (
              <>
                <div className="flex items-center gap-3 p-3 rounded-lg bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200/50 dark:border-emerald-800/30">
                  <Car className="w-8 h-8 text-emerald-600 dark:text-emerald-400" />
                  <div>
                    <p className="text-xs text-muted-foreground">عدد السيارات</p>
                    <p className="text-xl font-bold text-emerald-700 dark:text-emerald-400">
                      {formatNumber(vehicleCount)}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 rounded-lg bg-amber-50 dark:bg-amber-950/30 border border-amber-200/50 dark:border-amber-800/30">
                  <Wrench className="w-8 h-8 text-amber-600 dark:text-amber-400" />
                  <div>
                    <p className="text-xs text-muted-foreground">سجلات الصيانة</p>
                    <p className="text-xl font-bold text-amber-700 dark:text-amber-400">
                      {formatNumber(recordCount)}
                    </p>
                  </div>
                </div>
              </>
            )}
          </div>

          <Separator />

          {/* Action Buttons */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <Button
              variant="outline"
              onClick={() => seedMutation.mutate()}
              disabled={seedMutation.isPending}
              className="h-11 justify-start"
            >
              <Upload className="w-4 h-4 ml-2" />
              {seedMutation.isPending ? 'جاري إضافة البيانات...' : 'إضافة بيانات تجريبية'}
            </Button>

            <Button
              variant="outline"
              className="h-11 justify-start text-red-600 hover:text-red-700 hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/30 border-red-200 dark:border-red-800"
              onClick={() => setShowClearDialog(true)}
            >
              <Trash2 className="w-4 h-4 ml-2" />
              حذف جميع البيانات
            </Button>

            <Button
              variant="outline"
              className="h-11 justify-start"
              onClick={() => downloadCSV('vehicles')}
            >
              <Download className="w-4 h-4 ml-2" />
              تصدير بيانات السيارات (CSV)
            </Button>

            <Button
              variant="outline"
              className="h-11 justify-start"
              onClick={() => downloadCSV('maintenance')}
            >
              <Download className="w-4 h-4 ml-2" />
              تصدير سجلات الصيانة (CSV)
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Clear Data Confirmation */}
      <AlertDialog open={showClearDialog} onOpenChange={setShowClearDialog}>
        <AlertDialogContent dir="rtl">
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-red-500" />
              تأكيد حذف جميع البيانات
            </AlertDialogTitle>
            <AlertDialogDescription className="leading-relaxed">
              هل أنت متأكد من حذف جميع البيانات؟ سيتم حذف جميع السيارات وسجلات الصيانة نهائياً.
              <span className="block mt-2 text-red-600 dark:text-red-400 font-medium">
                ⚠ هذا الإجراء لا يمكن التراجع عنه!
              </span>
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter className="flex-col-reverse gap-2 sm:flex-row">
            <AlertDialogCancel disabled={clearMutation.isPending}>
              إلغاء
            </AlertDialogCancel>
            <Button
              variant="destructive"
              onClick={() => clearMutation.mutate()}
              disabled={clearMutation.isPending}
            >
              {clearMutation.isPending ? (
                <span className="flex items-center gap-2">
                  <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  جاري الحذف...
                </span>
              ) : (
                <span className="flex items-center gap-1.5">
                  <Trash2 className="w-4 h-4" />
                  نعم، حذف الكل
                </span>
              )}
            </Button>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}

/* ─── Activity Log Section ─── */
function ActivityLogSection() {
  const { data, isLoading } = useQuery<ActivityLogResponse>({
    queryKey: ['activity-log'],
    queryFn: () =>
      fetch('/api/activity-log?limit=20').then((r) => {
        if (!r.ok) throw new Error('Failed to fetch activity log')
        return r.json()
      }),
  })

  const logs = data?.logs || []

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <Activity className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
          <CardTitle>سجل النشاط</CardTitle>
        </div>
        <CardDescription>آخر العمليات والإجراءات المنفذة في النظام</CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="flex items-start gap-3">
                <Skeleton className="w-8 h-8 rounded-full shrink-0" />
                <div className="flex-1 space-y-1.5">
                  <Skeleton className="h-4 w-3/4" />
                  <Skeleton className="h-3 w-1/2" />
                </div>
              </div>
            ))}
          </div>
        ) : logs.length > 0 ? (
          <ScrollArea className="max-h-96">
            <div className="space-y-1">
              {logs.slice(0, 20).map((log) => (
                <div
                  key={log.id}
                  className="flex items-start gap-3 p-3 rounded-lg hover:bg-muted/50 transition-colors"
                >
                  <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center shrink-0 mt-0.5">
                    {getActivityIcon(log.action, log.entity)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-foreground">
                      {getActionLabel(log.action, log.entity, log.details)}
                    </p>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-xs text-muted-foreground flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {formatDate(log.createdAt)}
                      </span>
                      {log.user && (
                        <span className="text-xs text-muted-foreground">
                          • {log.user.name}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </ScrollArea>
        ) : (
          <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
            <Clock className="w-10 h-10 mb-2 opacity-40" />
            <p className="text-sm">لا توجد سجلات نشاط حتى الآن</p>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

/* ─── System Info Section ─── */
function SystemInfoSection() {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <Info className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
          <CardTitle>معلومات النظام</CardTitle>
        </div>
        <CardDescription>معلومات تقنية عن النظام والمكونات المستخدمة</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {SYSTEM_INFO.map((item) => {
            const Icon = item.icon
            return (
              <div
                key={item.label}
                className="flex items-center justify-between p-3 rounded-lg bg-muted/30 hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-lg bg-background flex items-center justify-center border shadow-sm">
                    <Icon className="w-4 h-4 text-muted-foreground" />
                  </div>
                  <span className="text-sm font-medium text-foreground">{item.label}</span>
                </div>
                <Badge variant="secondary" className="text-xs font-mono">
                  {item.value}
                </Badge>
              </div>
            )
          })}
        </div>

        <Separator className="my-4" />

        <div className="flex items-center gap-2 text-xs text-muted-foreground">
          <Shield className="w-3.5 h-3.5" />
          <span>جميع البيانات مخزنة محلياً على الخادم ولا يتم مشاركتها مع أي طرف ثالث</span>
        </div>
      </CardContent>
    </Card>
  )
}

/* ─── Main Settings View ─── */
export default function SettingsView() {
  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h2 className="text-xl font-bold text-foreground">إعدادات النظام</h2>
        <p className="text-sm text-muted-foreground mt-0.5">
          تخصيص وإدارة إعدادات النظام والبيانات
        </p>
      </div>

      {/* Tabbed Layout */}
      <Tabs defaultValue="general" dir="rtl">
        <TabsList className="w-full sm:w-auto grid grid-cols-2 sm:grid-cols-4 gap-1">
          <TabsTrigger value="general" className="text-xs sm:text-sm">عام</TabsTrigger>
          <TabsTrigger value="data" className="text-xs sm:text-sm">البيانات</TabsTrigger>
          <TabsTrigger value="activity" className="text-xs sm:text-sm">النشاط</TabsTrigger>
          <TabsTrigger value="system" className="text-xs sm:text-sm">النظام</TabsTrigger>
        </TabsList>

        <TabsContent value="general" className="mt-6 space-y-6">
          <CompanyInfoSection />
          <SystemPreferencesSection />
        </TabsContent>

        <TabsContent value="data" className="mt-6">
          <DataManagementSection />
        </TabsContent>

        <TabsContent value="activity" className="mt-6">
          <ActivityLogSection />
        </TabsContent>

        <TabsContent value="system" className="mt-6">
          <SystemInfoSection />
        </TabsContent>
      </Tabs>
    </div>
  )
}
