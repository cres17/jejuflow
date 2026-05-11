import React from 'react'
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native'
import { useRouter } from 'expo-router'
import { SafeAreaView } from 'react-native-safe-area-context'
import { useAppStore, SPOTS } from '@/store/appStore'
import { COLORS } from '@/theme/colors'
import { SavedRouteCard } from '@/components/SavedRouteCard'

export default function RoutesScreen() {
  const router = useRouter()
  const { savedRoutes, deleteRoute, selectSpot, weather, region } = useAppStore(s => ({
    savedRoutes:  s.savedRoutes,
    deleteRoute:  s.deleteRoute,
    selectSpot:   s.selectSpot,
    weather:      s.weather,
    region:       s.region,
  }))

  const currentWeather = weather[region]

  const handleUseRoute = (spotId: string) => {
    const spot = SPOTS.find(s => s.id === spotId)
    if (spot) {
      selectSpot(spot)
      router.push('/move')
    }
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.title}>Saved Routes</Text>
          <Text style={styles.subtitle}>
            {savedRoutes.length === 0 ? 'No saved routes yet' : `${savedRoutes.length} route${savedRoutes.length > 1 ? 's' : ''}`}
          </Text>
        </View>

        {savedRoutes.length === 0 ? (
          <View style={styles.emptyState}>
            <Text style={styles.emptyEmoji}>🗺</Text>
            <Text style={styles.emptyTitle}>No routes saved yet</Text>
            <Text style={styles.emptyBody}>
              Plan a route in the Move tab and save it here for quick access.
            </Text>
            <TouchableOpacity
              style={styles.ctaBtn}
              onPress={() => router.push('/move')}
              activeOpacity={0.8}
            >
              <Text style={styles.ctaBtnText}>Plan a Route</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.list}>
            {savedRoutes.map(route => (
              <SavedRouteCard
                key={route.id}
                route={route}
                currentWeather={currentWeather}
                onUse={() => handleUseRoute(route.spotId)}
                onDelete={() => deleteRoute(route.id)}
              />
            ))}
          </View>
        )}

        {savedRoutes.length > 0 && (
          <TouchableOpacity
            style={styles.newRouteBtn}
            onPress={() => router.push('/move')}
            activeOpacity={0.8}
          >
            <Text style={styles.newRouteBtnText}>＋ Plan a New Route</Text>
          </TouchableOpacity>
        )}
      </ScrollView>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  safe:    { flex: 1, backgroundColor: COLORS.bg },
  scroll:  { flex: 1 },
  content: { padding: 20, gap: 16, paddingBottom: 40 },
  header:  { gap: 2, marginBottom: 4 },
  title: {
    fontFamily: 'Outfit_800ExtraBold',
    fontSize: 26,
    color: COLORS.text1,
    letterSpacing: -0.8,
  },
  subtitle: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 13,
    color: COLORS.text2,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 60,
    gap: 12,
  },
  emptyEmoji: { fontSize: 48 },
  emptyTitle: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 20,
    color: COLORS.text1,
  },
  emptyBody: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 14,
    color: COLORS.text2,
    textAlign: 'center',
    maxWidth: 260,
    lineHeight: 20,
  },
  ctaBtn: {
    marginTop: 8,
    backgroundColor: COLORS.accent,
    borderRadius: 12,
    paddingHorizontal: 24,
    paddingVertical: 13,
  },
  ctaBtnText: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 15,
    color: '#FFFFFF',
  },
  list: { gap: 12 },
  newRouteBtn: {
    backgroundColor: COLORS.surface,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: COLORS.separator,
    marginTop: 4,
  },
  newRouteBtnText: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 14,
    color: COLORS.accent,
  },
})
