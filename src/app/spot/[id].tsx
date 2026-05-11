import React from 'react'
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Platform,
} from 'react-native'
import { useLocalSearchParams, useRouter } from 'expo-router'
import { SafeAreaView } from 'react-native-safe-area-context'
import { SPOTS } from '@/store/appStore'
import { useAppStore } from '@/store/appStore'
import { COLORS } from '@/theme/colors'
import { formatKoreanWon } from '@/utils/timeUtils'

export default function SpotDetailScreen() {
  const { id }     = useLocalSearchParams<{ id: string }>()
  const router     = useRouter()
  const selectSpot = useAppStore(s => s.selectSpot)

  const spot = SPOTS.find(s => s.id === id)

  if (!spot) {
    return (
      <SafeAreaView style={styles.safe} edges={['top']}>
        <View style={styles.notFound}>
          <Text style={styles.notFoundText}>Spot not found.</Text>
          <TouchableOpacity onPress={() => router.back()}>
            <Text style={styles.backLink}>← Go Back</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    )
  }

  const handlePlanRoute = () => {
    selectSpot(spot)
    router.push('/move')
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom']}>
      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <View style={[styles.heroHeader, { backgroundColor: spot.palette.bg }]}>
          <TouchableOpacity style={styles.closeBtn} onPress={() => router.back()}>
            <Text style={styles.closeText}>✕</Text>
          </TouchableOpacity>
          <Text style={styles.heroEmoji}>{spot.emoji}</Text>
          <Text style={styles.heroName}>{spot.name_en}</Text>
          <Text style={styles.heroSub}>{spot.sub}</Text>
        </View>

        <View style={styles.body}>
          <View style={styles.metaGrid}>
            <View style={styles.metaCell}>
              <Text style={styles.metaLabel}>HOURS</Text>
              <Text style={styles.metaValue}>{spot.hours}</Text>
            </View>
            <View style={styles.metaCell}>
              <Text style={styles.metaLabel}>ENTRY</Text>
              <Text style={styles.metaValue}>{formatKoreanWon(spot.fee)}</Text>
            </View>
            <View style={styles.metaCell}>
              <Text style={styles.metaLabel}>WALK</Text>
              <Text style={styles.metaValue}>{spot.walkMinutes} min</Text>
            </View>
            <View style={styles.metaCell}>
              <Text style={styles.metaLabel}>BUS</Text>
              <Text style={styles.metaValue}>{spot.busRoutes.join(', ')}</Text>
            </View>
          </View>

          <View style={styles.tagsRow}>
            {spot.tags.map(tag => (
              <View key={tag} style={styles.tag}>
                <Text style={styles.tagText}>{tag}</Text>
              </View>
            ))}
          </View>

          <View style={styles.stopInfo}>
            <Text style={styles.stopLabel}>Nearest Bus Stop</Text>
            <Text style={styles.stopName}>{spot.nearestStop}</Text>
            <Text style={styles.stopId}>Stop ID: {spot.stopId}</Text>
          </View>

          {Platform.OS !== 'web' ? (
            <View style={styles.mapPlaceholder}>
              <Text style={styles.mapPlaceholderText}>
                📍 {spot.lat.toFixed(4)}, {spot.lng.toFixed(4)}
              </Text>
              <Text style={styles.mapNote}>Map available on device</Text>
            </View>
          ) : (
            <View style={styles.mapPlaceholder}>
              <Text style={styles.mapPlaceholderText}>
                📍 {spot.lat.toFixed(4)}, {spot.lng.toFixed(4)}
              </Text>
            </View>
          )}

          <TouchableOpacity
            style={[styles.planBtn, { backgroundColor: spot.palette.accent }]}
            onPress={handlePlanRoute}
            activeOpacity={0.8}
          >
            <Text style={styles.planBtnText}>Plan Route to {spot.name_en}</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  safe:    { flex: 1, backgroundColor: COLORS.bg },
  content: { paddingBottom: 40 },
  notFound: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12 },
  notFoundText: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 16,
    color: COLORS.text2,
  },
  backLink: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 14,
    color: COLORS.accent,
  },
  heroHeader: {
    alignItems: 'center',
    paddingTop: 60,
    paddingBottom: 40,
    paddingHorizontal: 24,
    gap: 8,
  },
  closeBtn: {
    position: 'absolute',
    top: 16,
    right: 20,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255,255,255,0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeText: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 14,
    color: '#FFFFFF',
  },
  heroEmoji: { fontSize: 52 },
  heroName: {
    fontFamily: 'Outfit_800ExtraBold',
    fontSize: 26,
    color: '#FFFFFF',
    textAlign: 'center',
    letterSpacing: -0.5,
  },
  heroSub: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 14,
    color: 'rgba(255,255,255,0.7)',
    textAlign: 'center',
  },
  body: { padding: 20, gap: 16 },
  metaGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    overflow: 'hidden',
  },
  metaCell: {
    width: '50%',
    padding: 16,
    gap: 4,
    borderBottomWidth: 1,
    borderRightWidth: 1,
    borderColor: COLORS.separator,
  },
  metaLabel: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 9,
    letterSpacing: 1.5,
    color: COLORS.text3,
  },
  metaValue: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 14,
    color: COLORS.text1,
  },
  tagsRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  tag: {
    backgroundColor: COLORS.surface2,
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 5,
  },
  tagText: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 12,
    color: COLORS.text2,
  },
  stopInfo: {
    backgroundColor: COLORS.surface,
    borderRadius: 14,
    padding: 16,
    gap: 3,
  },
  stopLabel: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 10,
    letterSpacing: 1.5,
    color: COLORS.text3,
  },
  stopName: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 16,
    color: COLORS.text1,
    marginTop: 2,
  },
  stopId: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: COLORS.text3,
  },
  mapPlaceholder: {
    backgroundColor: COLORS.surface2,
    borderRadius: 14,
    height: 100,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  mapPlaceholderText: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 14,
    color: COLORS.text2,
  },
  mapNote: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: COLORS.text3,
  },
  planBtn: {
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 4,
  },
  planBtnText: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 15,
    color: '#FFFFFF',
  },
})
