import React, { useEffect, useState } from 'react'
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  RefreshControl,
  TouchableOpacity,
  StatusBar,
} from 'react-native'
import { useRouter } from 'expo-router'
import { SafeAreaView } from 'react-native-safe-area-context'
import { useAppStore } from '@/store/appStore'
import { getTheme, COLORS } from '@/theme/colors'
import { isBadWeather } from '@/utils/weatherUtils'
import { SituationCard } from '@/components/SituationCard'
import { AnswerSpots } from '@/components/AnswerSpots'
import { BusStrip } from '@/components/BusStrip'
import { WeatherBanner } from '@/components/WeatherBanner'
import type { Spot } from '@/types'

export default function NowScreen() {
  const router = useRouter()
  const {
    weather, region, weatherLoading, busArrivals, busLoading,
    fetchWeather, fetchBusArrivals, getFilteredSpots, selectSpot, timeOfDay,
    setRegion,
  } = useAppStore(s => ({
    weather:          s.weather,
    region:           s.region,
    weatherLoading:   s.weatherLoading,
    busArrivals:      s.busArrivals,
    busLoading:       s.busLoading,
    fetchWeather:     s.fetchWeather,
    fetchBusArrivals: s.fetchBusArrivals,
    getFilteredSpots: s.getFilteredSpots,
    selectSpot:       s.selectSpot,
    timeOfDay:        s.timeOfDay,
    setRegion:        s.setRegion,
  }))

  const [refreshing, setRefreshing] = useState(false)
  const [bannerDismissed, setBannerDismissed] = useState(false)

  const currentWeather = weather[region]
  const spots          = getFilteredSpots().slice(0, 3)
  const nearestStopId  = spots[0]?.stopId ?? null
  const currentBus     = nearestStopId ? busArrivals[nearestStopId] : null
  const theme          = currentWeather ? getTheme(currentWeather.condition, timeOfDay) : null
  const accent         = theme?.accent ?? COLORS.accent
  const showBanner     = !!currentWeather && isBadWeather(currentWeather.condition) && !bannerDismissed

  useEffect(() => {
    if (nearestStopId) fetchBusArrivals(nearestStopId)
  }, [nearestStopId, region])

  useEffect(() => {
    if (!isBadWeather(currentWeather?.condition)) {
      setBannerDismissed(false)
    }
  }, [currentWeather?.condition])

  const onRefresh = async () => {
    setRefreshing(true)
    await Promise.allSettled([
      fetchWeather(region),
      nearestStopId ? fetchBusArrivals(nearestStopId) : Promise.resolve(),
    ])
    setRefreshing(false)
  }

  const handleSpotSelect = (spot: Spot) => {
    selectSpot(spot)
    router.push('/move')
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <StatusBar barStyle="light-content" />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={accent}
          />
        }
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <View>
            <Text style={styles.appName}>JejuFlow</Text>
            <Text style={styles.tagline}>Where to go right now?</Text>
          </View>
          <TouchableOpacity
            style={styles.regionToggle}
            onPress={() => setRegion(region === 'jeju-city' ? 'seogwipo' : 'jeju-city')}
            activeOpacity={0.7}
          >
            <Text style={styles.regionText}>
              {region === 'jeju-city' ? '🏙 Jeju City' : '🌊 Seogwipo'}
            </Text>
          </TouchableOpacity>
        </View>

        {showBanner && currentWeather && (
          <WeatherBanner
            condition={currentWeather.condition}
            visible={showBanner}
            onSwitch={() => {
              setBannerDismissed(true)
              router.push('/move')
            }}
            onDismiss={() => setBannerDismissed(true)}
          />
        )}

        <SituationCard
          weather={currentWeather}
          region={region}
          accent={accent}
          loading={weatherLoading}
        />

        <AnswerSpots spots={spots} onSelect={handleSpotSelect} />

        {currentBus && (
          <BusStrip
            arrivals={currentBus.arrivals}
            loading={busLoading}
            fromCache={currentBus.fromCache}
            onRefresh={() => nearestStopId && fetchBusArrivals(nearestStopId)}
          />
        )}
      </ScrollView>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  scroll: { flex: 1 },
  content: { padding: 20, gap: 16, paddingBottom: 40 },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 4,
  },
  appName: {
    fontFamily: 'Outfit_800ExtraBold',
    fontSize: 26,
    color: COLORS.text1,
    letterSpacing: -0.8,
  },
  tagline: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 13,
    color: COLORS.text2,
    marginTop: 2,
  },
  regionToggle: {
    backgroundColor: COLORS.surface,
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderWidth: 1,
    borderColor: COLORS.separator,
  },
  regionText: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 13,
    color: COLORS.text1,
  },
})
