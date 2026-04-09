'use client'

import { useState, useMemo, type ComponentType } from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useTheme } from 'next-themes'
import {
  LayoutDashboard,
  Car,
  Wrench,
  BarChart3,
  Menu,
  Sun,
  Moon,
  Truck,
  LogOut,
  Settings,
  Shield,
  UserCircle,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
  SheetTrigger,
} from '@/components/ui/sheet'
import { cn } from '@/lib/utils'
import { useAppStore, type Page } from '@/lib/store'
import NotificationBell from '@/components/NotificationBell'

import DashboardView from '@/components/views/DashboardView'
import VehiclesView from '@/components/views/VehiclesView'
import MaintenanceView from '@/components/views/MaintenanceView'
import ReportsView from '@/components/views/ReportsView'

/* ─── Navigation Config ─── */
const navItems: {
  label: string
  icon: ComponentType<{ className?: string }>
  page: Page
}[] = [
  { label: 'لوحة التحكم', icon: LayoutDashboard, page: 'dashboard' },
  { label: 'إدارة السيارات', icon: Car, page: 'vehicles' },
  { label: 'سجلات الصيانة', icon: Wrench, page: 'maintenance' },
  { label: 'التقارير', icon: BarChart3, page: 'reports' },
]

const pageTitles: Record<Page, string> = {
  dashboard: 'لوحة التحكم',
  vehicles: 'إدارة السيارات',
  maintenance: 'سجلات الصيانة',
  reports: 'التقارير',
}

const pageDescriptions: Record<Page, string> = {
  dashboard: 'نظرة عامة على أداء الأسطول',
  vehicles: 'إدارة وتتبع سيارات الأسطول',
  maintenance: 'سجلات وجداول الصيانة',
  reports: 'تقارير وتحليلات مفصلة',
}

/* ─── Profile Dropdown ─── */
function ProfileDropdown() {
  return (
    <DropdownMenu dir="rtl">
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          className="relative h-9 w-9 rounded-full p-0 focus-visible:ring-2 focus-visible:ring-emerald-500 focus-visible:ring-offset-2"
          aria-label="قائمة المستخدم"
        >
          <Avatar className="h-9 w-9 border-2 border-emerald-400 shadow-sm">
            <AvatarFallback className="bg-gradient-to-br from-teal-500 to-emerald-700 text-white text-sm font-bold">
              م
            </AvatarFallback>
          </Avatar>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent
        className="w-56"
        align="start"
        sideOffset={8}
      >
        <DropdownMenuLabel className="font-normal">
          <div className="flex flex-col gap-1">
            <p className="text-sm font-semibold leading-none">مدير النظام</p>
            <p className="text-xs leading-none text-muted-foreground">
              admin@fleet.com
            </p>
          </div>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuGroup>
          <DropdownMenuItem className="cursor-pointer gap-2">
            <UserCircle className="h-4 w-4 text-muted-foreground" />
            <span>الملف الشخصي</span>
          </DropdownMenuItem>
          <DropdownMenuItem className="cursor-pointer gap-2">
            <Settings className="h-4 w-4 text-muted-foreground" />
            <span>الإعدادات</span>
          </DropdownMenuItem>
          <DropdownMenuItem className="cursor-pointer gap-2">
            <Shield className="h-4 w-4 text-muted-foreground" />
            <span>إدارة المستخدمين</span>
          </DropdownMenuItem>
        </DropdownMenuGroup>
        <DropdownMenuSeparator />
        <DropdownMenuItem className="cursor-pointer gap-2 text-red-600 focus:text-red-600">
          <LogOut className="h-4 w-4" />
          <span>تسجيل الخروج</span>
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

/* ─── Sidebar Content (shared between desktop & mobile) ─── */
function SidebarContent({
  currentPage,
  onPageSelect,
  isSheet = false,
}: {
  currentPage: Page
  onPageSelect: (page: Page) => void
  isSheet?: boolean
}) {
  return (
    <div className="flex flex-col h-full">
      {/* Brand */}
      <div
        className={cn(
          'flex items-center gap-3 border-b border-white/10',
          isSheet ? 'p-6 pt-10' : 'p-6'
        )}
      >
        <div className="w-11 h-11 rounded-xl bg-white/20 flex items-center justify-center shrink-0 overflow-hidden">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/logo.png"
            alt="KMS Fleet"
            className="w-full h-full object-contain"
          />
        </div>
        <div className="min-w-0">
          <h1 className="font-bold text-white text-sm leading-tight truncate">
            نظام إدارة صيانة
          </h1>
          <p className="text-emerald-200 text-xs mt-0.5">السيارات</p>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-3 space-y-1">
        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = currentPage === item.page
          return (
            <button
              key={item.page}
              onClick={() => onPageSelect(item.page)}
              className={cn(
                'w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200',
                isActive
                  ? 'bg-white/15 text-white border-r-4 border-emerald-300 shadow-sm'
                  : 'text-emerald-100 hover:bg-white/10 hover:text-white'
              )}
            >
              <Icon className="w-5 h-5 shrink-0" />
              <span>{item.label}</span>
            </button>
          )
        })}
      </nav>

      {/* Bottom user info */}
      <div className="p-4 border-t border-white/10">
        <div className="flex items-center gap-3 px-3 py-2">
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-teal-400 to-emerald-600 flex items-center justify-center text-sm font-bold text-white shrink-0 shadow-md ring-2 ring-white/20">
            م
          </div>
          <div className="min-w-0">
            <p className="text-white text-sm font-medium truncate">مدير النظام</p>
            <p className="text-emerald-300/70 text-xs truncate">
              admin@fleet.com
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

/* ─── Main Page Component ─── */
export default function Home() {
  const { currentPage, setCurrentPage } = useAppStore()
  const { theme, setTheme } = useTheme()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const queryClient = useMemo(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30 * 1000,
            refetchOnWindowFocus: false,
            retry: 1,
          },
        },
      }),
    []
  )

  const handlePageSelect = (page: Page) => {
    setCurrentPage(page)
    setSidebarOpen(false)
  }

  return (
    <QueryClientProvider client={queryClient}>
      <div className="min-h-screen flex bg-background">
        {/* ── Desktop Sidebar ── */}
        <aside className="hidden md:flex w-64 sticky top-0 h-screen flex-col bg-gradient-to-b from-emerald-950 via-emerald-900 to-teal-900 text-white shrink-0 overflow-y-auto">
          <SidebarContent
            currentPage={currentPage}
            onPageSelect={handlePageSelect}
          />
        </aside>

        {/* ── Main Content Area ── */}
        <div className="flex-1 flex flex-col min-h-screen">
          {/* Header */}
          <header className="sticky top-0 z-20 bg-background/80 backdrop-blur-md border-b">
            <div className="flex items-center justify-between px-4 md:px-6 h-14">
              {/* Right side: hamburger + title */}
              <div className="flex items-center gap-3">
                {/* Mobile hamburger → Sheet */}
                <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}>
                  <SheetTrigger asChild>
                    <Button variant="ghost" size="icon" className="md:hidden h-9 w-9">
                      <Menu className="w-5 h-5" />
                      <span className="sr-only">فتح القائمة</span>
                    </Button>
                  </SheetTrigger>

                  <SheetContent
                    side="right"
                    className="p-0 w-72 bg-gradient-to-b from-emerald-950 via-emerald-900 to-teal-900 text-white border-l-0"
                  >
                    <SheetHeader className="sr-only">
                      <SheetTitle>القائمة الرئيسية</SheetTitle>
                      <SheetDescription>التنقل بين أقسام النظام</SheetDescription>
                    </SheetHeader>
                    <SidebarContent
                      currentPage={currentPage}
                      onPageSelect={handlePageSelect}
                      isSheet
                    />
                  </SheetContent>
                </Sheet>

                <div>
                  <h2 className="text-base font-bold text-foreground leading-tight">
                    {pageTitles[currentPage]}
                  </h2>
                  <p className="text-[11px] text-muted-foreground hidden sm:block">
                    {pageDescriptions[currentPage]}
                  </p>
                </div>
              </div>

              {/* Left side: actions */}
              <div className="flex items-center gap-0.5">
                {/* Notification Bell */}
                <NotificationBell />

                {/* Theme toggle */}
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9"
                  onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
                  aria-label="تبديل المظهر"
                >
                  <Sun className="h-[18px] w-[18px] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
                  <Moon className="absolute h-[18px] w-[18px] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
                  <span className="sr-only">تبديل المظهر</span>
                </Button>

                {/* Profile avatar */}
                <ProfileDropdown />
              </div>
            </div>
          </header>

          {/* Page Content */}
          <main className="flex-1 p-4 md:p-6 overflow-auto">
            {currentPage === 'dashboard' && <DashboardView />}
            {currentPage === 'vehicles' && <VehiclesView />}
            {currentPage === 'maintenance' && <MaintenanceView />}
            {currentPage === 'reports' && <ReportsView />}
          </main>

          {/* Footer */}
          <footer className="border-t bg-background/95 backdrop-blur-sm px-4 md:px-6 py-3 mt-auto">
            <p className="text-center text-xs text-muted-foreground">
              © 2025 شركة KMS Fleet - جميع الحقوق محفوظة
            </p>
          </footer>
        </div>
      </div>
    </QueryClientProvider>
  )
}
