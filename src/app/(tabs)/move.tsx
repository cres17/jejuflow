import React, { useEffect, useState } from 'react'
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { useAppStore, SPOTS } from '@/store/appStore'
import { COLORS } from '@/theme/colors'
import { isBadWeather, WEATHER_WARNINGS } from '@/utils/weatherUtils'
import { formatKoreanWon } from '@/utils/timeUtils'
import { buildRouteSteps, computeTotalMinutes, buildSavedRoute, estimateTaxiPrice } from '@/utils/routeUtils'
import { SpotPickerGrid } from '@/components/SpotPickerGrid'
import { RouteSteps } from '@/components/RouteSteps'
import type { Spot } from '@/types'

export default function MoveScreen() {
  const {
    selectedSpot, selectSpot, region, weather, busArrivals,
    fetchBusArrivals, saveRoute,
  } = useAppStore(s => ({
    selectedSpot:     s.selectedSpot,
    selectSpot:       s.selectSpot,
    region:           s.region,
    weather:          s.weather,
    busArrivals:      s.busArrivals,
    fetchBusArrivals: s.fetchBusArrivals,
    saveRoute:        s.saveRoute,
  }))

  const [saved, setSaved] = useState(false)

  const allSpots    = SPOTS
  const currentWeather = weather[region]
  const arrival     = selectedSpot ? busArrivals[selectedSpot.stopId] : null
  const firstBus    = arrival?.arrivals[0] ?? null
  const steps       = selectedSpot ? buildRouteSteps(selectedSpot, firstBus) : []
  const totalMin    = selectedSpot ? computeTotalMinutes(selectedSpot, firstBus) : 0
  const taxi        = totalMin > 0 ? estimateTaxiPrice(totalMin) : null
  const showTaxi    = firstBus?.isLongWait ?? false
  const isOutdoor   = selectedSpot?.category === 'outdoor'
  const weatherBad  = currentWeather ? isBadWeather(currentWeather.condition) : false
  const showWarning = isOutdoor && weatherBad

  useEffect(() => {
    if (selectedSpot) {
      fetchBusArrivals(selectedSpot.stopId)
      setSaved(false)
    }
  }, [selectedSpot?.id])

  const handleSave = async () => {
    if (!selectedSpot) return
    const route = buildSavedRoute(selectedSpot, firstBus)
    await saveRoute(route)
    setSaved(true)
    Alert.alert('Route Saved', `${selectedSpot.name_en} added to your routes.`)
  }

  const handleSelectSpot = (spot: Spot) => {
    selectSpot(spot)
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.title}>Plan Your Move</Text>
          <Text style={styles.subtitle}>Pick a destination</Text>
        </View>

        {!selectedSpot ? (
          <SpotPickerGrid
            spots={allSpots}
            selectedId={null}
            onSelect={handleSelectSpot}
          />
        ) : (
          <View style={styles.routeContainer}>
            <TouchableOpacity
              style={styles.selectedHeader}
              onPress={() => selectSpot(null)}
              activeOpacity={0.8}
            >
              <View style={[styles.spotPalette, { backgroundColor: selectedSpot.palette.bg }]}>
                <Text style={styles.spotEmoji}>{selectedSpot.emoji}</Text>
              </View>
              <View style={styles.spotInfo}>
                <Text style={styles.spotName}>{selectedSpot.name_en}</Text>
                <Text style={styles.spotSub}>{selectedSpot.sub}</Text>
              </View>
              <Text style={styles.changeBtn}>Change ›</Text>
            </TouchableOpacity>

            {showWarning && currentWeather && (
              <View style={styles.warningBox}>
                <Text style={styles.warningText}>
                  {WEATHER_WARNINGS[currentWeather.condition] ?? '⚠️ Weather may affect this spot'}
                </Text>
              </View>
            )}

            <View style={[styles.routeCard, { borderTopColor: selectedSpot.palette.accent, borderTopWidth: 3 }]}>
              <View style={styles.routeHeader}>
                <Text style={styles.routeLabel}>ROUTE</Text>
                <Text style={[styles.totalTime, { color: selectedSpot.palette.accent }]}>
                  ~{totalMin} min total
                </Text>
              </View>
              <RouteSteps steps={steps} accent={selectedSpot.palette.accent} />
            </View>

            {showTaxi && taxi && (
              <View style={styles.taxiBox}>
                <Text style={styles.taxiTitle}>🚕 Taxi alternative</Text>
                <Text style={styles.taxiDetail}>
                  ~{taxi.minutes} min · {formatKoreanWon(taxi.minKrw)}–{formatKoreanWon(taxi.maxKrw)}
                </Text>
              </View>
            )}

            <View style={styles.feeRow}>
              <Text style={styles.feeLabel}>Entry fee</Text>
              <Text style={styles.feeValue}>{formatKoreanWon(selectedSpot.fee)}</Text>
            </View>

            <TouchableOpacity
              style={[
                styles.saveBtn,
                { backgroundColor: saved ? COLORS.text3 : selectedSpot.palette.accent },
              ]}
              onPress={handleSave}
              disabled={saved}
              activeOpacity={0.8}
            >
              <Text style={styles.saveBtnText}>
                {saved ? '✓ Route Saved' : 'Save This Route'}
              </Text>
            </TouchableOpacity>
          </View>
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
  routeContainer: { gap: 14 },
  selectedHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  spotPalette: {
    width: 72,
    height: 72,
    alignItems: 'center',
    justifyContent: 'center',
  },
  spotEmoji: { fontSize: 28 },
  spotInfo: { flex: 1, paddingHorizontal: 14 },
  spotName: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 15,
    color: COLORS.text1,
  },
  spotSub: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: COLORS.text2,
    marginTop: 2,
  },
  changeBtn: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 13,
    color: COLORS.text3,
    paddingRight: 16,
  },
  warningBox: {
    backgroundColor: COLORS.yellowBg,
    borderRadius: 12,
    padding: 12,
  },
  warningText: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 13,
    color: '#8A6010',
  },
  routeCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 20,
    gap: 16,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  routeHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  routeLabel: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 10,
    letterSpacing: 1.5,
    color: COLORS.text3,
  },
  totalTime: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 15,
  },
  taxiBox: {
    backgroundColor: COLORS.yellowBg,
    borderRadius: 12,
    padding: 14,
    gap: 4,
  },
  taxiTitle: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 14,
    color: '#8A6010',
  },
  taxiDetail: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 13,
    color: '#8A6010',
  },
  feeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 14,
  },
  feeLabel: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 14,
    color: COLORS.text2,
  },
  feeValue: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 15,
    color: COLORS.text1,
  },
  saveBtn: {
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
  },
  saveBtnText: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 16,
    color: '#FFFFFF',
  },
})
