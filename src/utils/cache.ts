import AsyncStorage from '@react-native-async-storage/async-storage'

interface CacheEntry<T> {
  data: T
  cachedAt: number
}

export async function fetchWithCache<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttlMs: number
): Promise<{ data: T; fromCache: boolean }> {
  try {
    const raw = await AsyncStorage.getItem(key)
    if (raw) {
      const entry: CacheEntry<T> = JSON.parse(raw)
      if (Date.now() - entry.cachedAt < ttlMs) {
        return { data: entry.data, fromCache: false }
      }
    }
  } catch {
    // AsyncStorage read failure — proceed to fetch
  }

  try {
    const data = await fetcher()
    const entry: CacheEntry<T> = { data, cachedAt: Date.now() }
    await AsyncStorage.setItem(key, JSON.stringify(entry))
    return { data, fromCache: false }
  } catch {
    try {
      const stale = await AsyncStorage.getItem(key)
      if (stale) {
        const entry: CacheEntry<T> = JSON.parse(stale)
        return { data: entry.data, fromCache: true }
      }
    } catch {}
    throw new Error(`No data available for key: ${key}`)
  }
}
