import axios from 'axios'
import { fetchWithCache } from '@/utils/cache'
import type { BusArrival } from '@/types'

const BASE_URL = 'https://apis.data.go.kr/1613000/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList'
const API_KEY  = process.env.EXPO_PUBLIC_TAGO_API_KEY ?? ''
const CACHE_TTL = 1 * 60 * 1000

function makeMockArrivals(stopId: string): BusArrival[] {
  const seed = stopId.charCodeAt(stopId.length - 1) % 20
  return [
    {
      routeNo:        '710',
      destination:    'Jeju Airport',
      arrivalMinutes: seed + 5,
      remainingStops: seed + 2,
      isLongWait:     seed + 5 > 30,
    },
    {
      routeNo:        '202',
      destination:    'Hallim',
      arrivalMinutes: seed + 18,
      remainingStops: seed + 8,
      isLongWait:     seed + 18 > 30,
    },
  ]
}

async function fetchBusFromAPI(stopId: string): Promise<BusArrival[]> {
  if (!API_KEY) return makeMockArrivals(stopId)

  const { data } = await axios.get(BASE_URL, {
    timeout: 5000,
    params: {
      serviceKey: API_KEY,
      pageNo:     1,
      numOfRows:  10,
      _type:      'json',
      cityCode:   38,
      nodeId:     stopId,
    },
  })

  const raw = data?.response?.body?.items?.item
  if (!raw) return []

  const items = Array.isArray(raw) ? raw : [raw]

  return items.map((item: Record<string, unknown>) => {
    const arrtime = typeof item.arrtime === 'number' ? item.arrtime : 0
    const mins    = Math.round(arrtime / 60)
    return {
      routeNo:        String(item.routeno ?? '—'),
      destination:    String(item.nodenm  ?? '—'),
      arrivalMinutes: mins,
      remainingStops: typeof item.arrprevstationcnt === 'number' ? item.arrprevstationcnt : 0,
      isLongWait:     mins > 30,
    }
  })
}

export async function getBusArrivals(stopId: string): Promise<{ arrivals: BusArrival[]; fromCache: boolean }> {
  const cacheKey = `bus:${stopId}`
  const result = await fetchWithCache(
    cacheKey,
    () => fetchBusFromAPI(stopId),
    CACHE_TTL
  )
  return { arrivals: result.data, fromCache: result.fromCache }
}
