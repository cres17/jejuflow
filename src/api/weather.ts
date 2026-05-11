import axios from 'axios'
import { fetchWithCache } from '@/utils/cache'
import { classifyWeather } from '@/utils/weatherUtils'
import { getKMABaseDateTime } from '@/utils/timeUtils'
import type { Region, WeatherData } from '@/types'

const BASE_URL = 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
const API_KEY  = process.env.EXPO_PUBLIC_WEATHER_API_KEY ?? ''
const CACHE_TTL = 10 * 60 * 1000

const GRID: Record<Region, { nx: number; ny: number }> = {
  'jeju-city': { nx: 53, ny: 38 },
  seogwipo:    { nx: 52, ny: 33 },
}

const MOCK_WEATHER: WeatherData = {
  condition:   'clear',
  temperature: '22°C',
  wind:        3.2,
  updatedAt:   Date.now(),
  fromCache:   false,
}

async function fetchWeatherFromAPI(region: Region): Promise<WeatherData> {
  if (!API_KEY) return MOCK_WEATHER

  const { nx, ny }     = GRID[region]
  const { date, time } = getKMABaseDateTime()

  const { data } = await axios.get(BASE_URL, {
    timeout: 5000,
    params: {
      serviceKey: API_KEY,
      pageNo:     1,
      numOfRows:  100,
      dataType:   'JSON',
      base_date:  date,
      base_time:  time,
      nx,
      ny,
    },
  })

  const items: unknown[] = data?.response?.body?.items?.item ?? []
  return parseItems(items)
}

function parseItems(items: unknown[]): WeatherData {
  const now    = new Date()
  const target = `${String(now.getHours()).padStart(2, '0')}00`
  let pty = '0', wsd = 0, tmp: string | null = null, sky = '1'

  for (const raw of items) {
    const item = raw as Record<string, string>
    if (item.fcstTime !== target) continue
    if (item.category === 'PTY') pty = item.fcstValue
    if (item.category === 'WSD') wsd = parseFloat(item.fcstValue)
    if (item.category === 'TMP') tmp = item.fcstValue
    if (item.category === 'SKY') sky = item.fcstValue
  }

  return {
    condition:   classifyWeather(pty, wsd, sky),
    temperature: tmp ? `${tmp}°C` : null,
    wind:        wsd,
    updatedAt:   Date.now(),
    fromCache:   false,
  }
}

export async function getWeather(region: Region): Promise<WeatherData> {
  const cacheKey = `weather:${region}`
  const result = await fetchWithCache(
    cacheKey,
    () => fetchWeatherFromAPI(region),
    CACHE_TTL
  )
  return { ...result.data, fromCache: result.fromCache }
}
