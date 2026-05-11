import * as Location from 'expo-location'
import type { Region } from '@/types'

export async function detectRegion(): Promise<Region> {
  try {
    const { status } = await Location.requestForegroundPermissionsAsync()
    if (status !== 'granted') return 'jeju-city'

    const loc = await Location.getCurrentPositionAsync({
      accuracy: Location.Accuracy.Balanced,
    })

    return loc.coords.latitude < 33.38 ? 'seogwipo' : 'jeju-city'
  } catch {
    return 'jeju-city'
  }
}
