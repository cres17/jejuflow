import React from 'react'
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native'
import { COLORS } from '@/theme/colors'
import { formatKoreanWon } from '@/utils/timeUtils'
import { isBadWeather } from '@/utils/weatherUtils'
import { SPOTS } from '@/store/appStore'
import type { SavedRoute, WeatherData } from '@/types'

interface Props {
  route: SavedRoute
  currentWeather: WeatherData | null
  onUse: () => void
  onDelete: () => void
}

export function SavedRouteCard({ route, currentWeather, onUse, onDelete }: Props) {
  const spot = SPOTS.find(s => s.id === route.spotId)
  const isOutdoor = spot?.category === 'outdoor'
  const weatherAffected = isOutdoor && currentWeather && isBadWeather(currentWeather.condition)

  const savedDate = new Date(route.savedAt)
  const dateStr = `${savedDate.getMonth() + 1}/${savedDate.getDate()} ${String(savedDate.getHours()).padStart(2, '0')}:${String(savedDate.getMinutes()).padStart(2, '0')}`

  return (
    <View style={styles.card}>
      <View style={[styles.header, { backgroundColor: route.accent }]}>
        <View style={styles.headerLeft}>
          <Text style={styles.spotEmoji}>{route.spotEmoji}</Text>
          <View>
            <Text style={styles.spotName}>{route.spotName}</Text>
            <Text style={styles.savedDate}>Saved {dateStr}</Text>
          </View>
        </View>
        {weatherAffected && (
          <View style={styles.alertBadge}>
            <Text style={styles.alertText}>⚠️</Text>
          </View>
        )}
      </View>

      <View style={styles.body}>
        <View style={styles.metaRow}>
          <View style={styles.metaItem}>
            <Text style={styles.metaLabel}>TOTAL</Text>
            <Text style={styles.metaValue}>{route.totalMinutes} min</Text>
          </View>
          <View style={styles.metaDivider} />
          <View style={styles.metaItem}>
            <Text style={styles.metaLabel}>ENTRY</Text>
            <Text style={styles.metaValue}>{formatKoreanWon(route.fee)}</Text>
          </View>
          <View style={styles.metaDivider} />
          <View style={styles.metaItem}>
            <Text style={styles.metaLabel}>STOPS</Text>
            <Text style={styles.metaValue}>{route.steps.length}</Text>
          </View>
        </View>

        {weatherAffected && (
          <View style={styles.warningRow}>
            <Text style={styles.warningText}>
              ⚠️ Weather may affect this outdoor spot
            </Text>
          </View>
        )}

        <View style={styles.actions}>
          <TouchableOpacity
            style={[styles.useBtn, { backgroundColor: route.accent }]}
            onPress={onUse}
            activeOpacity={0.8}
          >
            <Text style={styles.useText}>Use Now</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={onDelete} style={styles.deleteBtn} activeOpacity={0.7}>
            <Text style={styles.deleteText}>Delete</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
  },
  headerLeft: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  spotEmoji: { fontSize: 28 },
  spotName: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 16,
    color: '#FFFFFF',
  },
  savedDate: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 11,
    color: 'rgba(255,255,255,0.7)',
    marginTop: 1,
  },
  alertBadge: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(0,0,0,0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  alertText: { fontSize: 16 },
  body: { padding: 16, gap: 12 },
  metaRow: { flexDirection: 'row', alignItems: 'center' },
  metaItem: { flex: 1, alignItems: 'center', gap: 2 },
  metaLabel: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 9,
    letterSpacing: 1.5,
    color: COLORS.text3,
  },
  metaValue: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 15,
    color: COLORS.text1,
  },
  metaDivider: { width: 1, height: 28, backgroundColor: COLORS.separator },
  warningRow: {
    backgroundColor: COLORS.yellowBg,
    borderRadius: 8,
    padding: 10,
  },
  warningText: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: '#8A6010',
  },
  actions: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  useBtn: {
    flex: 1,
    borderRadius: 10,
    paddingVertical: 11,
    alignItems: 'center',
  },
  useText: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 14,
    color: '#FFFFFF',
  },
  deleteBtn: { padding: 11 },
  deleteText: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 13,
    color: COLORS.text3,
  },
})
