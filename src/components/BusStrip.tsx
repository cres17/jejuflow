import React from 'react'
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native'
import { COLORS } from '@/theme/colors'
import { formatKoreanWon } from '@/utils/timeUtils'
import { estimateTaxiPrice } from '@/utils/routeUtils'
import type { BusArrival } from '@/types'

interface Props {
  arrivals: BusArrival[]
  loading: boolean
  fromCache: boolean
  onRefresh: () => void
}

function minuteColor(min: number): string {
  if (min <= 5) return COLORS.green
  if (min <= 20) return COLORS.yellow
  return COLORS.text3
}

export function BusStrip({ arrivals, loading, fromCache, onRefresh }: Props) {
  const allLongWait = arrivals.length > 0 && arrivals.every(a => a.isLongWait)
  const avgWait = arrivals.length > 0
    ? Math.round(arrivals.reduce((s, a) => s + a.arrivalMinutes, 0) / arrivals.length)
    : 40
  const taxi = estimateTaxiPrice(avgWait)

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.sectionLabel}>BUS ARRIVALS</Text>
        <TouchableOpacity onPress={onRefresh} style={styles.refreshBtn} activeOpacity={0.7}>
          {loading
            ? <ActivityIndicator size="small" color={COLORS.text3} />
            : <Text style={styles.refreshText}>↻ Refresh</Text>
          }
        </TouchableOpacity>
      </View>

      {arrivals.length === 0 && !loading && (
        <Text style={styles.empty}>No bus data available.</Text>
      )}

      {arrivals.map((bus, i) => (
        <View key={i} style={styles.row}>
          <View style={styles.routeBadge}>
            <Text style={styles.routeNo}>{bus.routeNo}</Text>
          </View>
          <View style={styles.busInfo}>
            <Text style={styles.destination} numberOfLines={1}>{bus.destination}</Text>
            <Text style={styles.stops}>{bus.remainingStops} stops away</Text>
          </View>
          <Text style={[styles.minutes, { color: minuteColor(bus.arrivalMinutes) }]}>
            {bus.arrivalMinutes} min
          </Text>
        </View>
      ))}

      {fromCache && (
        <Text style={styles.cacheNote}>📡 Showing cached data</Text>
      )}

      {allLongWait && (
        <View style={styles.taxiRow}>
          <Text style={styles.taxiIcon}>🚕</Text>
          <View style={styles.taxiInfo}>
            <Text style={styles.taxiTitle}>Taxi recommended</Text>
            <Text style={styles.taxiDetail}>
              ~{taxi.minutes} min · {formatKoreanWon(taxi.minKrw)}–{formatKoreanWon(taxi.maxKrw)}
            </Text>
          </View>
        </View>
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 16,
    gap: 12,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  sectionLabel: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 10,
    letterSpacing: 1.5,
    color: COLORS.text3,
  },
  refreshBtn: { padding: 4 },
  refreshText: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 12,
    color: COLORS.text2,
  },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  routeBadge: {
    width: 44,
    height: 28,
    backgroundColor: COLORS.text1,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  routeNo: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 12,
    color: '#FFFFFF',
  },
  busInfo: { flex: 1 },
  destination: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 14,
    color: COLORS.text1,
  },
  stops: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 11,
    color: COLORS.text3,
    marginTop: 1,
  },
  minutes: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 16,
  },
  cacheNote: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 11,
    color: COLORS.text3,
  },
  taxiRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: COLORS.yellowBg,
    borderRadius: 10,
    padding: 10,
    marginTop: 4,
  },
  taxiIcon: { fontSize: 20 },
  taxiInfo: { gap: 2 },
  taxiTitle: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 13,
    color: '#8A6010',
  },
  taxiDetail: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: '#8A6010',
  },
  empty: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 14,
    color: COLORS.text2,
  },
})
