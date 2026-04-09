import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

// GET /api/settings - Return company settings
export async function GET() {
  try {
    let settings = await db.companySettings.findFirst();

    // If no settings exist, return defaults
    if (!settings) {
      return NextResponse.json({
        id: null,
        companyName: 'شركة صيانة السيارات',
        companyLogo: null,
        address: null,
        phone: null,
        email: null,
        website: null,
        currency: 'EGP',
        language: 'ar',
      });
    }

    return NextResponse.json(settings);
  } catch (error) {
    console.error('Error fetching settings:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب إعدادات الشركة' },
      { status: 500 }
    );
  }
}

// PUT /api/settings - Update company settings
export async function PUT(request: NextRequest) {
  try {
    const body = await request.json();

    // Check if settings exist
    const existing = await db.companySettings.findFirst();

    let settings;
    if (existing) {
      settings = await db.companySettings.update({
        where: { id: existing.id },
        data: {
          companyName: body.companyName !== undefined ? body.companyName : undefined,
          companyLogo: body.companyLogo !== undefined ? body.companyLogo : undefined,
          address: body.address !== undefined ? body.address : undefined,
          phone: body.phone !== undefined ? body.phone : undefined,
          email: body.email !== undefined ? body.email : undefined,
          website: body.website !== undefined ? body.website : undefined,
          currency: body.currency !== undefined ? body.currency : undefined,
          language: body.language !== undefined ? body.language : undefined,
        },
      });
    } else {
      settings = await db.companySettings.create({
        data: {
          companyName: body.companyName || 'شركة صيانة السيارات',
          companyLogo: body.companyLogo || null,
          address: body.address || null,
          phone: body.phone || null,
          email: body.email || null,
          website: body.website || null,
          currency: body.currency || 'EGP',
          language: body.language || 'ar',
        },
      });
    }

    // Log activity
    await db.activityLog.create({
      data: {
        action: 'UPDATE',
        entity: 'SETTINGS',
        entityId: settings.id,
        details: 'تم تحديث إعدادات الشركة',
      },
    });

    return NextResponse.json(settings);
  } catch (error) {
    console.error('Error updating settings:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء تحديث إعدادات الشركة' },
      { status: 500 }
    );
  }
}
