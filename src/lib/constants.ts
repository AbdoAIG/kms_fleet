export const MAINTENANCE_TYPES = [
  { value: 'OIL_CHANGE', label: 'تغيير زيت' },
  { value: 'TIRE', label: 'إطارات (كاوتش)' },
  { value: 'ELECTRICAL', label: 'كهرباء' },
  { value: 'MECHANICAL', label: 'ميكانيكا' },
  { value: 'BRAKES', label: 'فرامل' },
  { value: 'BODYWORK', label: 'هيكل ودهان' },
  { value: 'AC', label: 'تكييف' },
  { value: 'TRANSMISSION', label: 'ناقل حركة' },
  { value: 'FILTER', label: 'فلاتر' },
  { value: 'BATTERY', label: 'بطارية' },
  { value: 'SUSPENSION', label: 'مساعدات ومعلقات' },
  { value: 'OTHER', label: 'أخرى' },
] as const

export const VEHICLE_STATUSES = [
  { value: 'ACTIVE', label: 'نشطة', color: 'bg-emerald-500' },
  { value: 'MAINTENANCE', label: 'في الصيانة', color: 'bg-amber-500' },
  { value: 'OUT_OF_SERVICE', label: 'خارج الخدمة', color: 'bg-red-500' },
  { value: 'SOLD', label: 'مباعة', color: 'bg-gray-500' },
] as const

export const MAINTENANCE_STATUSES = [
  { value: 'PENDING', label: 'معلقة', color: 'bg-amber-500' },
  { value: 'IN_PROGRESS', label: 'قيد التنفيذ', color: 'bg-blue-500' },
  { value: 'COMPLETED', label: 'مكتملة', color: 'bg-emerald-500' },
  { value: 'CANCELLED', label: 'ملغية', color: 'bg-red-500' },
] as const

export const PRIORITIES = [
  { value: 'LOW', label: 'منخفضة', color: 'bg-slate-500' },
  { value: 'NORMAL', label: 'عادية', color: 'bg-emerald-500' },
  { value: 'HIGH', label: 'عالية', color: 'bg-amber-500' },
  { value: 'URGENT', label: 'عاجلة', color: 'bg-red-500' },
] as const

export const FUEL_TYPES = [
  { value: 'PETROL', label: 'بنزين' },
  { value: 'DIESEL', label: 'ديزل' },
  { value: 'ELECTRIC', label: 'كهربائي' },
  { value: 'HYBRID', label: 'هجين' },
] as const

export const VEHICLE_MAKES = [
  'تويوتا', 'هيونداي', 'نيسان', 'كيا', 'مرسيدس', 'بي إم دبليو',
  'أودي', 'فورد', 'شيفروليه', 'هوندا', 'فولكس فاجن', 'لاند روفر',
  'جيب', 'لكزس', 'إنفينيتي', 'بورشه', 'جاجوار', 'فولفو',
  'ميتسوبيشي', 'سوزوكي', 'مازدا', 'بيوك', 'كاديلاك', 'لينكولن',
  'رينو', 'بيجو', 'سيات', 'فيات', 'أوبل', 'سكودا',
]

export function getMaintenanceTypeLabel(value: string): string {
  return MAINTENANCE_TYPES.find(t => t.value === value)?.label || value
}

export function getVehicleStatusLabel(value: string): string {
  return VEHICLE_STATUSES.find(s => s.value === value)?.label || value
}

export function getMaintenanceStatusLabel(value: string): string {
  return MAINTENANCE_STATUSES.find(s => s.value === value)?.label || value
}

export function getPriorityLabel(value: string): string {
  return PRIORITIES.find(p => p.value === value)?.label || value
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('ar-EG', {
    style: 'currency',
    currency: 'EGP',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(amount)
}

export function formatDate(date: string | Date): string {
  return new Intl.DateTimeFormat('ar-EG', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date(date))
}

export function formatNumber(num: number): string {
  return new Intl.NumberFormat('ar-EG').format(num)
}
