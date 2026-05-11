import { Tabs } from 'expo-router'
import { Text } from 'react-native'
import { useAppStore } from '@/store/appStore'
import { getTheme, COLORS } from '@/theme/colors'

export default function TabLayout() {
  const weather   = useAppStore(s => s.weather[s.region])
  const timeOfDay = useAppStore(s => s.timeOfDay)
  const theme     = weather ? getTheme(weather.condition, timeOfDay) : null
  const accent    = theme?.accent ?? COLORS.accent

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          height: 80,
          backgroundColor: COLORS.surface,
          borderTopColor: COLORS.separator,
          borderTopWidth: 1,
          paddingBottom: 16,
        },
        tabBarActiveTintColor: accent,
        tabBarInactiveTintColor: COLORS.text3,
        tabBarLabelStyle: {
          fontFamily: 'Outfit_700Bold',
          fontSize: 10,
          letterSpacing: 0.5,
        },
      }}
    >
      <Tabs.Screen
        name="now"
        options={{
          title: 'Now',
          tabBarIcon: ({ color }) => (
            <Text style={{ fontSize: 22, color }}>⚡</Text>
          ),
        }}
      />
      <Tabs.Screen
        name="move"
        options={{
          title: 'Move',
          tabBarIcon: ({ color }) => (
            <Text style={{ fontSize: 22, color }}>🗺</Text>
          ),
        }}
      />
      <Tabs.Screen
        name="routes"
        options={{
          title: 'Routes',
          tabBarIcon: ({ color }) => (
            <Text style={{ fontSize: 22, color }}>📋</Text>
          ),
        }}
      />
    </Tabs>
  )
}
