import { useEffect } from 'react'
import { Stack } from 'expo-router'
import {
  useFonts,
  Outfit_400Regular,
  Outfit_500Medium,
  Outfit_600SemiBold,
  Outfit_700Bold,
  Outfit_800ExtraBold,
} from '@expo-google-fonts/outfit'
import * as SplashScreen from 'expo-splash-screen'
import { useAppStore } from '@/store/appStore'

SplashScreen.preventAutoHideAsync()

export default function RootLayout() {
  const initApp = useAppStore(s => s.initApp)
  const [fontsLoaded] = useFonts({
    Outfit_400Regular,
    Outfit_500Medium,
    Outfit_600SemiBold,
    Outfit_700Bold,
    Outfit_800ExtraBold,
  })

  useEffect(() => {
    if (fontsLoaded) {
      initApp().finally(() => SplashScreen.hideAsync())
    }
  }, [fontsLoaded])

  if (!fontsLoaded) return null

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="spot/[id]" options={{ presentation: 'modal' }} />
    </Stack>
  )
}
