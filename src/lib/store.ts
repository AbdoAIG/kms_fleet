import { create } from 'zustand'

export type Page = 'dashboard' | 'vehicles' | 'maintenance' | 'reports' | 'settings'

interface Notification {
  id: string
  type: string
  title: string
  message: string
  date: string
  read: boolean
  entity?: string
  entityId?: string
}

interface CurrentUser {
  id: string
  name: string
  email: string
  role: string
  avatar?: string
}

interface AppState {
  currentPage: Page
  setCurrentPage: (page: Page) => void
  selectedVehicleId: string | null
  setSelectedVehicleId: (id: string | null) => void
  editingVehicleId: string | null
  setEditingVehicleId: (id: string | null) => void
  editingMaintenanceId: string | null
  setEditingMaintenanceId: (id: string | null) => void
  showVehicleDialog: boolean
  setShowVehicleDialog: (show: boolean) => void
  showMaintenanceDialog: boolean
  setShowMaintenanceDialog: (show: boolean) => void

  // Auth state
  isAuthenticated: boolean
  currentUser: CurrentUser | null
  setAuth: (user: CurrentUser | null) => void

  // Notifications
  notifications: Notification[]
  setNotifications: (notifications: Notification[]) => void
  unreadCount: number
  setUnreadCount: (count: number) => void
}

export const useAppStore = create<AppState>((set) => ({
  currentPage: 'dashboard',
  setCurrentPage: (page) => set({ currentPage: page }),
  selectedVehicleId: null,
  setSelectedVehicleId: (id) => set({ selectedVehicleId: id }),
  editingVehicleId: null,
  setEditingVehicleId: (id) => set({ editingVehicleId: id }),
  editingMaintenanceId: null,
  setEditingMaintenanceId: (id) => set({ editingMaintenanceId: id }),
  showVehicleDialog: false,
  setShowVehicleDialog: (show) => set({ showVehicleDialog: show }),
  showMaintenanceDialog: false,
  setShowMaintenanceDialog: (show) => set({ showMaintenanceDialog: show }),

  // Auth
  isAuthenticated: false,
  currentUser: null,
  setAuth: (user) =>
    set({
      isAuthenticated: !!user,
      currentUser: user,
    }),

  // Notifications
  notifications: [],
  setNotifications: (notifications) => {
    const unreadCount = notifications.filter((n) => !n.read).length
    set({ notifications, unreadCount })
  },
  unreadCount: 0,
  setUnreadCount: (count) => set({ unreadCount: count }),
}))
