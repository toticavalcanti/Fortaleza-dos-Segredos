import { NextResponse } from 'next/server'
import { getConfig } from '../../../src/lib/config'

export async function GET() {
  const { fortressUrl } = getConfig()

  if (!fortressUrl) {
    return NextResponse.json({ error: 'INTERNAL_FORTRESS_URL not configured' }, { status: 500 })
  }

  try {
    const res = await fetch(fortressUrl, { cache: 'no-store' })
    const text = await res.text()

    try {
      const json = JSON.parse(text)
      return NextResponse.json(json)
    } catch {
      return NextResponse.json({ raw: text })
    }
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || 'Fetch failed' }, { status: 500 })
  }
}