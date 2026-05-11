import type { WeatherCondition, TimeOfDay } from '@/types'

export function classifyWeather(
  pty: string,
  wsd: number,
  sky: string
): WeatherCondition {
  const isRain = ['1', '2', '3', '4'].includes(pty)
  if (isRain && wsd >= 14) return 'storm'
  if (isRain) return 'rain'
  if (wsd >= 14) return 'windy'
  if (sky === '4') return 'cloudy'
  return 'clear'
}

export function detectTimeOfDay(): TimeOfDay {
  const h = new Date().getHours()
  if (h >= 5 && h < 10) return 'morning'
  if (h >= 10 && h < 13) return 'noon'
  if (h >= 13 && h < 18) return 'afternoon'
  if (h >= 18 && h < 22) return 'evening'
  return 'night'
}

export const WEATHER_ADVICE: Record<WeatherCondition, string> = {
  clear:  'Great conditions — all spots accessible by bus.',
  cloudy: 'Comfortable for both indoor and outdoor spots.',
  rain:   'Rain today — indoor spots recommended.',
  windy:  'Coastal spots are dangerous. Stay inland.',
  storm:  'Stay indoors. No outdoor activities today.',
}

export const WEATHER_ICONS: Record<WeatherCondition, string> = {
  clear:  '☀️',
  cloudy: '☁️',
  rain:   '🌧',
  windy:  '💨',
  storm:  '⛈',
}

export const WEATHER_LABELS: Record<WeatherCondition, string> = {
  clear:  'Clear',
  cloudy: 'Cloudy',
  rain:   'Rain',
  windy:  'Strong Wind',
  storm:  'Storm',
}

export const WEATHER_WARNINGS: Partial<Record<WeatherCondition, string>> = {
  rain:  '⚠️ Slippery paths at outdoor spots',
  windy: '⚠️ Wind advisory — coastal areas unsafe',
  storm: '🚨 Storm warning — outdoor activities suspended',
}

export function isBadWeather(condition: WeatherCondition | undefined): boolean {
  if (!condition) return false
  return ['rain', 'windy', 'storm'].includes(condition)
}

export function formatUpdatedAt(timestamp: number): string {
  const d = Math.round((Date.now() - timestamp) / 1000)
  if (d < 10) return 'just now'
  if (d < 60) return `${d}s ago`
  if (d < 3600) return `${Math.round(d / 60)}m ago`
  return `${Math.round(d / 3600)}h ago`
}
