import { create } from 'zustand'

export type Page = 'dashboard' | 'vehicles' | 'maintenance' | 'reports'

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
}))
