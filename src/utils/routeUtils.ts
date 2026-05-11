import type { Spot, RouteStep, SavedRoute, BusArrival } from '@/types'
import { formatKoreanWon } from './timeUtils'

export function buildRouteSteps(spot: Spot, busArrival: BusArrival | null): RouteStep[] {
  const waitMin = busArrival?.arrivalMinutes ?? spot.busWaitMinutes
  return [
    {
      type: 'start',
      icon: '📍',
      main: 'Your location',
      detail: 'Walk to nearest bus stop',
      durationMinutes: 0,
    },
    {
      type: 'walk',
      icon: '🚶',
      main: `Walk to ${spot.nearestStop}`,
      detail: '~3 min walk',
      durationMinutes: 3,
    },
    {
      type: 'bus',
      icon: '🚌',
      main: `Bus ${spot.busRoutes[0]}`,
      detail: `Wait ~${waitMin} min`,
      durationMinutes: waitMin,
    },
    {
      type: 'walk',
      icon: '🚶',
      main: `Walk to ${spot.name_en}`,
      detail: `${spot.walkMinutes} min from stop`,
      durationMinutes: spot.walkMinutes,
    },
    {
      type: 'arrive',
      icon: spot.emoji,
      main: spot.name_en,
      detail: `Open ${spot.hours} · ${formatKoreanWon(spot.fee)}`,
      durationMinutes: 0,
    },
  ]
}

export function computeTotalMinutes(spot: Spot, busArrival: BusArrival | null): number {
  const waitMin = busArrival?.arrivalMinutes ?? spot.busWaitMinutes
  return 3 + waitMin + spot.walkMinutes
}

export function buildSavedRoute(spot: Spot, busArrival: BusArrival | null): SavedRoute {
  const steps = buildRouteSteps(spot, busArrival)
  const total = computeTotalMinutes(spot, busArrival)
  return {
    id: `${spot.id}-${Date.now()}`,
    spotId: spot.id,
    spotName: spot.name_en,
    spotEmoji: spot.emoji,
    accent: spot.palette.accent,
    savedAt: Date.now(),
    totalMinutes: total,
    fee: spot.fee,
    steps,
  }
}

export function estimateTaxiPrice(totalMinutes: number): {
  minKrw: number
  maxKrw: number
  minutes: number
} {
  return {
    minutes: Math.round(totalMinutes * 0.5),
    minKrw: Math.round(totalMinutes * 600),
    maxKrw: Math.round(totalMinutes * 900),
  }
}
