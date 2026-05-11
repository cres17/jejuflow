export type Region = 'jeju-city' | 'seogwipo'
export type WeatherCondition = 'clear' | 'cloudy' | 'rain' | 'windy' | 'storm'
export type TimeOfDay = 'morning' | 'noon' | 'afternoon' | 'evening' | 'night'

export interface WeatherData {
  condition: WeatherCondition
  temperature: string | null
  wind: number
  updatedAt: number
  fromCache: boolean
}

export interface BusArrival {
  routeNo: string
  destination: string
  arrivalMinutes: number
  remainingStops: number
  isLongWait: boolean
}

export interface Spot {
  id: string
  name_en: string
  emoji: string
  sub: string
  category: 'outdoor' | 'indoor' | 'both'
  region: Region
  nearestStop: string
  stopId: string
  busRoutes: string[]
  walkMinutes: number
  busWaitMinutes: number
  palette: { bg: string; accent: string }
  fee: number
  hours: string
  tags: string[]
  altSpotId: string | null
  lat: number
  lng: number
}

export interface RouteStep {
  type: 'start' | 'walk' | 'bus' | 'arrive'
  icon: string
  main: string
  detail: string
  durationMinutes: number
}

export interface SavedRoute {
  id: string
  spotId: string
  spotName: string
  spotEmoji: string
  accent: string
  savedAt: number
  totalMinutes: number
  fee: number
  steps: RouteStep[]
  isWeatherAffected?: boolean
}
