'use client'

import { useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useAppStore } from '@/lib/store'
import { Bell, CheckCheck, Wrench, AlertTriangle, Car, Info, Settings, Clock, Shield } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Separator } from '@/components/ui/separator'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'
import { Skeleton } from '@/components/ui/skeleton'
import { toast } from 'sonner'
import { formatDistanceToNow } from 'date-fns'
import { ar } from 'date-fns/locale'

interface NotificationItem {
  id: string
  type: string
  title: string
  message: string
  date: string
  entityType: string
  entityId: string
}

interface NotificationsResponse {
  notifications: NotificationItem[]
  summary: {
    overdue: number
    upcoming: number
    pending: number
    inProgress: number
    highPriority: number
    total: number
  }
}

function getNotificationIcon(type: string) {
  switch (type) {
    case 'OVERDUE':
      return <AlertTriangle className="w-4 h-4 text-red-500" />
    case 'UPCOMING':
      return <Clock className="w-4 h-4 text-amber-500" />
    case 'IN_PROGRESS':
      return <Wrench className="w-4 h-4 text-blue-500" />
    case 'PENDING':
      return <Clock className="w-4 h-4 text-amber-500" />
    case 'URGENT':
      return <AlertTriangle className="w-4 h-4 text-red-500" />
    case 'HIGH_PRIORITY':
      return <Shield className="w-4 h-4 text-orange-500" />
    case 'maintenance':
      return <Wrench className="w-4 h-4 text-amber-500" />
    case 'vehicle':
      return <Car className="w-4 h-4 text-emerald-500" />
    default:
      return <Info className="w-4 h-4 text-slate-500" />
  }
}

function formatNotificationDate(dateStr: string): string {
  try {
    if (!dateStr) return ''
    return formatDistanceToNow(new Date(dateStr), { addSuffix: true, locale: ar })
  } catch {
    return dateStr
  }
}

function NotificationSkeleton() {
  return (
    <div className="flex items-start gap-3 p-3">
      <Skeleton className="w-8 h-8 rounded-full shrink-0" />
      <div className="flex-1 min-w-0 space-y-1.5">
        <Skeleton className="h-4 w-3/4" />
        <Skeleton className="h-3 w-full" />
        <Skeleton className="h-3 w-20" />
      </div>
    </div>
  )
}

export default function NotificationBell() {
  const { notifications, setNotifications, unreadCount } = useAppStore()
  const queryClient = useQueryClient()

  const { data, isLoading } = useQuery<NotificationsResponse>({
    queryKey: ['notifications'],
    queryFn: () =>
      fetch('/api/notifications').then((r) => {
        if (!r.ok) throw new Error('Failed to fetch notifications')
        return r.json()
      }),
    refetchInterval: 60000,
    staleTime: 55000,
  })

  useEffect(() => {
    if (data?.notifications) {
      setNotifications(data.notifications)
    }
  }, [data, setNotifications])

  const displayNotifications = notifications.length > 0 ? notifications : (data?.notifications || [])

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="relative"
          aria-label="الإشعارات"
        >
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute -top-0.5 -left-0.5 flex items-center justify-center w-5 h-5 rounded-full bg-red-500 text-white text-[10px] font-bold leading-none">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent
        align="start"
        dir="rtl"
        className="w-80 sm:w-96 p-0"
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 pb-2">
          <div className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-foreground" />
            <h3 className="font-semibold text-foreground">الإشعارات</h3>
            {unreadCount > 0 && (
              <Badge variant="secondary" className="bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 text-xs px-2 py-0">
                {unreadCount} جديد
              </Badge>
            )}
          </div>
        </div>
        <Separator />

        {/* Notification List */}
        <ScrollArea className="max-h-80">
          {isLoading ? (
            <div className="p-2 space-y-1">
              {Array.from({ length: 4 }).map((_, i) => (
                <NotificationSkeleton key={i} />
              ))}
            </div>
          ) : displayNotifications.length > 0 ? (
            <div className="p-2">
              {displayNotifications.slice(0, 20).map((notification) => (
                <div
                  key={notification.id}
                  className={`flex items-start gap-3 p-3 rounded-lg transition-colors cursor-default hover:bg-muted/50`}
                >
                  <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center shrink-0">
                    {getNotificationIcon(notification.type)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate text-foreground">
                      {notification.title}
                    </p>
                    <p className="text-xs text-muted-foreground mt-0.5 line-clamp-2 leading-relaxed">
                      {notification.message}
                    </p>
                    {notification.date && (
                      <p className="text-xs text-muted-foreground/70 mt-1 flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {formatNotificationDate(notification.date)}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
              <div className="w-14 h-14 rounded-full bg-muted flex items-center justify-center mb-3">
                <Bell className="w-6 h-6 text-muted-foreground/50" />
              </div>
              <p className="text-sm font-medium">لا توجد إشعارات</p>
              <p className="text-xs mt-1">ستظهر هنا أي إشعارات جديدة</p>
            </div>
          )}
        </ScrollArea>
      </PopoverContent>
    </Popover>
  )
}
