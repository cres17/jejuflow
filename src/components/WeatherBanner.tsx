import React, { useEffect, useRef } from 'react'
import { View, Text, StyleSheet, TouchableOpacity, Animated } from 'react-native'
import { WEATHER_WARNINGS } from '@/utils/weatherUtils'
import type { WeatherCondition } from '@/types'

interface Props {
  condition: WeatherCondition
  visible: boolean
  onSwitch: () => void
  onDismiss: () => void
}

export function WeatherBanner({ condition, visible, onSwitch, onDismiss }: Props) {
  const translateY = useRef(new Animated.Value(-80)).current
  const opacity    = useRef(new Animated.Value(0)).current

  useEffect(() => {
    Animated.parallel([
      Animated.spring(translateY, {
        toValue: visible ? 0 : -80,
        useNativeDriver: true,
        tension: 80,
        friction: 12,
      }),
      Animated.timing(opacity, {
        toValue: visible ? 1 : 0,
        duration: 200,
        useNativeDriver: true,
      }),
    ]).start()
  }, [visible])

  const warning = WEATHER_WARNINGS[condition]
  if (!warning) return null

  return (
    <Animated.View style={[styles.banner, { transform: [{ translateY }], opacity }]}>
      <Text style={styles.text}>{warning}</Text>
      <View style={styles.actions}>
        <TouchableOpacity style={styles.switchBtn} onPress={onSwitch} activeOpacity={0.8}>
          <Text style={styles.switchText}>Switch Route</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={onDismiss} activeOpacity={0.7}>
          <Text style={styles.dismissText}>Keep</Text>
        </TouchableOpacity>
      </View>
    </Animated.View>
  )
}

const styles = StyleSheet.create({
  banner: {
    backgroundColor: '#FEF6E4',
    borderRadius: 14,
    padding: 14,
    gap: 10,
    shadowColor: '#000',
    shadowOpacity: 0.08,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  text: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 13,
    color: '#8A6010',
    lineHeight: 18,
  },
  actions: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  switchBtn: {
    backgroundColor: '#C8920A',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 7,
  },
  switchText: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 12,
    color: '#FFFFFF',
  },
  dismissText: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 12,
    color: '#8A6010',
  },
})
