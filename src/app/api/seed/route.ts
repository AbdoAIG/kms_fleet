import { NextResponse } from 'next/server'
import { db } from '@/lib/db'

export async function POST() {
  try {
    // Check if data already exists
    const existingVehicles = await db.vehicle.count()
    if (existingVehicles > 0) {
      return NextResponse.json({ message: 'البيانات موجودة بالفعل', seeded: false })
    }

    const vehicles = [
      { plateNumber: 'أ ب ج 1234', make: 'تويوتا', model: 'كامري', year: 2022, color: 'أبيض', status: 'ACTIVE', department: 'المبيعات', driverName: 'أحمد محمد', driverPhone: '01012345678', fuelType: 'PETROL' },
      { plateNumber: 'د ه و 5678', make: 'هيونداي', model: 'سوناتا', year: 2023, color: 'أسود', status: 'ACTIVE', department: 'التسويق', driverName: 'محمد علي', driverPhone: '01098765432', fuelType: 'PETROL' },
      { plateNumber: 'ز ح ط 9012', make: 'نيسان', model: 'صني', year: 2021, color: 'فضي', status: 'MAINTENANCE', department: 'الخدمات', driverName: 'خالد إبراهيم', driverPhone: '01155667788', fuelType: 'PETROL' },
      { plateNumber: 'ي ك ل 3456', make: 'كيا', model: 'سيراتو', year: 2023, color: 'أحمر', status: 'ACTIVE', department: 'الإدارة', driverName: 'عمر حسن', driverPhone: '01233445566', fuelType: 'PETROL' },
      { plateNumber: 'م ن س 7890', make: 'مرسيدس', model: 'C200', year: 2022, color: 'رمادي', status: 'ACTIVE', department: 'الإدارة العليا', driverName: 'سعيد أحمد', driverPhone: '01011223344', fuelType: 'DIESEL' },
      { plateNumber: 'ع ف ق 1357', make: 'بي إم دبليو', model: '320i', year: 2021, color: 'أزرق', status: 'OUT_OF_SERVICE', department: 'المبيعات', fuelType: 'PETROL' },
      { plateNumber: 'ر ش ت 2468', make: 'فورد', model: 'إكسبلورر', year: 2023, color: 'أسود', status: 'ACTIVE', department: 'النقل', driverName: 'ياسر محمود', driverPhone: '01199887766', fuelType: 'DIESEL' },
      { plateNumber: 'ث خ ذ 3579', make: 'شيفروليه', model: 'أوبترا', year: 2020, color: 'أبيض', status: 'ACTIVE', department: 'الخدمات', driverName: 'حسن عبدالله', driverPhone: '01566778899', fuelType: 'PETROL' },
      { plateNumber: 'ض ظ غ 4680', make: 'هيونداي', model: 'توسان', year: 2024, color: 'أخضر', status: 'ACTIVE', department: 'المبيعات', driverName: 'محمود سالم', driverPhone: '01244556677', fuelType: 'HYBRID' },
      { plateNumber: 'ب ت ث 5791', make: 'تويوتا', model: 'هايلكس', year: 2022, color: 'أبيض', status: 'ACTIVE', department: 'النقل', driverName: 'إبراهيم عادل', driverPhone: '01377889900', fuelType: 'DIESEL' },
      { plateNumber: 'ج ح خ 6802', make: 'لاند روفر', model: 'رينج روفر', year: 2023, color: 'أسود', status: 'ACTIVE', department: 'الإدارة العليا', driverName: 'طارق نبيل', driverPhone: '01488990011', fuelType: 'DIESEL' },
      { plateNumber: 'د ذ ر 7913', make: 'نيسان', model: 'باترول', year: 2021, color: 'ذهبي', status: 'MAINTENANCE', department: 'النقل', driverName: 'عادل فؤاد', driverPhone: '01599001122', fuelType: 'PETROL' },
    ]

    const createdVehicles = []
    for (const v of vehicles) {
      const created = await db.vehicle.create({ data: v })
      createdVehicles.push(created)
    }

    const maintenanceRecords = [
      // Vehicle 0 - Toyota Camry
      { vehicleId: createdVehicles[0].id, maintenanceDate: new Date('2025-01-15'), description: 'تغيير زيت المحرك والفلتر', type: 'OIL_CHANGE', cost: 850, kilometerReading: 45000, serviceProvider: 'مركز الصيانة السريعة', invoiceNumber: 'INV-001', laborCost: 200, partsCost: 650, priority: 'NORMAL', status: 'COMPLETED', notes: 'زيت توتال 5W-30' },
      { vehicleId: createdVehicles[0].id, maintenanceDate: new Date('2025-03-20'), description: 'تغيير الإطارات الأربعة', type: 'TIRE', cost: 4800, kilometerReading: 52000, serviceProvider: 'مركز الإطارات المتقدمة', invoiceNumber: 'INV-002', laborCost: 400, partsCost: 4400, priority: 'NORMAL', status: 'COMPLETED', nextMaintenanceDate: new Date('2025-09-20'), nextMaintenanceKm: 62000 },
      { vehicleId: createdVehicles[0].id, maintenanceDate: new Date('2025-06-10'), description: 'فحص وتغيير فرامل أمامية', type: 'BRAKES', cost: 2200, kilometerReading: 58000, serviceProvider: 'ورشة الفرامل الاحترافية', invoiceNumber: 'INV-003', laborCost: 500, partsCost: 1700, priority: 'HIGH', status: 'COMPLETED' },

      // Vehicle 1 - Hyundai Sonata
      { vehicleId: createdVehicles[1].id, maintenanceDate: new Date('2025-02-10'), description: 'تغيير زيت + فلتر هواء', type: 'OIL_CHANGE', cost: 950, kilometerReading: 30000, serviceProvider: 'مركز هيونداي المعتمد', invoiceNumber: 'INV-010', laborCost: 250, partsCost: 700, priority: 'NORMAL', status: 'COMPLETED', notes: 'زيت هيونداي الأصلي' },
      { vehicleId: createdVehicles[1].id, maintenanceDate: new Date('2025-05-05'), description: 'إصلاح مولد كهرباء', type: 'ELECTRICAL', cost: 3500, kilometerReading: 35000, serviceProvider: 'ورشة الكهرباء الحديثة', invoiceNumber: 'INV-011', laborCost: 800, partsCost: 2700, priority: 'URGENT', status: 'COMPLETED' },
      { vehicleId: createdVehicles[1].id, maintenanceDate: new Date('2025-07-01'), description: 'صيانة دورية شاملة', type: 'MECHANICAL', cost: 4200, kilometerReading: 40000, serviceProvider: 'مركز هيونداي المعتمد', invoiceNumber: 'INV-012', laborCost: 1200, partsCost: 3000, priority: 'NORMAL', status: 'COMPLETED', nextMaintenanceDate: new Date('2025-10-01'), nextMaintenanceKm: 50000 },

      // Vehicle 2 - Nissan Sunny (IN MAINTENANCE)
      { vehicleId: createdVehicles[2].id, maintenanceDate: new Date('2025-01-20'), description: 'تغيير بطارية جديدة', type: 'BATTERY', cost: 2800, kilometerReading: 60000, serviceProvider: 'محل البطاريات', invoiceNumber: 'INV-020', laborCost: 200, partsCost: 2600, priority: 'HIGH', status: 'COMPLETED' },
      { vehicleId: createdVehicles[2].id, maintenanceDate: new Date('2025-04-15'), description: 'إصلاح مشاكل في التكييف', type: 'AC', cost: 1800, kilometerReading: 65000, serviceProvider: 'مركز التكييف المتخصص', invoiceNumber: 'INV-021', laborCost: 600, partsCost: 1200, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[2].id, maintenanceDate: new Date('2025-07-15'), description: 'تغيير كلاتش + أسطوانة', type: 'TRANSMISSION', cost: 8500, kilometerReading: 70000, serviceProvider: 'ورشة نيسان المعتمدة', invoiceNumber: 'INV-022', laborCost: 2500, partsCost: 6000, priority: 'URGENT', status: 'IN_PROGRESS', notes: 'في انتظار قطعة الغيار' },

      // Vehicle 3 - Kia Cerato
      { vehicleId: createdVehicles[3].id, maintenanceDate: new Date('2025-02-28'), description: 'تغيير زيت محرك', type: 'OIL_CHANGE', cost: 800, kilometerReading: 15000, serviceProvider: 'مركز كيا المعتمد', invoiceNumber: 'INV-030', laborCost: 150, partsCost: 650, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[3].id, maintenanceDate: new Date('2025-05-20'), description: 'دهان وتصليح هيكل', type: 'BODYWORK', cost: 5500, kilometerReading: 18000, serviceProvider: 'ورشة الدهان المتقدمة', invoiceNumber: 'INV-031', laborCost: 2000, partsCost: 3500, priority: 'LOW', status: 'COMPLETED' },

      // Vehicle 4 - Mercedes C200
      { vehicleId: createdVehicles[4].id, maintenanceDate: new Date('2025-01-10'), description: 'صيانة دورية A-Service', type: 'OIL_CHANGE', cost: 3500, kilometerReading: 25000, serviceProvider: 'وكالة مرسيدس المعتمدة', invoiceNumber: 'INV-040', laborCost: 1000, partsCost: 2500, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[4].id, maintenanceDate: new Date('2025-04-01'), description: 'تغيير فرامل كاملة', type: 'BRAKES', cost: 6200, kilometerReading: 30000, serviceProvider: 'وكالة مرسيدس المعتمدة', invoiceNumber: 'INV-041', laborCost: 1500, partsCost: 4700, priority: 'HIGH', status: 'COMPLETED' },
      { vehicleId: createdVehicles[4].id, maintenanceDate: new Date('2025-06-15'), description: 'إصلاح نظام التكييف', type: 'AC', cost: 4200, kilometerReading: 33000, serviceProvider: 'وكالة مرسيدس المعتمدة', invoiceNumber: 'INV-042', laborCost: 1200, partsCost: 3000, priority: 'NORMAL', status: 'COMPLETED', nextMaintenanceDate: new Date('2025-12-15'), nextMaintenanceKm: 43000 },

      // Vehicle 6 - Ford Explorer
      { vehicleId: createdVehicles[6].id, maintenanceDate: new Date('2025-03-01'), description: 'تغيير زيت + فلاتر', type: 'FILTER', cost: 1200, kilometerReading: 40000, serviceProvider: 'مركز فورد المعتمد', invoiceNumber: 'INV-050', laborCost: 300, partsCost: 900, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[6].id, maintenanceDate: new Date('2025-05-25'), description: 'إصلاح مساعدات أمامية', type: 'SUSPENSION', cost: 3800, kilometerReading: 45000, serviceProvider: 'ورشة التعليق المتخصصة', invoiceNumber: 'INV-051', laborCost: 1000, partsCost: 2800, priority: 'HIGH', status: 'COMPLETED' },
      { vehicleId: createdVehicles[6].id, maintenanceDate: new Date('2025-07-20'), description: 'صيانة ناقل الحركة', type: 'TRANSMISSION', cost: 7500, kilometerReading: 50000, serviceProvider: 'مركز فورد المعتمد', invoiceNumber: 'INV-052', laborCost: 2000, partsCost: 5500, priority: 'URGENT', status: 'PENDING' },

      // Vehicle 7 - Chevrolet Optra
      { vehicleId: createdVehicles[7].id, maintenanceDate: new Date('2025-02-15'), description: 'تغيير زيت وفلتر', type: 'OIL_CHANGE', cost: 700, kilometerReading: 80000, serviceProvider: 'ورشة عامة', invoiceNumber: 'INV-060', laborCost: 150, partsCost: 550, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[7].id, maintenanceDate: new Date('2025-06-05'), description: 'إصلاح كهرباء + تغيير دينامو', type: 'ELECTRICAL', cost: 2900, kilometerReading: 85000, serviceProvider: 'ورشة الكهرباء', invoiceNumber: 'INV-061', laborCost: 800, partsCost: 2100, priority: 'HIGH', status: 'COMPLETED' },

      // Vehicle 8 - Hyundai Tucson
      { vehicleId: createdVehicles[8].id, maintenanceDate: new Date('2025-04-10'), description: 'صيانة دورية أولى', type: 'OIL_CHANGE', cost: 900, kilometerReading: 10000, serviceProvider: 'مركز هيونداي المعتمد', invoiceNumber: 'INV-070', laborCost: 200, partsCost: 700, priority: 'NORMAL', status: 'COMPLETED', nextMaintenanceDate: new Date('2025-07-10'), nextMaintenanceKm: 20000 },

      // Vehicle 9 - Toyota Hilux
      { vehicleId: createdVehicles[9].id, maintenanceDate: new Date('2025-01-25'), description: 'تغيير زيت ديزل + فلتر', type: 'OIL_CHANGE', cost: 1100, kilometerReading: 55000, serviceProvider: 'مركز تويوتا المعتمد', invoiceNumber: 'INV-080', laborCost: 250, partsCost: 850, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[9].id, maintenanceDate: new Date('2025-03-15'), description: 'تغيير إطارات خلفية', type: 'TIRE', cost: 2800, kilometerReading: 60000, serviceProvider: 'مركز الإطارات', invoiceNumber: 'INV-081', laborCost: 300, partsCost: 2500, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[9].id, maintenanceDate: new Date('2025-06-25'), description: 'إصلاح مشاكل ميكانيكية متعددة', type: 'MECHANICAL', cost: 5400, kilometerReading: 67000, serviceProvider: 'مركز تويوتا المعتمد', invoiceNumber: 'INV-082', laborCost: 1800, partsCost: 3600, priority: 'HIGH', status: 'COMPLETED', nextMaintenanceDate: new Date('2025-09-25'), nextMaintenanceKm: 77000 },

      // Vehicle 10 - Land Rover Range Rover
      { vehicleId: createdVehicles[10].id, maintenanceDate: new Date('2025-02-05'), description: 'صيانة شاملة كاملة', type: 'MECHANICAL', cost: 9500, kilometerReading: 20000, serviceProvider: 'وكالة لاند روفر', invoiceNumber: 'INV-090', laborCost: 3000, partsCost: 6500, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[10].id, maintenanceDate: new Date('2025-05-15'), description: 'تغيير فرامل + أقراص', type: 'BRAKES', cost: 7200, kilometerReading: 25000, serviceProvider: 'وكالة لاند روفر', invoiceNumber: 'INV-091', laborCost: 1800, partsCost: 5400, priority: 'HIGH', status: 'COMPLETED' },

      // Vehicle 11 - Nissan Patrol (IN MAINTENANCE)
      { vehicleId: createdVehicles[11].id, maintenanceDate: new Date('2025-03-10'), description: 'تغيير زيت + فلتر', type: 'OIL_CHANGE', cost: 1200, kilometerReading: 90000, serviceProvider: 'مركز نيسان', invoiceNumber: 'INV-100', laborCost: 300, partsCost: 900, priority: 'NORMAL', status: 'COMPLETED' },
      { vehicleId: createdVehicles[11].id, maintenanceDate: new Date('2025-07-10'), description: 'إصلاح مشاكل المحرك', type: 'MECHANICAL', cost: 12000, kilometerReading: 95000, serviceProvider: 'ورشة المحركات المتخصصة', invoiceNumber: 'INV-101', laborCost: 4000, partsCost: 8000, priority: 'URGENT', status: 'IN_PROGRESS', notes: 'تم اكتشاف مشكلة في رأس الأسطوانة' },
    ]

    for (const record of maintenanceRecords) {
      await db.maintenanceRecord.create({ data: record })
    }

    return NextResponse.json({
      message: 'تم إضافة البيانات التجريبية بنجاح',
      seeded: true,
      vehiclesCount: vehicles.length,
      recordsCount: maintenanceRecords.length,
    })
  } catch (error) {
    console.error('Seed error:', error)
    return NextResponse.json(
      { error: 'حدث خطأ أثناء إضافة البيانات التجريبية' },
      { status: 500 }
    )
  }
}
