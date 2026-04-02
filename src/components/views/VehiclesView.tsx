'use client'

import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useAppStore } from '@/lib/store'
import { toast } from 'sonner'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  Plus,
  Search,
  Pencil,
  Trash2,
  Wrench,
  Car,
  Phone,
  User,
  Fuel,
  Building2,
  AlertTriangle,
  ChevronLeft,
  ChevronRight,
  Filter,
  X,
  Hash,
  Palette,
  Calendar,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { Card, CardContent } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'
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
  VEHICLE_STATUSES,
  FUEL_TYPES,
  VEHICLE_MAKES,
  getVehicleStatusLabel,
  formatDate,
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
  _count: {
    maintenanceRecords: number
  }
}

interface VehiclesResponse {
  vehicles: Vehicle[]
  total: number
  pages: number
  page: number
  limit: number
}

/* ─── Zod Schema ─── */
const vehicleFormSchema = z.object({
  plateNumber: z.string().min(1, 'رقم اللوحة مطلوب'),
  make: z.string().min(1, 'الماركة مطلوبة'),
  model: z.string().min(1, 'الموديل مطلوب'),
  year: z
    .number({ invalid_type_error: 'السنة يجب أن تكون رقماً' })
    .min(2000, 'السنة يجب أن تكون 2000 أو أكثر')
    .max(2026, 'السنة يجب أن تكون 2026 أو أقل'),
  color: z.string().optional().default(''),
  vin: z.string().optional().default(''),
  status: z.string().default('ACTIVE'),
  department: z.string().optional().default(''),
  driverName: z.string().optional().default(''),
  driverPhone: z.string().optional().default(''),
  fuelType: z.string().optional().default(''),
  notes: z.string().optional().default(''),
})

type VehicleFormValues = z.infer<typeof vehicleFormSchema>

/* ─── Status Color Mapping ─── */
function getStatusClasses(status: string): string {
  switch (status) {
    case 'ACTIVE':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800'
    case 'MAINTENANCE':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border-amber-200 dark:border-amber-800'
    case 'OUT_OF_SERVICE':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border-red-200 dark:border-red-800'
    case 'SOLD':
      return 'bg-gray-100 text-gray-600 dark:bg-gray-900/30 dark:text-gray-400 border-gray-200 dark:border-gray-800'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400 border-gray-200 dark:border-gray-800'
  }
}

function getStatusDotColor(status: string): string {
  switch (status) {
    case 'ACTIVE':
      return 'bg-emerald-500'
    case 'MAINTENANCE':
      return 'bg-amber-500'
    case 'OUT_OF_SERVICE':
      return 'bg-red-500'
    case 'SOLD':
      return 'bg-gray-400'
    default:
      return 'bg-gray-400'
  }
}

function getFuelLabel(value: string): string {
  return FUEL_TYPES.find(f => f.value === value)?.label || value
}

function getFuelClasses(value: string): string {
  switch (value) {
    case 'PETROL':
      return 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400'
    case 'DIESEL':
      return 'bg-slate-100 text-slate-700 dark:bg-slate-900/30 dark:text-slate-400'
    case 'ELECTRIC':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
    case 'HYBRID':
      return 'bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-400'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

/* ─── Card Skeleton ─── */
function VehicleCardSkeleton() {
  return (
    <Card>
      <CardContent className="p-5">
        <div className="flex items-start justify-between mb-4">
          <div className="space-y-2">
            <Skeleton className="h-7 w-28" />
            <Skeleton className="h-4 w-36" />
          </div>
          <Skeleton className="h-6 w-20 rounded-full" />
        </div>
        <Separator className="mb-4" />
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Skeleton className="w-4 h-4 rounded-full" />
            <Skeleton className="h-4 w-28" />
          </div>
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-4 w-24" />
          <div className="flex gap-2 mt-2">
            <Skeleton className="h-5 w-14 rounded-full" />
            <Skeleton className="h-5 w-16 rounded-full" />
          </div>
        </div>
        <Separator className="my-4" />
        <div className="flex items-center justify-between">
          <Skeleton className="h-4 w-28" />
          <div className="flex gap-1">
            <Skeleton className="w-8 h-8 rounded-md" />
            <Skeleton className="w-8 h-8 rounded-md" />
            <Skeleton className="w-8 h-8 rounded-md" />
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

/* ─── Vehicle Card ─── */
function VehicleCard({
  vehicle,
  onEdit,
  onDelete,
  onViewMaintenance,
}: {
  vehicle: Vehicle
  onEdit: (v: Vehicle) => void
  onDelete: (v: Vehicle) => void
  onViewMaintenance: (id: string) => void
}) {
  return (
    <Card className="group hover:shadow-lg hover:scale-[1.02] transition-all duration-200 border-border/50">
      <CardContent className="p-5">
        {/* Header: Plate + Status */}
        <div className="flex items-start justify-between mb-3">
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <Hash className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
              <h3 className="text-lg font-bold text-foreground truncate tracking-tight">
                {vehicle.plateNumber}
              </h3>
            </div>
            <p className="text-sm text-muted-foreground mt-0.5 truncate">
              {vehicle.make} {vehicle.model} • {vehicle.year}
            </p>
          </div>
          <Badge
            variant="outline"
            className={`shrink-0 text-xs ${getStatusClasses(vehicle.status)}`}
          >
            <span className={`w-1.5 h-1.5 rounded-full ${getStatusDotColor(vehicle.status)} inline-block ml-1.5`} />
            {getVehicleStatusLabel(vehicle.status)}
          </Badge>
        </div>

        <Separator />

        {/* Details */}
        <div className="space-y-2.5 mt-3.5">
          {/* Color + Driver */}
          <div className="flex items-center gap-2">
            {vehicle.color && (
              <div className="flex items-center gap-1.5">
                <span
                  className="w-3.5 h-3.5 rounded-full border border-gray-300 dark:border-gray-600 shrink-0"
                  style={{ backgroundColor: vehicle.color }}
                  title={vehicle.color}
                />
                <span className="text-xs text-muted-foreground">{vehicle.color}</span>
              </div>
            )}
            {vehicle.color && vehicle.driverName && (
              <span className="text-muted-foreground text-xs">•</span>
            )}
            {vehicle.driverName && (
              <div className="flex items-center gap-1 min-w-0">
                <User className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
                <span className="text-xs text-muted-foreground truncate">
                  {vehicle.driverName}
                </span>
              </div>
            )}
          </div>

          {/* Driver Phone */}
          {vehicle.driverPhone && (
            <div className="flex items-center gap-1.5">
              <Phone className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
              <span className="text-xs text-muted-foreground" dir="ltr">
                {vehicle.driverPhone}
              </span>
            </div>
          )}

          {/* Department */}
          {vehicle.department && (
            <div className="flex items-center gap-1.5">
              <Building2 className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
              <span className="text-xs text-muted-foreground truncate">
                {vehicle.department}
              </span>
            </div>
          )}

          {/* Badges Row */}
          <div className="flex items-center gap-2 flex-wrap mt-1">
            {vehicle.fuelType && (
              <Badge
                variant="secondary"
                className={`text-xs px-2 py-0 ${getFuelClasses(vehicle.fuelType)}`}
              >
                <Fuel className="w-3 h-3 ml-1" />
                {getFuelLabel(vehicle.fuelType)}
              </Badge>
            )}
            <Badge variant="secondary" className="text-xs px-2 py-0 bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400">
              <Wrench className="w-3 h-3 ml-1" />
              {vehicle._count.maintenanceRecords} صيانة
            </Badge>
          </div>
        </div>

        <Separator className="my-3.5" />

        {/* Footer: Last Maintenance + Actions */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <Calendar className="w-3.5 h-3.5" />
            <span className="truncate max-w-[140px]">
              {vehicle._count.maintenanceRecords > 0
                ? `آخر صيانة: ${vehicle.updatedAt !== vehicle.createdAt ? formatDate(vehicle.updatedAt) : 'حديثة'}`
                : 'لا توجد صيانة'}
            </span>
          </div>

          <div className="flex items-center gap-1">
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 dark:text-emerald-400 dark:hover:bg-emerald-950/50"
              onClick={() => onViewMaintenance(vehicle.id)}
              title="عرض الصيانة"
            >
              <Wrench className="w-4 h-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 text-amber-600 hover:text-amber-700 hover:bg-amber-50 dark:text-amber-400 dark:hover:bg-amber-950/50"
              onClick={() => onEdit(vehicle)}
              title="تعديل"
            >
              <Pencil className="w-4 h-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 text-red-500 hover:text-red-600 hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/50"
              onClick={() => onDelete(vehicle)}
              title="حذف"
            >
              <Trash2 className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

/* ─── Vehicle Form Dialog ─── */
function VehicleFormDialog({
  open,
  onOpenChange,
  editingVehicle,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  editingVehicle: Vehicle | null
}) {
  const queryClient = useQueryClient()
  const isEditing = !!editingVehicle

  const form = useForm<VehicleFormValues>({
    resolver: zodResolver(vehicleFormSchema),
    defaultValues: {
      plateNumber: '',
      make: '',
      model: '',
      year: new Date().getFullYear(),
      color: '',
      vin: '',
      status: 'ACTIVE',
      department: '',
      driverName: '',
      driverPhone: '',
      fuelType: '',
      notes: '',
    },
  })

  // Reset form when dialog opens with editing vehicle
  useEffect(() => {
    if (open) {
      if (editingVehicle) {
        form.reset({
          plateNumber: editingVehicle.plateNumber,
          make: editingVehicle.make,
          model: editingVehicle.model,
          year: editingVehicle.year,
          color: editingVehicle.color || '',
          vin: editingVehicle.vin || '',
          status: editingVehicle.status,
          department: editingVehicle.department || '',
          driverName: editingVehicle.driverName || '',
          driverPhone: editingVehicle.driverPhone || '',
          fuelType: editingVehicle.fuelType || '',
          notes: editingVehicle.notes || '',
        })
      } else {
        form.reset({
          plateNumber: '',
          make: '',
          model: '',
          year: new Date().getFullYear(),
          color: '',
          vin: '',
          status: 'ACTIVE',
          department: '',
          driverName: '',
          driverPhone: '',
          fuelType: '',
          notes: '',
        })
      }
    }
  }, [open, editingVehicle, form])

  const createMutation = useMutation({
    mutationFn: (data: VehicleFormValues) =>
      fetch('/api/vehicles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      }).then((r) => {
        if (!r.ok) return r.json().then((err) => { throw new Error(err.error || 'حدث خطأ') })
        return r.json()
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vehicles'] })
      onOpenChange(false)
      toast.success('تم إضافة السيارة بنجاح')
    },
    onError: (error: Error) => {
      toast.error(error.message || 'حدث خطأ أثناء إضافة السيارة')
    },
  })

  const updateMutation = useMutation({
    mutationFn: (data: VehicleFormValues) =>
      fetch(`/api/vehicles/${editingVehicle?.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      }).then((r) => {
        if (!r.ok) return r.json().then((err) => { throw new Error(err.error || 'حدث خطأ') })
        return r.json()
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vehicles'] })
      onOpenChange(false)
      toast.success('تم تحديث بيانات السيارة بنجاح')
    },
    onError: (error: Error) => {
      toast.error(error.message || 'حدث خطأ أثناء تحديث بيانات السيارة')
    },
  })

  const isSubmitting = createMutation.isPending || updateMutation.isPending

  function onSubmit(data: VehicleFormValues) {
    if (isEditing) {
      updateMutation.mutate(data)
    } else {
      createMutation.mutate(data)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl max-h-[90vh]">
        <DialogHeader>
          <DialogTitle className="text-right">
            {isEditing ? 'تعديل بيانات السيارة' : 'إضافة سيارة جديدة'}
          </DialogTitle>
          <DialogDescription className="text-right">
            {isEditing
              ? 'قم بتعديل بيانات السيارة المطلوبة'
              : 'أدخل بيانات السيارة الجديدة لإضافتها إلى الأسطول'}
          </DialogDescription>
        </DialogHeader>

        <ScrollArea className="max-h-[65vh] pl-1">
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-5 px-1 pb-2">
              {/* ── Basic Info ── */}
              <div className="space-y-1.5">
                <h4 className="text-sm font-semibold text-foreground flex items-center gap-2">
                  <Car className="w-4 h-4 text-emerald-600" />
                  معلومات أساسية
                </h4>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="plateNumber"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>رقم اللوحة *</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="مثال: أ ب ج 1234"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="make"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>الماركة *</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="مثال: تويوتا"
                            list="vehicle-makes"
                            {...field}
                          />
                        </FormControl>
                        <datalist id="vehicle-makes">
                          {VEHICLE_MAKES.map((make) => (
                            <option key={make} value={make} />
                          ))}
                        </datalist>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="model"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>الموديل *</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="مثال: كامري"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="year"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>سنة الصنع *</FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            placeholder="2024"
                            min={2000}
                            max={2026}
                            value={field.value}
                            onChange={(e) => field.onChange(e.target.value ? parseInt(e.target.value) : '')}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="color"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>
                          <span className="flex items-center gap-1.5">
                            <Palette className="w-3.5 h-3.5" />
                            اللون
                          </span>
                        </FormLabel>
                        <FormControl>
                          <Input
                            placeholder="مثال: أبيض"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="vin"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>رقم الشاصي (VIN)</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="رقم الهيكل"
                            dir="ltr"
                            className="text-left"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
              </div>

              <Separator />

              {/* ── Status & Operations ── */}
              <div className="space-y-1.5">
                <h4 className="text-sm font-semibold text-foreground flex items-center gap-2">
                  <Building2 className="w-4 h-4 text-emerald-600" />
                  الحالة والتشغيل
                </h4>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="status"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>الحالة</FormLabel>
                        <Select
                          value={field.value}
                          onValueChange={field.onChange}
                        >
                          <FormControl>
                            <SelectTrigger className="w-full">
                              <SelectValue placeholder="اختر الحالة" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {VEHICLE_STATUSES.map((s) => (
                              <SelectItem key={s.value} value={s.value}>
                                <span className="flex items-center gap-2">
                                  <span className={`w-2 h-2 rounded-full ${s.color}`} />
                                  {s.label}
                                </span>
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
                    name="fuelType"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>نوع الوقود</FormLabel>
                        <Select
                          value={field.value || ''}
                          onValueChange={field.onChange}
                        >
                          <FormControl>
                            <SelectTrigger className="w-full">
                              <SelectValue placeholder="اختر نوع الوقود" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {FUEL_TYPES.map((f) => (
                              <SelectItem key={f.value} value={f.value}>
                                {f.label}
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
                    name="department"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>القسم</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="مثال: قسم النقل"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
              </div>

              <Separator />

              {/* ── Driver Info ── */}
              <div className="space-y-1.5">
                <h4 className="text-sm font-semibold text-foreground flex items-center gap-2">
                  <User className="w-4 h-4 text-emerald-600" />
                  بيانات السائق
                </h4>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <FormField
                    control={form.control}
                    name="driverName"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>اسم السائق</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="اسم السائق"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="driverPhone"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>رقم هاتف السائق</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="رقم الهاتف"
                            dir="ltr"
                            className="text-left"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
              </div>

              <Separator />

              {/* ── Notes ── */}
              <FormField
                control={form.control}
                name="notes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>ملاحظات</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="أي ملاحظات إضافية..."
                        rows={3}
                        className="resize-none"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* ── Submit ── */}
              <DialogFooter className="pt-2 gap-2 sm:gap-0">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => onOpenChange(false)}
                  disabled={isSubmitting}
                >
                  إلغاء
                </Button>
                <Button
                  type="submit"
                  disabled={isSubmitting}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white min-w-[140px]"
                >
                  {isSubmitting ? (
                    <span className="flex items-center gap-2">
                      <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      جاري الحفظ...
                    </span>
                  ) : isEditing ? (
                    'حفظ التعديلات'
                  ) : (
                    <span className="flex items-center gap-1.5">
                      <Plus className="w-4 h-4" />
                      إضافة السيارة
                    </span>
                  )}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </ScrollArea>
      </DialogContent>
    </Dialog>
  )
}

/* ─── Delete Confirmation Dialog ─── */
function DeleteVehicleDialog({
  open,
  onOpenChange,
  vehicle,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  vehicle: Vehicle | null
}) {
  const queryClient = useQueryClient()

  const deleteMutation = useMutation({
    mutationFn: (id: string) =>
      fetch(`/api/vehicles/${id}`, { method: 'DELETE' }).then((r) => {
        if (!r.ok) return r.json().then((err) => { throw new Error(err.error || 'حدث خطأ') })
        return r.json()
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vehicles'] })
      onOpenChange(false)
      toast.success('تم حذف السيارة بنجاح')
    },
    onError: (error: Error) => {
      toast.error(error.message || 'حدث خطأ أثناء حذف السيارة')
    },
  })

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent className="sm:max-w-md">
        <AlertDialogHeader className="text-center sm:text-right">
          <div className="mx-auto sm:mx-0 w-14 h-14 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center mb-3">
            <Trash2 className="w-7 h-7 text-red-600 dark:text-red-400" />
          </div>
          <AlertDialogTitle className="text-right">
            تأكيد حذف السيارة
          </AlertDialogTitle>
          <AlertDialogDescription className="text-right leading-relaxed">
            هل أنت متأكد من حذف السيارة{' '}
            <span className="font-bold text-foreground">
              {vehicle?.plateNumber}
            </span>{' '}
            ({vehicle?.make} {vehicle?.model})؟
            {vehicle && vehicle._count.maintenanceRecords > 0 && (
              <span className="block mt-2 text-red-600 dark:text-red-400 font-medium">
                ⚠ تحذير: سيتم حذف جميع سجلات الصيانة المرتبطة بهذه السيارة ({vehicle._count.maintenanceRecords} سجل).
              </span>
            )}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter className="flex-col-reverse gap-2 sm:flex-row">
          <AlertDialogCancel disabled={deleteMutation.isPending}>
            إلغاء
          </AlertDialogCancel>
          <Button
            variant="destructive"
            onClick={() => vehicle && deleteMutation.mutate(vehicle.id)}
            disabled={deleteMutation.isPending}
            className="min-w-[120px]"
          >
            {deleteMutation.isPending ? (
              <span className="flex items-center gap-2">
                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                جاري الحذف...
              </span>
            ) : (
              <span className="flex items-center gap-1.5">
                <Trash2 className="w-4 h-4" />
                حذف السيارة
              </span>
            )}
          </Button>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}

/* ─── Pagination Component ─── */
function PaginationControls({
  currentPage,
  totalPages,
  onPageChange,
}: {
  currentPage: number
  totalPages: number
  onPageChange: (page: number) => void
}) {
  if (totalPages <= 1) return null

  const getVisiblePages = (): (number | '...')[] => {
    const pages: (number | '...')[] = []
    if (totalPages <= 7) {
      for (let i = 1; i <= totalPages; i++) pages.push(i)
    } else {
      pages.push(1)
      if (currentPage > 3) pages.push('...')
      const start = Math.max(2, currentPage - 1)
      const end = Math.min(totalPages - 1, currentPage + 1)
      for (let i = start; i <= end; i++) pages.push(i)
      if (currentPage < totalPages - 2) pages.push('...')
      pages.push(totalPages)
    }
    return pages
  }

  return (
    <div className="flex items-center justify-center gap-1 mt-6">
      <Button
        variant="outline"
        size="icon"
        className="h-8 w-8"
        onClick={() => onPageChange(currentPage - 1)}
        disabled={currentPage <= 1}
      >
        <ChevronRight className="w-4 h-4" />
      </Button>

      {getVisiblePages().map((page, idx) =>
        page === '...' ? (
          <span
            key={`ellipsis-${idx}`}
            className="px-2 text-muted-foreground text-sm"
          >
            ...
          </span>
        ) : (
          <Button
            key={page}
            variant={currentPage === page ? 'default' : 'outline'}
            size="icon"
            className={`h-8 w-8 ${currentPage === page ? 'bg-emerald-600 hover:bg-emerald-700 text-white border-emerald-600' : ''}`}
            onClick={() => onPageChange(page as number)}
          >
            {page}
          </Button>
        )
      )}

      <Button
        variant="outline"
        size="icon"
        className="h-8 w-8"
        onClick={() => onPageChange(currentPage + 1)}
        disabled={currentPage >= totalPages}
      >
        <ChevronLeft className="w-4 h-4" />
      </Button>
    </div>
  )
}

/* ─── Main Vehicles View ─── */
export default function VehiclesView() {
  const { setCurrentPage, setSelectedVehicleId } = useAppStore()

  /* ── Filters State ── */
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [filtersOpen, setFiltersOpen] = useState(false)
  const limit = 12

  /* ── Dialog State ── */
  const [showFormDialog, setShowFormDialog] = useState(false)
  const [editingVehicle, setEditingVehicle] = useState<Vehicle | null>(null)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)
  const [deletingVehicle, setDeletingVehicle] = useState<Vehicle | null>(null)

  /* ── Debounced Search ── */
  const [debouncedSearch, setDebouncedSearch] = useState('')
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search)
      setPage(1)
    }, 300)
    return () => clearTimeout(timer)
  }, [search])

  /* ── Status Change resets page (called from handler) ── */
  function handleStatusChange(newStatus: string) {
    setStatus(newStatus)
    setPage(1)
  }

  /* ── Data Fetching ── */
  const { data, isLoading, isError, refetch } = useQuery<VehiclesResponse>({
    queryKey: ['vehicles', debouncedSearch, status, page],
    queryFn: () =>
      fetch(
        `/api/vehicles?search=${encodeURIComponent(debouncedSearch)}&status=${status}&page=${page}&limit=${limit}`
      ).then((r) => {
        if (!r.ok) throw new Error('Failed to fetch vehicles')
        return r.json()
      }),
  })

  const vehicles = data?.vehicles || []
  const totalVehicles = data?.total || 0
  const totalPages = data?.pages || 0

  /* ── Handlers ── */
  function handleAdd() {
    setEditingVehicle(null)
    setShowFormDialog(true)
  }

  function handleEdit(vehicle: Vehicle) {
    setEditingVehicle(vehicle)
    setShowFormDialog(true)
  }

  function handleDelete(vehicle: Vehicle) {
    setDeletingVehicle(vehicle)
    setShowDeleteDialog(true)
  }

  function handleViewMaintenance(id: string) {
    setSelectedVehicleId(id)
    setCurrentPage('maintenance')
  }

  function clearFilters() {
    setSearch('')
    setStatus('')
    setPage(1)
  }

  const hasActiveFilters = search || status

  /* ── Loading State ── */
  if (isLoading) {
    return (
      <div className="space-y-6">
        {/* Header skeleton */}
        <div className="flex items-center justify-between">
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-10 w-40" />
        </div>

        {/* Filters skeleton */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Skeleton className="h-10 flex-1" />
              <Skeleton className="h-10 w-36" />
            </div>
          </CardContent>
        </Card>

        {/* Grid skeleton */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <VehicleCardSkeleton key={i} />
          ))}
        </div>
      </div>
    )
  }

  /* ── Error State ── */
  if (isError) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-foreground">إدارة أسطيل السيارات</h2>
          <Button onClick={handleAdd} className="bg-emerald-600 hover:bg-emerald-700 text-white">
            <Plus className="w-4 h-4" />
            إضافة سيارة جديدة
          </Button>
        </div>
        <Card className="border-destructive">
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <AlertTriangle className="w-12 h-12 text-destructive mb-4" />
            <h3 className="text-lg font-semibold mb-2">حدث خطأ أثناء تحميل البيانات</h3>
            <p className="text-muted-foreground text-sm mb-4">
              يرجى المحاولة مرة أخرى لاحقاً
            </p>
            <Button variant="outline" onClick={() => refetch()}>
              إعادة المحاولة
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* ── Page Header ── */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-foreground">
            إدارة أسطول السيارات
          </h2>
          <p className="text-sm text-muted-foreground mt-0.5">
            {totalVehicles > 0
              ? `إجمالي ${totalVehicles} سيارة في الأسطول`
              : 'لا توجد سيارات مسجلة في الأسطول'}
          </p>
        </div>
        <Button
          onClick={handleAdd}
          className="bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span className="hidden sm:inline">إضافة سيارة جديدة</span>
        </Button>
      </div>

      {/* ── Filters Bar ── */}
      <Card className="border-border/50">
        <CardContent className="p-4">
          {/* Mobile filter toggle */}
          <button
            onClick={() => setFiltersOpen(!filtersOpen)}
            className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors md:hidden mb-3"
          >
            <Filter className="w-4 h-4" />
            {filtersOpen ? 'إخفاء الفلاتر' : 'عرض الفلاتر'}
            {hasActiveFilters && (
              <Badge variant="secondary" className="text-xs bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                مفعل
              </Badge>
            )}
          </button>

          <div className={`space-y-3 md:space-y-0 md:flex md:items-center md:gap-3 ${filtersOpen ? 'block' : 'hidden md:flex'}`}>
            {/* Search Input */}
            <div className="relative flex-1">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
              <Input
                placeholder="بحث برقم اللوحة، الماركة، الموديل، اسم السائق، رقم الشاصي..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pr-10 h-10"
              />
              {search && (
                <button
                  onClick={() => setSearch('')}
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>

            {/* Status Filter */}
            <Select value={status} onValueChange={handleStatusChange}>
              <SelectTrigger className="h-10 w-full sm:w-[180px]">
                <SelectValue placeholder="جميع الحالات" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">
                  <span className="flex items-center gap-2">جميع الحالات</span>
                </SelectItem>
                {VEHICLE_STATUSES.map((s) => (
                  <SelectItem key={s.value} value={s.value}>
                    <span className="flex items-center gap-2">
                      <span className={`w-2 h-2 rounded-full ${s.color}`} />
                      {s.label}
                    </span>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            {/* Clear Filters */}
            {hasActiveFilters && (
              <Button
                variant="ghost"
                size="sm"
                onClick={clearFilters}
                className="text-muted-foreground hover:text-foreground shrink-0"
              >
                <X className="w-4 h-4" />
                مسح الفلاتر
              </Button>
            )}
          </div>

          {/* Results count */}
          {hasActiveFilters && (
            <div className="mt-3 pt-3 border-t text-xs text-muted-foreground">
              عرض {vehicles.length} نتيجة من أصل {totalVehicles} سيارة
            </div>
          )}
        </CardContent>
      </Card>

      {/* ── Vehicles Grid ── */}
      {vehicles.length > 0 ? (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {vehicles.map((vehicle) => (
              <VehicleCard
                key={vehicle.id}
                vehicle={vehicle}
                onEdit={handleEdit}
                onDelete={handleDelete}
                onViewMaintenance={handleViewMaintenance}
              />
            ))}
          </div>

          {/* ── Pagination ── */}
          <PaginationControls
            currentPage={page}
            totalPages={totalPages}
            onPageChange={setPage}
          />
        </>
      ) : (
        /* ── Empty State ── */
        <Card className="border-dashed">
          <CardContent className="flex flex-col items-center justify-center py-20 text-center">
            <div className="w-20 h-20 rounded-2xl bg-emerald-50 dark:bg-emerald-950/30 flex items-center justify-center mb-5">
              <Car className="w-10 h-10 text-emerald-400" />
            </div>
            <h3 className="text-lg font-semibold mb-2">
              {hasActiveFilters ? 'لا توجد نتائج مطابقة' : 'لا توجد سيارات في الأسطول'}
            </h3>
            <p className="text-muted-foreground text-sm max-w-md mb-5">
              {hasActiveFilters
                ? 'جرّب تعديل معايير البحث أو الفلاتر للعثور على السيارة المطلوبة'
                : 'ابدأ بإضافة سيارتك الأولى إلى أسطول المركبات للمتابعة والإدارة'}
            </p>
            <div className="flex items-center gap-3">
              {hasActiveFilters ? (
                <Button variant="outline" onClick={clearFilters}>
                  <X className="w-4 h-4" />
                  مسح الفلاتر
                </Button>
              ) : (
                <Button
                  onClick={handleAdd}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white"
                >
                  <Plus className="w-4 h-4" />
                  إضافة سيارة جديدة
                </Button>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* ── Form Dialog ── */}
      <VehicleFormDialog
        open={showFormDialog}
        onOpenChange={(open) => {
          setShowFormDialog(open)
          if (!open) setEditingVehicle(null)
        }}
        editingVehicle={editingVehicle}
      />

      {/* ── Delete Dialog ── */}
      <DeleteVehicleDialog
        open={showDeleteDialog}
        onOpenChange={(open) => {
          setShowDeleteDialog(open)
          if (!open) setDeletingVehicle(null)
        }}
        vehicle={deletingVehicle}
      />
    </div>
  )
}
