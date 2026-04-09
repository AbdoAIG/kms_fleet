import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

// Helper: ensure default admin user exists
async function ensureDefaultAdmin() {
  const userCount = await db.user.count();
  if (userCount === 0) {
    await db.user.create({
      data: {
        name: 'مدير النظام',
        email: 'admin@fleet.com',
        password: 'admin123',
        role: 'ADMIN',
        isActive: true,
      },
    });
  }
}

// POST /api/auth/login
export async function POST(request: NextRequest) {
  try {
    // Ensure at least one user exists
    await ensureDefaultAdmin();

    const body = await request.json();
    const { email, password } = body;

    if (!email || !password) {
      return NextResponse.json(
        { error: 'البريد الإلكتروني وكلمة المرور مطلوبان' },
        { status: 400 }
      );
    }

    const user = await db.user.findUnique({
      where: { email },
    });

    if (!user) {
      return NextResponse.json(
        { error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة' },
        { status: 401 }
      );
    }

    if (!user.isActive) {
      return NextResponse.json(
        { error: 'هذا الحساب معطل. يرجى التواصل مع المسؤول' },
        { status: 403 }
      );
    }

    if (user.password !== password) {
      return NextResponse.json(
        { error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة' },
        { status: 401 }
      );
    }

    // Update last login
    await db.user.update({
      where: { id: user.id },
      data: { lastLogin: new Date() },
    });

    // Log activity
    await db.activityLog.create({
      data: {
        userId: user.id,
        action: 'LOGIN',
        entity: 'USER',
        entityId: user.id,
        details: `تسجيل دخول: ${user.name}`,
      },
    });

    // Return user without password, token is userId for simplicity
    const { password: _pw, ...safeUser } = user;

    return NextResponse.json({
      user: safeUser,
      token: user.id,
    });
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء تسجيل الدخول' },
      { status: 500 }
    );
  }
}

// GET /api/auth/me?userId=xxx
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const userId = searchParams.get('userId');

    if (!userId) {
      return NextResponse.json(
        { error: 'معرف المستخدم مطلوب' },
        { status: 400 }
      );
    }

    const user = await db.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        avatar: true,
        isActive: true,
        lastLogin: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      return NextResponse.json(
        { error: 'المستخدم غير موجود' },
        { status: 404 }
      );
    }

    return NextResponse.json({ user });
  } catch (error) {
    console.error('Get user error:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء جلب بيانات المستخدم' },
      { status: 500 }
    );
  }
}
