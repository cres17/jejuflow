import React from 'react'
import { View, Text, StyleSheet } from 'react-native'
import { COLORS } from '@/theme/colors'
import type { RouteStep } from '@/types'

interface Props {
  steps: RouteStep[]
  accent: string
}

export function RouteSteps({ steps, accent }: Props) {
  return (
    <View style={styles.container}>
      {steps.map((step, i) => {
        const isFirst = i === 0
        const isLast  = i === steps.length - 1
        const showLine = !isLast
        return (
          <View key={i} style={styles.stepRow}>
            <View style={styles.timeline}>
              <View style={[
                styles.dot,
                (isFirst || isLast)
                  ? { backgroundColor: accent, width: 14, height: 14, borderRadius: 7 }
                  : { borderColor: accent, borderWidth: 2, backgroundColor: '#FFF' },
              ]} />
              {showLine && <View style={[styles.line, { backgroundColor: COLORS.separator }]} />}
            </View>
            <View style={[styles.content, !isLast && { paddingBottom: 24 }]}>
              <View style={styles.stepHeader}>
                <Text style={styles.stepIcon}>{step.icon}</Text>
                <Text style={styles.stepMain}>{step.main}</Text>
                {step.durationMinutes > 0 && (
                  <View style={[styles.durationBadge, { backgroundColor: accent + '20' }]}>
                    <Text style={[styles.durationText, { color: accent }]}>
                      {step.durationMinutes} min
                    </Text>
                  </View>
                )}
              </View>
              <Text style={styles.stepDetail}>{step.detail}</Text>
            </View>
          </View>
        )
      })}
    </View>
  )
}

const styles = StyleSheet.create({
  container: { gap: 0 },
  stepRow: { flexDirection: 'row', gap: 14 },
  timeline: { alignItems: 'center', width: 14 },
  dot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: COLORS.separator,
    marginTop: 3,
  },
  line: {
    width: 2,
    flex: 1,
    marginTop: 4,
  },
  content: { flex: 1, paddingBottom: 0 },
  stepHeader: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  stepIcon: { fontSize: 16 },
  stepMain: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 14,
    color: COLORS.text1,
    flex: 1,
  },
  durationBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 20,
  },
  durationText: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 11,
  },
  stepDetail: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: COLORS.text2,
    marginTop: 3,
    marginLeft: 24,
  },
})
