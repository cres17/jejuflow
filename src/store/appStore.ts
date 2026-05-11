import { create } from 'zustand'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { getWeather } from '@/api/weather'
import { getBusArrivals } from '@/api/transit'
import { detectRegion } from '@/utils/locationUtils'
import { detectTimeOfDay, isBadWeather } from '@/utils/weatherUtils'
import spotsData from '@/data/spots.json'
import type { Region, WeatherData, BusArrival, Spot, SavedRoute, TimeOfDay } from '@/types'

const SPOTS: Spot[] = spotsData as Spot[]
const SAVED_ROUTES_KEY = 'savedRoutes:v1'

interface AppState {
  weather: Record<Region, WeatherData | null>
  weatherError: string | null
  weatherLoading: boolean

  region: Region
  timeOfDay: TimeOfDay

  busArrivals: Record<string, { arrivals: BusArrival[]; fromCache: boolean }>
  busLoading: boolean
  busError: string | null

  selectedSpot: Spot | null
  savedRoutes: SavedRoute[]

  initApp: () => Promise<void>
  fetchWeather: (region: Region) => Promise<void>
  fetchBusArrivals: (stopId: string) => Promise<void>
  setRegion: (region: Region) => void
  selectSpot: (spot: Spot | null) => void
  saveRoute: (route: SavedRoute) => Promise<void>
  deleteRoute: (id: string) => Promise<void>
  loadSavedRoutes: () => Promise<void>
  getFilteredSpots: () => Spot[]
}

export const useAppStore = create<AppState>((set, get) => ({
  weather:        { 'jeju-city': null, seogwipo: null },
  weatherError:   null,
  weatherLoading: false,
  region:         'jeju-city',
  timeOfDay:      detectTimeOfDay(),
  busArrivals:    {},
  busLoading:     false,
  busError:       null,
  selectedSpot:   null,
  savedRoutes:    [],

  initApp: async () => {
    const { fetchWeather, loadSavedRoutes } = get()
    const region = await detectRegion()
    set({ region, timeOfDay: detectTimeOfDay() })
    await Promise.allSettled([
      fetchWeather(region),
      loadSavedRoutes(),
    ])
  },

  fetchWeather: async (region: Region) => {
    set({ weatherLoading: true, weatherError: null })
    try {
      const data = await getWeather(region)
      set(state => ({
        weather: { ...state.weather, [region]: data },
        weatherLoading: false,
      }))
    } catch {
      set({
        weatherLoading: false,
        weatherError: 'Could not refresh weather. Showing cached data.',
      })
    }
  },

  fetchBusArrivals: async (stopId: string) => {
    set({ busLoading: true, busError: null })
    try {
      const result = await getBusArrivals(stopId)
      set(state => ({
        busArrivals: { ...state.busArrivals, [stopId]: result },
        busLoading: false,
      }))
    } catch {
      set({ busLoading: false, busError: 'Bus data unavailable.' })
    }
  },

  setRegion: (region: Region) => {
    set({ region })
    get().fetchWeather(region)
  },

  selectSpot: (spot: Spot | null) => set({ selectedSpot: spot }),

  saveRoute: async (route: SavedRoute) => {
    const current = get().savedRoutes
    if (current.some(r => r.id === route.id)) return
    const updated = [route, ...current]
    set({ savedRoutes: updated })
    await AsyncStorage.setItem(SAVED_ROUTES_KEY, JSON.stringify(updated))
  },

  deleteRoute: async (id: string) => {
    const updated = get().savedRoutes.filter(r => r.id !== id)
    set({ savedRoutes: updated })
    await AsyncStorage.setItem(SAVED_ROUTES_KEY, JSON.stringify(updated))
  },

  loadSavedRoutes: async () => {
    try {
      const raw = await AsyncStorage.getItem(SAVED_ROUTES_KEY)
      if (raw) set({ savedRoutes: JSON.parse(raw) })
    } catch {}
  },

  getFilteredSpots: () => {
    const { region, weather } = get()
    const currentWeather = weather[region]
    const bad = currentWeather ? isBadWeather(currentWeather.condition) : false
    return SPOTS
      .filter(s => s.region === region)
      .filter(s => bad ? s.category !== 'outdoor' : true)
  },
}))

export { SPOTS }
