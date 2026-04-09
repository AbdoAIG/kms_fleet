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
} from 'lucide-react'
import { Button } from '@/components/ui/button'
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
        <div className="w-11 h-11 rounded-xl bg-white/20 flex items-center justify-center shrink-0">
          <Truck className="w-6 h-6 text-white" />
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
          <div className="w-9 h-9 rounded-full bg-emerald-500/30 flex items-center justify-center text-sm font-bold text-white shrink-0">
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
            <div className="flex items-center justify-between px-4 md:px-6 h-16">
              {/* Right side: hamburger + title */}
              <div className="flex items-center gap-3">
                {/* Mobile hamburger → Sheet */}
                <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}>
                  <SheetTrigger asChild>
                    <Button variant="ghost" size="icon" className="md:hidden">
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
                  <h2 className="text-lg font-bold text-foreground leading-tight">
                    {pageTitles[currentPage]}
                  </h2>
                  <p className="text-xs text-muted-foreground hidden sm:block">
                    {pageDescriptions[currentPage]}
                  </p>
                </div>
              </div>

              {/* Left side: actions */}
              <div className="flex items-center gap-1">
                {/* Theme toggle */}
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
                  aria-label="تبديل المظهر"
                >
                  <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
                  <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
                  <span className="sr-only">تبديل المظهر</span>
                </Button>
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
          <footer className="border-t bg-background/95 backdrop-blur-sm px-4 md:px-6 py-3">
            <p className="text-center text-xs text-muted-foreground">
              © 2025 شركة صيانة السيارات - جميع الحقوق محفوظة
            </p>
          </footer>
        </div>
      </div>
    </QueryClientProvider>
  )
}
