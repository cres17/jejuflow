import React from 'react'
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native'
import { COLORS } from '@/theme/colors'
import {
  WEATHER_ICONS,
  WEATHER_LABELS,
  WEATHER_ADVICE,
  WEATHER_WARNINGS,
  formatUpdatedAt,
} from '@/utils/weatherUtils'
import type { WeatherData, Region } from '@/types'

interface Props {
  weather: WeatherData | null
  region: Region
  accent: string
  loading: boolean
}

export function SituationCard({ weather, region, accent, loading }: Props) {
  const regionLabel = region === 'jeju-city' ? 'Jeju City' : 'Seogwipo'

  if (loading && !weather) {
    return (
      <View style={[styles.card, { borderLeftColor: accent }]}>
        <ActivityIndicator color={accent} />
      </View>
    )
  }

  if (!weather) {
    return (
      <View style={[styles.card, { borderLeftColor: accent }]}>
        <Text style={styles.label}>WEATHER</Text>
        <Text style={styles.advice}>Loading weather data...</Text>
      </View>
    )
  }

  const warning = WEATHER_WARNINGS[weather.condition]

  return (
    <View style={styles.wrapper}>
      <View style={[styles.card, { borderLeftColor: accent }]}>
        <View style={styles.row}>
          <View style={styles.left}>
            <Text style={styles.label}>NOW IN {regionLabel.toUpperCase()}</Text>
            <View style={styles.conditionRow}>
              <Text style={styles.icon}>{WEATHER_ICONS[weather.condition]}</Text>
              <Text style={[styles.condition, { color: accent }]}>
                {WEATHER_LABELS[weather.condition]}
              </Text>
            </View>
            {weather.temperature && (
              <Text style={styles.temp}>{weather.temperature}</Text>
            )}
            <Text style={styles.wind}>{weather.wind.toFixed(1)} m/s wind</Text>
          </View>
          <View style={styles.right}>
            <Text style={styles.updated}>
              {weather.fromCache ? '📡 Cached' : '🔴 Live'}
            </Text>
            <Text style={styles.updatedTime}>
              {formatUpdatedAt(weather.updatedAt)}
            </Text>
          </View>
        </View>
        <Text style={styles.advice}>{WEATHER_ADVICE[weather.condition]}</Text>
      </View>
      {warning && (
        <View style={[styles.warningBanner, { backgroundColor: '#FEF6E4' }]}>
          <Text style={styles.warningText}>{warning}</Text>
        </View>
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  wrapper: { gap: 8 },
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 20,
    borderLeftWidth: 4,
    gap: 12,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  left: { gap: 4 },
  right: { alignItems: 'flex-end' },
  label: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 10,
    letterSpacing: 1.5,
    color: COLORS.text3,
  },
  conditionRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 2 },
  icon: { fontSize: 22 },
  condition: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 22,
    letterSpacing: -0.3,
  },
  temp: {
    fontFamily: 'Outfit_800ExtraBold',
    fontSize: 32,
    color: COLORS.text1,
    letterSpacing: -1,
    marginTop: 2,
  },
  wind: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 13,
    color: COLORS.text2,
  },
  updated: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 11,
    color: COLORS.text3,
  },
  updatedTime: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 11,
    color: COLORS.text3,
    marginTop: 2,
  },
  advice: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 14,
    color: COLORS.text2,
    lineHeight: 20,
  },
  warningBanner: {
    borderRadius: 12,
    padding: 12,
  },
  warningText: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 13,
    color: '#8A6010',
  },
})
