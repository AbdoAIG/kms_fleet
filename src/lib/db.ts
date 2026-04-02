import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

// Force create new client to pick up schema changes
const client = new PrismaClient({
  log: ['query'],
})

export const db = client

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db