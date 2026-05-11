import React from 'react'
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native'
import { COLORS } from '@/theme/colors'
import { formatArrivalTime, formatKoreanWon } from '@/utils/timeUtils'
import type { Spot } from '@/types'

interface Props {
  spots: Spot[]
  onSelect: (spot: Spot) => void
}

function arrivalColor(minutes: number): string {
  if (minutes <= 15) return COLORS.green
  if (minutes <= 30) return COLORS.yellow
  return COLORS.text3
}

export function AnswerSpots({ spots, onSelect }: Props) {
  if (spots.length === 0) {
    return (
      <View style={styles.empty}>
        <Text style={styles.emptyText}>No spots available for current conditions.</Text>
      </View>
    )
  }

  return (
    <View style={styles.container}>
      <Text style={styles.sectionLabel}>GO NOW</Text>
      {spots.map((spot, i) => {
        const totalMin = spot.busWaitMinutes + spot.walkMinutes
        const color = arrivalColor(totalMin)
        return (
          <TouchableOpacity
            key={spot.id}
            style={styles.card}
            activeOpacity={0.75}
            onPress={() => onSelect(spot)}
          >
            <View style={[styles.palette, { backgroundColor: spot.palette.bg }]}>
              <Text style={styles.emoji}>{spot.emoji}</Text>
            </View>
            <View style={styles.info}>
              <Text style={styles.name} numberOfLines={1}>{spot.name_en}</Text>
              <Text style={styles.sub} numberOfLines={1}>{spot.sub}</Text>
              <View style={styles.metaRow}>
                <Text style={[styles.arrival, { color }]}>
                  Arrive ~{formatArrivalTime(totalMin)}
                </Text>
                <Text style={styles.fee}>{formatKoreanWon(spot.fee)}</Text>
              </View>
            </View>
            <View style={styles.rank}>
              <Text style={styles.rankNum}>{i + 1}</Text>
            </View>
          </TouchableOpacity>
        )
      })}
    </View>
  )
}

const styles = StyleSheet.create({
  container: { gap: 10 },
  sectionLabel: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 10,
    letterSpacing: 1.5,
    color: COLORS.text3,
    marginBottom: 2,
  },
  card: {
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
  palette: {
    width: 72,
    height: 80,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emoji: { fontSize: 28 },
  info: { flex: 1, paddingHorizontal: 14, paddingVertical: 12, gap: 3 },
  name: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 15,
    color: COLORS.text1,
  },
  sub: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: COLORS.text2,
  },
  metaRow: { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 4 },
  arrival: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 12,
  },
  fee: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: COLORS.text3,
  },
  rank: {
    width: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rankNum: {
    fontFamily: 'Outfit_800ExtraBold',
    fontSize: 22,
    color: COLORS.separator,
  },
  empty: {
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
  },
  emptyText: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 14,
    color: COLORS.text2,
  },
})
