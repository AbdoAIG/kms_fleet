'use client'

import { useState, useEffect, useCallback, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { format, parseISO } from 'date-fns'
import { ar } from 'date-fns/locale'
import {
  Plus,
  Search,
  Filter,
  X,
  Pencil,
  Trash2,
  Wrench,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  ArrowRight,
  CalendarIcon,
  AlertTriangle,
  Loader2,
  Car,
} from 'lucide-react'
import { toast } from '@/hooks/use-toast'
import { useAppStore } from '@/lib/store'
import {
  MAINTENANCE_TYPES,
  MAINTENANCE_STATUSES,
  PRIORITIES,
  getMaintenanceTypeLabel,
  getMaintenanceStatusLabel,
  getPriorityLabel,
  formatCurrency,
  formatDate,
  formatNumber,
} from '@/lib/constants'
import { cn } from '@/lib/utils'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent } from '@/components/ui/card'
import { Label } from '@/components/ui/label'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Separator } from '@/components/ui/separator'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
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
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from '@/components/ui/tooltip'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Calendar } from '@/components/ui/calendar'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'

/* ─── Types ─── */
interface VehicleOption {
  id: string
  plateNumber: string
  make: string
  model: string
}

interface MaintenanceRecord {
  id: string
  vehicleId: string
  maintenanceDate: string
  description: string
  type: string
  cost: number
  kilometerReading: number | null
  serviceProvider: string | null
  invoiceNumber: string | null
  laborCost: number | null
  partsCost: number | null
  nextMaintenanceDate: string | null
  nextMaintenanceKm: number | null
  priority: string
  status: string
  notes: string | null
  createdAt: string
  vehicle: {
    id: string
    plateNumber: string
    make: string
    model: string
  }
}

interface MaintenanceResponse {
  records: MaintenanceRecord[]
  total: number
  pages: number
  page: number
  limit: number
}

/* ─── Form Schema ─── */
const maintenanceFormSchema = z.object({
  vehicleId: z.string().min(1, 'يرجى اختيار المركبة'),
  maintenanceDate: z.string().min(1, 'يرجى تحديد تاريخ الصيانة'),
  description: z.string().min(1, 'يرجى إدخال البيان').max(500, 'البيان طويل جداً'),
  type: z.string().min(1, 'يرجى اختيار نوع الصيانة'),
  cost: z.coerce.number().min(0, 'التكلفة يجب أن تكون ٠ أو أكبر'),
  partsCost: z.coerce.number().min(0, 'تكلفة القطع يجب أن تكون ٠ أو أكبر').optional().or(z.literal('')),
  laborCost: z.coerce.number().min(0, 'تكلفة العمالة يجب أن تكون ٠ أو أكبر').optional().or(z.literal('')),
  kilometerReading: z.coerce.number().min(0, 'عداد الكيلومتر يجب أن يكون ٠ أو أكبر').optional().or(z.literal('')),
  serviceProvider: z.string().max(200, 'النص طويل جداً').optional().or(z.literal('')),
  invoiceNumber: z.string().max(100, 'النص طويل جداً').optional().or(z.literal('')),
  nextMaintenanceDate: z.string().optional().or(z.literal('')),
  nextMaintenanceKm: z.coerce.number().min(0).optional().or(z.literal('')),
  priority: z.string().min(1, 'يرجى اختيار الأولوية'),
  status: z.string().min(1, 'يرجى اختيار الحالة'),
  notes: z.string().max(1000, 'الملاحظات طويلة جداً').optional().or(z.literal('')),
})

type MaintenanceFormData = z.infer<typeof maintenanceFormSchema>

/* ─── Badge Color Helpers ─── */
function getTypeBadgeClasses(type: string): string {
  switch (type) {
    case 'OIL_CHANGE':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800'
    case 'TIRE':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border-amber-200 dark:border-amber-800'
    case 'ELECTRICAL':
      return 'bg-cyan-100 text-cyan-700 dark:bg-cyan-900/30 dark:text-cyan-400 border-cyan-200 dark:border-cyan-800'
    case 'MECHANICAL':
      return 'bg-slate-100 text-slate-700 dark:bg-slate-900/30 dark:text-slate-400 border-slate-200 dark:border-slate-800'
    case 'BRAKES':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border-red-200 dark:border-red-800'
    case 'BODYWORK':
      return 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400 border-purple-200 dark:border-purple-800'
    case 'AC':
      return 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-400 border-sky-200 dark:border-sky-800'
    case 'TRANSMISSION':
      return 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400 border-orange-200 dark:border-orange-800'
    case 'FILTER':
      return 'bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-400 border-teal-200 dark:border-teal-800'
    case 'BATTERY':
      return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border-yellow-200 dark:border-yellow-800'
    case 'SUSPENSION':
      return 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400 border-indigo-200 dark:border-indigo-800'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400 border-gray-200 dark:border-gray-800'
  }
}

function getStatusBadgeClasses(status: string): string {
  switch (status) {
    case 'COMPLETED':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800'
    case 'PENDING':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border-amber-200 dark:border-amber-800'
    case 'IN_PROGRESS':
      return 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-400 border-sky-200 dark:border-sky-800'
    case 'CANCELLED':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border-red-200 dark:border-red-800'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400 border-gray-200 dark:border-gray-800'
  }
}

function getPriorityBadgeClasses(priority: string): string {
  switch (priority) {
    case 'URGENT':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border-red-200 dark:border-red-800'
    case 'HIGH':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border-amber-200 dark:border-amber-800'
    case 'NORMAL':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800'
    case 'LOW':
      return 'bg-slate-100 text-slate-600 dark:bg-slate-900/30 dark:text-slate-400 border-slate-200 dark:border-slate-800'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400 border-gray-200 dark:border-gray-800'
  }
}

/* ─── Skeleton Components ─── */
function FilterBarSkeleton() {
  return (
    <div className="flex flex-wrap gap-3">
      {Array.from({ length: 4 }).map((_, i) => (
        <Skeleton key={i} className="h-9 w-40" />
      ))}
    </div>
  )
}

function TableSkeleton() {
  return (
    <Card>
      <CardContent className="p-0">
        <div className="p-4 space-y-3">
          <div className="flex gap-4">
            {Array.from({ length: 5 }).map((_, i) => (
              <Skeleton key={i} className="h-4 w-24" />
            ))}
          </div>
          <Separator />
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="flex gap-4 py-3">
              {Array.from({ length: 6 }).map((_, j) => (
                <Skeleton key={j} className="h-4 flex-1" />
              ))}
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}

function CardsSkeleton() {
  return (
    <div className="grid gap-3">
      {Array.from({ length: 5 }).map((_, i) => (
        <Card key={i}>
          <CardContent className="p-4">
            <div className="flex items-start justify-between">
              <div className="flex-1 space-y-2">
                <Skeleton className="h-5 w-40" />
                <Skeleton className="h-4 w-64" />
                <Skeleton className="h-4 w-32" />
              </div>
              <Skeleton className="h-9 w-20" />
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}

/* ─── Date Picker Component ─── */
function DatePickerField({
  value,
  onChange,
  placeholder = 'اختر التاريخ',
}: {
  value: Date | undefined
  onChange: (date: Date | undefined) => void
  placeholder?: string
}) {
  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          className="w-full justify-start text-right font-normal"
        >
          <CalendarIcon className="ml-2 h-4 w-4 text-muted-foreground" />
          {value ? format(value, 'yyyy/MM/dd', { locale: ar }) : placeholder}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto p-0" align="start">
        <Calendar
          mode="single"
          selected={value}
          onSelect={onChange}
          initialFocus
        />
      </PopoverContent>
    </Popover>
  )
}

/* ─── Main Component ─── */
export default function MaintenanceView() {
  const queryClient = useQueryClient()
  const {
    selectedVehicleId,
    setSelectedVehicleId,
    editingMaintenanceId,
    setEditingMaintenanceId,
    showMaintenanceDialog,
    setShowMaintenanceDialog,
  } = useAppStore()

  /* ── Filter States ─── */
  const [search, setSearch] = useState('')
  const [localVehicleId, setLocalVehicleId] = useState(selectedVehicleId ?? '')
  const [type, setType] = useState('')
  const [status, setStatus] = useState('')
  const [priority, setPriority] = useState('')
  const [startDate, setStartDate] = useState<Date | undefined>(undefined)
  const [endDate, setEndDate] = useState<Date | undefined>(undefined)
  const [page, setPage] = useState(1)
  const [filtersOpen, setFiltersOpen] = useState(false)
  const [deleteId, setDeleteId] = useState<string | null>(null)

  /* ── Derive effective vehicleId from store or local state ─── */
  const vehicleId = localVehicleId || selectedVehicleId || ''
  const setVehicleId = setLocalVehicleId

  /* ── Clear filters ─── */
  const clearFilters = useCallback(() => {
    setSearch('')
    setLocalVehicleId('')
    setType('')
    setStatus('')
    setPriority('')
    setStartDate(undefined)
    setEndDate(undefined)
    setPage(1)
    setSelectedVehicleId(null)
  }, [setSelectedVehicleId])

  /* ── Check if any filter is active ─── */
  const hasActiveFilters = useMemo(
    () => !!(search || vehicleId || type || status || priority || startDate || endDate),
    [search, vehicleId, type, status, priority, startDate, endDate]
  )

  /* ── Fetch maintenance records ─── */
  const { data, isLoading, isError } = useQuery<MaintenanceResponse>({
    queryKey: ['maintenance', search, vehicleId, type, status, priority, startDate?.toISOString(), endDate?.toISOString(), page],
    queryFn: () => {
      const params = new URLSearchParams()
      if (search) params.set('search', search)
      if (vehicleId) params.set('vehicleId', vehicleId)
      if (type) params.set('type', type)
      if (status) params.set('status', status)
      if (priority) params.set('priority', priority)
      if (startDate) params.set('startDate', startDate.toISOString())
      if (endDate) params.set('endDate', endDate.toISOString())
      params.set('page', page.toString())
      params.set('limit', '15')
      return fetch(`/api/maintenance?${params}`).then((r) => {
        if (!r.ok) throw new Error('Failed to fetch')
        return r.json()
      })
    },
  })

  /* ── Fetch vehicles for dropdown ─── */
  const { data: vehiclesData } = useQuery<{ vehicles: VehicleOption[] }>({
    queryKey: ['vehicles-list'],
    queryFn: () => fetch('/api/vehicles?limit=100').then((r) => r.json()),
  })

  const vehicles = vehiclesData?.vehicles ?? []

  /* ── Fetch single record for editing ─── */
  const { data: editingRecord } = useQuery<MaintenanceRecord>({
    queryKey: ['maintenance', editingMaintenanceId],
    queryFn: () =>
      fetch(`/api/maintenance/${editingMaintenanceId}`).then((r) => r.json()),
    enabled: !!editingMaintenanceId,
  })

  /* ── Form setup ─── */
  const form = useForm<MaintenanceFormData>({
    resolver: zodResolver(maintenanceFormSchema),
    defaultValues: {
      vehicleId: '',
      maintenanceDate: '',
      description: '',
      type: '',
      cost: 0,
      partsCost: '',
      laborCost: '',
      kilometerReading: '',
      serviceProvider: '',
      invoiceNumber: '',
      nextMaintenanceDate: '',
      nextMaintenanceKm: '',
      priority: 'NORMAL',
      status: 'COMPLETED',
      notes: '',
    },
  })

  /* ── Populate form when editing ─── */
  useEffect(() => {
    if (editingRecord && showMaintenanceDialog) {
      form.reset({
        vehicleId: editingRecord.vehicleId,
        maintenanceDate: editingRecord.maintenanceDate
          ? format(parseISO(editingRecord.maintenanceDate), 'yyyy-MM-dd')
          : '',
        description: editingRecord.description,
        type: editingRecord.type,
        cost: editingRecord.cost,
        partsCost: editingRecord.partsCost ?? '',
        laborCost: editingRecord.laborCost ?? '',
        kilometerReading: editingRecord.kilometerReading ?? '',
        serviceProvider: editingRecord.serviceProvider ?? '',
        invoiceNumber: editingRecord.invoiceNumber ?? '',
        nextMaintenanceDate: editingRecord.nextMaintenanceDate
          ? format(parseISO(editingRecord.nextMaintenanceDate), 'yyyy-MM-dd')
          : '',
        nextMaintenanceKm: editingRecord.nextMaintenanceKm ?? '',
        priority: editingRecord.priority,
        status: editingRecord.status,
        notes: editingRecord.notes ?? '',
      })
    }
  }, [editingRecord, showMaintenanceDialog, form])

  /* ── Reset form on dialog close ─── */
  useEffect(() => {
    if (!showMaintenanceDialog) {
      form.reset({
        vehicleId: vehicleId || selectedVehicleId || '',
        maintenanceDate: '',
        description: '',
        type: '',
        cost: 0,
        partsCost: '',
        laborCost: '',
        kilometerReading: '',
        serviceProvider: '',
        invoiceNumber: '',
        nextMaintenanceDate: '',
        nextMaintenanceKm: '',
        priority: 'NORMAL',
        status: 'COMPLETED',
        notes: '',
      })
      setEditingMaintenanceId(null)
    }
  }, [showMaintenanceDialog, form, vehicleId, selectedVehicleId, setEditingMaintenanceId])

  /* ── Create/Update mutation ─── */
  const saveMutation = useMutation({
    mutationFn: async (values: MaintenanceFormData) => {
      const payload: Record<string, unknown> = {
        vehicleId: values.vehicleId,
        maintenanceDate: values.maintenanceDate,
        description: values.description,
        type: values.type,
        cost: values.cost,
        priority: values.priority,
        status: values.status,
      }

      if (values.partsCost !== '' && values.partsCost !== undefined) payload.partsCost = Number(values.partsCost)
      if (values.laborCost !== '' && values.laborCost !== undefined) payload.laborCost = Number(values.laborCost)
      if (values.kilometerReading !== '' && values.kilometerReading !== undefined) payload.kilometerReading = Number(values.kilometerReading)
      if (values.serviceProvider) payload.serviceProvider = values.serviceProvider
      if (values.invoiceNumber) payload.invoiceNumber = values.invoiceNumber
      if (values.nextMaintenanceDate) payload.nextMaintenanceDate = values.nextMaintenanceDate
      if (values.nextMaintenanceKm !== '' && values.nextMaintenanceKm !== undefined) payload.nextMaintenanceKm = Number(values.nextMaintenanceKm)
      if (values.notes) payload.notes = values.notes

      if (editingMaintenanceId) {
        const res = await fetch(`/api/maintenance/${editingMaintenanceId}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        })
        if (!res.ok) {
          const err = await res.json()
          throw new Error(err.error || 'حدث خطأ أثناء التحديث')
        }
        return res.json()
      } else {
        const res = await fetch('/api/maintenance', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        })
        if (!res.ok) {
          const err = await res.json()
          throw new Error(err.error || 'حدث خطأ أثناء الإنشاء')
        }
        return res.json()
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] })
      setShowMaintenanceDialog(false)
      toast({
        title: editingMaintenanceId ? 'تم التحديث بنجاح' : 'تم الإنشاء بنجاح',
        description: editingMaintenanceId
          ? 'تم تحديث سجل الصيانة بنجاح'
          : 'تم إضافة سجل صيانة جديد بنجاح',
      })
    },
    onError: (error: Error) => {
      toast({
        title: 'حدث خطأ',
        description: error.message,
        variant: 'destructive',
      })
    },
  })

  /* ── Delete mutation ─── */
  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const res = await fetch(`/api/maintenance/${id}`, { method: 'DELETE' })
      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.error || 'حدث خطأ أثناء الحذف')
      }
      return res.json()
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] })
      setDeleteId(null)
      toast({
        title: 'تم الحذف بنجاح',
        description: 'تم حذف سجل الصيانة بنجاح',
      })
    },
    onError: (error: Error) => {
      toast({
        title: 'حدث خطأ',
        description: error.message,
        variant: 'destructive',
      })
    },
  })

  /* ── Handlers ─── */
  const handleOpenAdd = () => {
    setEditingMaintenanceId(null)
    form.reset({
      vehicleId: vehicleId || selectedVehicleId || '',
      maintenanceDate: format(new Date(), 'yyyy-MM-dd'),
      description: '',
      type: '',
      cost: 0,
      partsCost: '',
      laborCost: '',
      kilometerReading: '',
      serviceProvider: '',
      invoiceNumber: '',
      nextMaintenanceDate: '',
      nextMaintenanceKm: '',
      priority: 'NORMAL',
      status: 'COMPLETED',
      notes: '',
    })
    setShowMaintenanceDialog(true)
  }

  const handleOpenEdit = (id: string) => {
    setEditingMaintenanceId(id)
    setShowMaintenanceDialog(true)
  }

  const handleOpenDelete = (id: string) => {
    setDeleteId(id)
  }

  const handleBackToAll = () => {
    setSelectedVehicleId(null)
    setLocalVehicleId('')
  }

  /* ── Loading State ─── */
  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-10 w-44" />
        </div>
        <FilterBarSkeleton />
        <div className="hidden md:block">
          <TableSkeleton />
        </div>
        <div className="md:hidden">
          <CardsSkeleton />
        </div>
      </div>
    )
  }

  /* ── Error State ─── */
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

  const records = data?.records ?? []
  const totalPages = data?.pages ?? 1
  const total = data?.total ?? 0

  return (
    <div className="space-y-4">
      {/* ── Page Header ── */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 flex items-center justify-center shrink-0">
            <Wrench className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
          </div>
          <div>
            <h1 className="text-xl font-bold">سجلات الصيانة</h1>
            <p className="text-sm text-muted-foreground">
              إدارة وتتبع سجلات صيانة الأسطول
            </p>
          </div>
        </div>
        <Button onClick={handleOpenAdd} className="gap-2 bg-emerald-600 hover:bg-emerald-700 text-white">
          <Plus className="w-4 h-4" />
          إضافة سجل صيانة
        </Button>
      </div>

      {/* ── Back to All button (when filtered from vehicles view) ── */}
      {selectedVehicleId && (
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleBackToAll}
            className="gap-2 text-emerald-600 border-emerald-300 hover:bg-emerald-50 dark:border-emerald-800 dark:text-emerald-400 dark:hover:bg-emerald-950/30"
          >
            <ArrowRight className="w-4 h-4" />
            العودة لجميع السجلات
          </Button>
          <span className="text-sm text-muted-foreground">
            عرض سجلات سيارة محددة
          </span>
        </div>
      )}

      {/* ── Filters Bar ── */}
      <Card>
        <CardContent className="p-4">
          {/* Desktop filters - always visible */}
          <div className="hidden md:block">
            <div className="flex flex-wrap items-end gap-3">
              {/* Search */}
              <div className="w-64">
                <Label className="text-xs text-muted-foreground mb-1.5 block">بحث</Label>
                <div className="relative">
                  <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="وصف، مقدم خدمة، رقم فاتورة..."
                    value={search}
                    onChange={(e) => { setSearch(e.target.value); setPage(1) }}
                    className="pr-9 h-9"
                  />
                </div>
              </div>

              {/* Vehicle */}
              <div className="w-48">
                <Label className="text-xs text-muted-foreground mb-1.5 block">السيارة</Label>
                <Select value={vehicleId} onValueChange={(v) => { setVehicleId(v === 'all' ? '' : v); setPage(1) }}>
                  <SelectTrigger className="h-9 w-full">
                    <SelectValue placeholder="جميع السيارات" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">جميع السيارات</SelectItem>
                    {vehicles.map((v) => (
                      <SelectItem key={v.id} value={v.id}>
                        {v.plateNumber} - {v.make} {v.model}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Type */}
              <div className="w-44">
                <Label className="text-xs text-muted-foreground mb-1.5 block">نوع الصيانة</Label>
                <Select value={type} onValueChange={(v) => { setType(v === 'all' ? '' : v); setPage(1) }}>
                  <SelectTrigger className="h-9 w-full">
                    <SelectValue placeholder="الكل" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">الكل</SelectItem>
                    {MAINTENANCE_TYPES.map((t) => (
                      <SelectItem key={t.value} value={t.value}>
                        {t.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Status */}
              <div className="w-40">
                <Label className="text-xs text-muted-foreground mb-1.5 block">الحالة</Label>
                <Select value={status} onValueChange={(v) => { setStatus(v === 'all' ? '' : v); setPage(1) }}>
                  <SelectTrigger className="h-9 w-full">
                    <SelectValue placeholder="الكل" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">الكل</SelectItem>
                    {MAINTENANCE_STATUSES.map((s) => (
                      <SelectItem key={s.value} value={s.value}>
                        {s.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Priority */}
              <div className="w-40">
                <Label className="text-xs text-muted-foreground mb-1.5 block">الأولوية</Label>
                <Select value={priority} onValueChange={(v) => { setPriority(v === 'all' ? '' : v); setPage(1) }}>
                  <SelectTrigger className="h-9 w-full">
                    <SelectValue placeholder="الكل" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">الكل</SelectItem>
                    {PRIORITIES.map((p) => (
                      <SelectItem key={p.value} value={p.value}>
                        {p.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Date range */}
              <div className="w-40">
                <Label className="text-xs text-muted-foreground mb-1.5 block">من تاريخ</Label>
                <DatePickerField
                  value={startDate}
                  onChange={(d) => { setStartDate(d); setPage(1) }}
                  placeholder="من تاريخ"
                />
              </div>
              <div className="w-40">
                <Label className="text-xs text-muted-foreground mb-1.5 block">إلى تاريخ</Label>
                <DatePickerField
                  value={endDate}
                  onChange={(d) => { setEndDate(d); setPage(1) }}
                  placeholder="إلى تاريخ"
                />
              </div>

              {/* Clear button */}
              {hasActiveFilters && (
                <Button variant="ghost" size="sm" onClick={clearFilters} className="gap-1 text-muted-foreground hover:text-foreground h-9">
                  <X className="w-3.5 h-3.5" />
                  مسح الفلاتر
                </Button>
              )}
            </div>
          </div>

          {/* Mobile filters - collapsible */}
          <div className="md:hidden">
            <Collapsible open={filtersOpen} onOpenChange={setFiltersOpen}>
              <CollapsibleTrigger asChild>
                <Button
                  variant="outline"
                  size="sm"
                  className="w-full justify-between gap-2"
                >
                  <div className="flex items-center gap-2">
                    <Filter className="w-4 h-4" />
                    <span>الفلاتر</span>
                    {hasActiveFilters && (
                      <Badge variant="secondary" className="h-5 px-1.5 text-xs bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                        فعال
                      </Badge>
                    )}
                  </div>
                  <ChevronLeft className={cn('w-4 h-4 transition-transform', filtersOpen && 'rotate-90')} />
                </Button>
              </CollapsibleTrigger>
              <CollapsibleContent className="mt-3 space-y-3">
                <div className="relative">
                  <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="بحث..."
                    value={search}
                    onChange={(e) => { setSearch(e.target.value); setPage(1) }}
                    className="pr-9 h-9"
                  />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <Select value={vehicleId} onValueChange={(v) => { setVehicleId(v === 'all' ? '' : v); setPage(1) }}>
                    <SelectTrigger className="h-9 w-full">
                      <SelectValue placeholder="السيارة" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">الكل</SelectItem>
                      {vehicles.map((v) => (
                        <SelectItem key={v.id} value={v.id}>
                          {v.plateNumber}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Select value={type} onValueChange={(v) => { setType(v === 'all' ? '' : v); setPage(1) }}>
                    <SelectTrigger className="h-9 w-full">
                      <SelectValue placeholder="النوع" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">الكل</SelectItem>
                      {MAINTENANCE_TYPES.map((t) => (
                        <SelectItem key={t.value} value={t.value}>
                          {t.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Select value={status} onValueChange={(v) => { setStatus(v === 'all' ? '' : v); setPage(1) }}>
                    <SelectTrigger className="h-9 w-full">
                      <SelectValue placeholder="الحالة" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">الكل</SelectItem>
                      {MAINTENANCE_STATUSES.map((s) => (
                        <SelectItem key={s.value} value={s.value}>
                          {s.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Select value={priority} onValueChange={(v) => { setPriority(v === 'all' ? '' : v); setPage(1) }}>
                    <SelectTrigger className="h-9 w-full">
                      <SelectValue placeholder="الأولوية" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">الكل</SelectItem>
                      {PRIORITIES.map((p) => (
                        <SelectItem key={p.value} value={p.value}>
                          {p.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <DatePickerField
                    value={startDate}
                    onChange={(d) => { setStartDate(d); setPage(1) }}
                    placeholder="من تاريخ"
                  />
                  <DatePickerField
                    value={endDate}
                    onChange={(d) => { setEndDate(d); setPage(1) }}
                    placeholder="إلى تاريخ"
                  />
                </div>
                {hasActiveFilters && (
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={clearFilters}
                    className="w-full gap-1 text-muted-foreground hover:text-foreground"
                  >
                    <X className="w-3.5 h-3.5" />
                    مسح الفلاتر
                  </Button>
                )}
              </CollapsibleContent>
            </Collapsible>
          </div>

          {/* Results count */}
          <div className="mt-3 pt-3 border-t">
            <p className="text-xs text-muted-foreground">
              {total > 0 ? (
                <>عرض <span className="font-semibold text-foreground">{records.length}</span> من <span className="font-semibold text-foreground">{formatNumber(total)}</span> سجل</>
              ) : (
                'لا توجد سجلات مطابقة'
              )}
            </p>
          </div>
        </CardContent>
      </Card>

      {/* ── Desktop Table ── */}
      {records.length > 0 && (
        <div className="hidden md:block">
          <Card>
            <CardContent className="p-0">
              <ScrollArea className="max-h-[calc(100vh-420px)]">
                <Table>
                  <TableHeader>
                    <TableRow className="hover:bg-transparent">
                      <TableHead className="text-right whitespace-nowrap py-3 px-4">التاريخ</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4">السيارة</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4">نوع الصيانة</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4 min-w-[180px]">البيان</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4">التكلفة</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4">العداد</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4 min-w-[140px]">مقدم الخدمة</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4">الأولوية</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4">الحالة</TableHead>
                      <TableHead className="text-right whitespace-nowrap py-3 px-4">الإجراءات</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {records.map((record) => (
                      <TableRow key={record.id} className="group">
                        <TableCell className="text-right py-3 px-4 whitespace-nowrap text-sm">
                          {formatDate(record.maintenanceDate)}
                        </TableCell>
                        <TableCell className="text-right py-3 px-4 whitespace-nowrap">
                          <div>
                            <p className="text-sm font-medium">{record.vehicle.plateNumber}</p>
                            <p className="text-xs text-muted-foreground">
                              {record.vehicle.make} {record.vehicle.model}
                            </p>
                          </div>
                        </TableCell>
                        <TableCell className="text-right py-3 px-4">
                          <Badge
                            variant="outline"
                            className={cn('text-xs font-medium border', getTypeBadgeClasses(record.type))}
                          >
                            {getMaintenanceTypeLabel(record.type)}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right py-3 px-4">
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <p className="text-sm truncate max-w-[180px] cursor-default">
                                {record.description}
                              </p>
                            </TooltipTrigger>
                            <TooltipContent side="top" className="max-w-xs">
                              <p className="text-xs">{record.description}</p>
                            </TooltipContent>
                          </Tooltip>
                        </TableCell>
                        <TableCell className="text-right py-3 px-4 whitespace-nowrap">
                          <span className="text-sm font-semibold">
                            {formatCurrency(record.cost)}
                          </span>
                        </TableCell>
                        <TableCell className="text-right py-3 px-4 whitespace-nowrap text-sm text-muted-foreground">
                          {record.kilometerReading ? formatNumber(record.kilometerReading) : '—'}
                        </TableCell>
                        <TableCell className="text-right py-3 px-4">
                          <span className="text-sm truncate max-w-[130px] block">
                            {record.serviceProvider || '—'}
                          </span>
                        </TableCell>
                        <TableCell className="text-right py-3 px-4">
                          <Badge
                            variant="outline"
                            className={cn('text-xs font-medium border', getPriorityBadgeClasses(record.priority))}
                          >
                            {getPriorityLabel(record.priority)}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right py-3 px-4">
                          <Badge
                            variant="outline"
                            className={cn('text-xs font-medium border', getStatusBadgeClasses(record.status))}
                          >
                            {getMaintenanceStatusLabel(record.status)}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right py-3 px-4">
                          <div className="flex items-center gap-1">
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 text-muted-foreground hover:text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-950/30"
                              onClick={() => handleOpenEdit(record.id)}
                            >
                              <Pencil className="w-4 h-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 text-muted-foreground hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/30"
                              onClick={() => handleOpenDelete(record.id)}
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </ScrollArea>
            </CardContent>
          </Card>
        </div>
      )}

      {/* ── Mobile Cards ── */}
      {records.length > 0 && (
        <div className="md:hidden space-y-3">
          {records.map((record) => (
            <Card key={record.id} className="overflow-hidden">
              <CardContent className="p-4 space-y-3">
                {/* Header row */}
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 flex items-center justify-center shrink-0">
                      <Car className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-sm font-semibold truncate">
                        {record.vehicle.plateNumber}
                      </p>
                      <p className="text-xs text-muted-foreground truncate">
                        {record.vehicle.make} {record.vehicle.model}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-1 shrink-0">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-muted-foreground hover:text-emerald-600"
                      onClick={() => handleOpenEdit(record.id)}
                    >
                      <Pencil className="w-3.5 h-3.5" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-muted-foreground hover:text-red-600"
                      onClick={() => handleOpenDelete(record.id)}
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </Button>
                  </div>
                </div>

                {/* Description */}
                <p className="text-sm text-foreground/80 line-clamp-2">
                  {record.description}
                </p>

                {/* Badges row */}
                <div className="flex items-center gap-2 flex-wrap">
                  <Badge
                    variant="outline"
                    className={cn('text-xs font-medium border', getTypeBadgeClasses(record.type))}
                  >
                    {getMaintenanceTypeLabel(record.type)}
                  </Badge>
                  <Badge
                    variant="outline"
                    className={cn('text-xs font-medium border', getStatusBadgeClasses(record.status))}
                  >
                    {getMaintenanceStatusLabel(record.status)}
                  </Badge>
                  <Badge
                    variant="outline"
                    className={cn('text-xs font-medium border', getPriorityBadgeClasses(record.priority))}
                  >
                    {getPriorityLabel(record.priority)}
                  </Badge>
                </div>

                {/* Footer info */}
                <div className="flex items-center justify-between pt-2 border-t">
                  <div className="text-xs text-muted-foreground space-y-0.5">
                    <div className="flex items-center gap-1">
                      <CalendarIcon className="w-3 h-3" />
                      {formatDate(record.maintenanceDate)}
                    </div>
                    {record.serviceProvider && (
                      <p className="truncate max-w-[200px]">{record.serviceProvider}</p>
                    )}
                  </div>
                  <span className="text-sm font-bold text-emerald-600 dark:text-emerald-400">
                    {formatCurrency(record.cost)}
                  </span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* ── Empty State ── */}
      {records.length === 0 && !isLoading && (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <div className="w-16 h-16 rounded-2xl bg-emerald-50 dark:bg-emerald-950/50 flex items-center justify-center mb-4">
              <Wrench className="w-8 h-8 text-emerald-600 dark:text-emerald-400 opacity-60" />
            </div>
            <h3 className="text-lg font-semibold mb-2">
              {hasActiveFilters ? 'لا توجد نتائج مطابقة' : 'لا توجد سجلات صيانة'}
            </h3>
            <p className="text-muted-foreground text-sm max-w-md mb-4">
              {hasActiveFilters
                ? 'جرب تعديل معايير البحث أو مسح الفلاتر'
                : 'ابدأ بإضافة سجل صيانة جديد لتتبع أعمال صيانة الأسطول'}
            </p>
            {hasActiveFilters ? (
              <Button variant="outline" onClick={clearFilters} className="gap-2">
                <X className="w-4 h-4" />
                مسح الفلاتر
              </Button>
            ) : (
              <Button onClick={handleOpenAdd} className="gap-2 bg-emerald-600 hover:bg-emerald-700 text-white">
                <Plus className="w-4 h-4" />
                إضافة سجل صيانة
              </Button>
            )}
          </CardContent>
        </Card>
      )}

      {/* ── Pagination ── */}
      {totalPages > 1 && (
        <Card>
          <CardContent className="p-3">
            <div className="flex items-center justify-between gap-2">
              <p className="text-xs text-muted-foreground">
                صفحة {page} من {totalPages}
              </p>
              <div className="flex items-center gap-1">
                <Button
                  variant="outline"
                  size="icon"
                  className="h-8 w-8"
                  disabled={page <= 1}
                  onClick={() => setPage(1)}
                >
                  <ChevronsRight className="w-4 h-4" />
                </Button>
                <Button
                  variant="outline"
                  size="icon"
                  className="h-8 w-8"
                  disabled={page <= 1}
                  onClick={() => setPage((p) => p - 1)}
                >
                  <ChevronRight className="w-4 h-4" />
                </Button>

                {/* Page numbers */}
                <div className="hidden sm:flex items-center gap-1">
                  {Array.from({ length: totalPages }, (_, i) => i + 1)
                    .filter((p) => {
                      if (totalPages <= 7) return true
                      if (p === 1 || p === totalPages) return true
                      if (Math.abs(p - page) <= 1) return true
                      return false
                    })
                    .map((p, idx, arr) => {
                      const prev = arr[idx - 1]
                      const showEllipsis = prev !== undefined && p - prev > 1
                      return (
                        <span key={p} className="flex items-center">
                          {showEllipsis && (
                            <span className="px-1 text-xs text-muted-foreground">...</span>
                          )}
                          <Button
                            variant={page === p ? 'default' : 'outline'}
                            size="icon"
                            className={cn('h-8 w-8 text-xs', page === p && 'bg-emerald-600 hover:bg-emerald-700 text-white')}
                            onClick={() => setPage(p)}
                          >
                            {p}
                          </Button>
                        </span>
                      )
                    })}
                </div>

                <Button
                  variant="outline"
                  size="icon"
                  className="h-8 w-8"
                  disabled={page >= totalPages}
                  onClick={() => setPage((p) => p + 1)}
                >
                  <ChevronLeft className="w-4 h-4" />
                </Button>
                <Button
                  variant="outline"
                  size="icon"
                  className="h-8 w-8"
                  disabled={page >= totalPages}
                  onClick={() => setPage(totalPages)}
                >
                  <ChevronsLeft className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* ── Add/Edit Dialog ── */}
      <Dialog open={showMaintenanceDialog} onOpenChange={setShowMaintenanceDialog}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              {editingMaintenanceId ? 'تعديل سجل الصيانة' : 'إضافة سجل صيانة جديد'}
            </DialogTitle>
            <DialogDescription>
              {editingMaintenanceId
                ? 'قم بتعديل بيانات سجل الصيانة'
                : 'أدخل بيانات سجل الصيانة الجديد'}
            </DialogDescription>
          </DialogHeader>

          <ScrollArea className="flex-1 max-h-[calc(90vh-180px)] -mx-6 px-6">
            <Form {...form}>
              <form id="maintenance-form" className="space-y-4 py-2">
                {/* Row 1: Vehicle + Date */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="vehicleId"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>السيارة <span className="text-destructive">*</span></FormLabel>
                        <Select value={field.value} onValueChange={field.onChange}>
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="اختر السيارة" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {vehicles.map((v) => (
                              <SelectItem key={v.id} value={v.id}>
                                {v.plateNumber} - {v.make} {v.model}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="maintenanceDate"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>تاريخ الصيانة <span className="text-destructive">*</span></FormLabel>
                        <Popover>
                          <PopoverTrigger asChild>
                            <FormControl>
                              <Button
                                type="button"
                                variant="outline"
                                className="w-full justify-start text-right font-normal"
                              >
                                <CalendarIcon className="ml-2 h-4 w-4 text-muted-foreground" />
                                {field.value
                                  ? format(parseISO(field.value), 'yyyy/MM/dd', { locale: ar })
                                  : 'اختر التاريخ'}
                              </Button>
                            </FormControl>
                          </PopoverTrigger>
                          <PopoverContent className="w-auto p-0" align="start">
                            <Calendar
                              mode="single"
                              selected={field.value ? parseISO(field.value) : undefined}
                              onSelect={(d) => field.onChange(d ? format(d, 'yyyy-MM-dd') : '')}
                              initialFocus
                            />
                          </PopoverContent>
                        </Popover>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>

                {/* Row 2: Type + Status */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="type"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>نوع الصيانة <span className="text-destructive">*</span></FormLabel>
                        <Select value={field.value} onValueChange={field.onChange}>
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="اختر النوع" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {MAINTENANCE_TYPES.map((t) => (
                              <SelectItem key={t.value} value={t.value}>
                                {t.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="status"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>الحالة <span className="text-destructive">*</span></FormLabel>
                        <Select value={field.value} onValueChange={field.onChange}>
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="اختر الحالة" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {MAINTENANCE_STATUSES.map((s) => (
                              <SelectItem key={s.value} value={s.value}>
                                {s.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>

                {/* Row 3: Description */}
                <FormField
                  control={form.control}
                  name="description"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>البيان <span className="text-destructive">*</span></FormLabel>
                      <FormControl>
                        <Textarea
                          placeholder="وصف تفصيلي لأعمال الصيانة..."
                          className="min-h-[80px]"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                {/* Row 4: Cost + Parts + Labor */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <FormField
                    control={form.control}
                    name="cost"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>التكلفة الإجمالية <span className="text-destructive">*</span></FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            step="0.01"
                            min="0"
                            placeholder="0.00"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="partsCost"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>تكلفة القطع</FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            step="0.01"
                            min="0"
                            placeholder="0.00"
                            value={field.value}
                            onChange={field.onChange}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="laborCost"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>تكلفة العمالة</FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            step="0.01"
                            min="0"
                            placeholder="0.00"
                            value={field.value}
                            onChange={field.onChange}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>

                {/* Row 5: KM + Service Provider + Invoice */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <FormField
                    control={form.control}
                    name="kilometerReading"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>عداد الكيلومتر</FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            step="1"
                            min="0"
                            placeholder="0"
                            value={field.value}
                            onChange={field.onChange}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="serviceProvider"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>مقدم الخدمة</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="اسم الورشة أو المركز"
                            value={field.value}
                            onChange={field.onChange}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="invoiceNumber"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>رقم الفاتورة</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="رقم الفاتورة"
                            value={field.value}
                            onChange={field.onChange}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>

                {/* Row 6: Next maintenance date + Next KM */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="nextMaintenanceDate"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>تاريخ الصيانة القادمة</FormLabel>
                        <Popover>
                          <PopoverTrigger asChild>
                            <FormControl>
                              <Button
                                type="button"
                                variant="outline"
                                className="w-full justify-start text-right font-normal"
                              >
                                <CalendarIcon className="ml-2 h-4 w-4 text-muted-foreground" />
                                {field.value
                                  ? format(parseISO(field.value), 'yyyy/MM/dd', { locale: ar })
                                  : 'اختر التاريخ'}
                              </Button>
                            </FormControl>
                          </PopoverTrigger>
                          <PopoverContent className="w-auto p-0" align="start">
                            <Calendar
                              mode="single"
                              selected={field.value ? parseISO(field.value) : undefined}
                              onSelect={(d) => field.onChange(d ? format(d, 'yyyy-MM-dd') : '')}
                              initialFocus
                            />
                          </PopoverContent>
                        </Popover>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="nextMaintenanceKm"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>الكيلومتر القادم للصيانة</FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            step="1"
                            min="0"
                            placeholder="0"
                            value={field.value}
                            onChange={field.onChange}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>

                {/* Row 7: Priority */}
                <FormField
                  control={form.control}
                  name="priority"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>الأولوية <span className="text-destructive">*</span></FormLabel>
                      <Select value={field.value} onValueChange={field.onChange}>
                        <FormControl>
                          <SelectTrigger className="w-full sm:w-1/2">
                            <SelectValue placeholder="اختر الأولوية" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {PRIORITIES.map((p) => (
                            <SelectItem key={p.value} value={p.value}>
                              {p.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                {/* Row 8: Notes */}
                <FormField
                  control={form.control}
                  name="notes"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>ملاحظات</FormLabel>
                      <FormControl>
                        <Textarea
                          placeholder="ملاحظات إضافية..."
                          className="min-h-[60px]"
                          value={field.value}
                          onChange={field.onChange}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </form>
            </Form>
          </ScrollArea>

          <DialogFooter className="pt-2 border-t mt-2 gap-2">
            <Button
              variant="outline"
              onClick={() => setShowMaintenanceDialog(false)}
              disabled={saveMutation.isPending}
            >
              إلغاء
            </Button>
            <Button
              type="submit"
              form="maintenance-form"
              onClick={form.handleSubmit((data) => saveMutation.mutate(data))}
              disabled={saveMutation.isPending}
              className="bg-emerald-600 hover:bg-emerald-700 text-white gap-2"
            >
              {saveMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
              {editingMaintenanceId ? 'حفظ التعديلات' : 'إضافة السجل'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ── Delete Confirmation Dialog ── */}
      <AlertDialog open={!!deleteId} onOpenChange={(open) => { if (!open) setDeleteId(null) }}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <div className="w-10 h-10 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center shrink-0">
                <Trash2 className="w-5 h-5 text-red-600 dark:text-red-400" />
              </div>
              تأكيد الحذف
            </AlertDialogTitle>
            <AlertDialogDescription className="text-right pt-2">
              هل أنت متأكد من حذف سجل الصيانة هذا؟ لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter className="gap-2 sm:gap-0">
            <AlertDialogCancel disabled={deleteMutation.isPending}>
              إلغاء
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={() => { if (deleteId) deleteMutation.mutate(deleteId) }}
              disabled={deleteMutation.isPending}
              className="bg-red-600 hover:bg-red-700 text-white gap-2"
            >
              {deleteMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
