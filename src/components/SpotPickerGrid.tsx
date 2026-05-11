import React from 'react'
import { View, Text, StyleSheet, TouchableOpacity, FlatList } from 'react-native'
import { COLORS } from '@/theme/colors'
import type { Spot } from '@/types'

interface Props {
  spots: Spot[]
  selectedId: string | null
  onSelect: (spot: Spot) => void
}

export function SpotPickerGrid({ spots, selectedId, onSelect }: Props) {
  return (
    <FlatList
      data={spots}
      numColumns={2}
      scrollEnabled={false}
      columnWrapperStyle={styles.row}
      keyExtractor={item => item.id}
      renderItem={({ item }) => {
        const selected = item.id === selectedId
        return (
          <TouchableOpacity
            style={[
              styles.cell,
              selected && { borderColor: item.palette.accent, borderWidth: 2 },
            ]}
            activeOpacity={0.75}
            onPress={() => onSelect(item)}
          >
            <View style={[styles.emojiBox, { backgroundColor: item.palette.bg }]}>
              <Text style={styles.emoji}>{item.emoji}</Text>
            </View>
            <View style={styles.textBox}>
              <Text style={styles.name} numberOfLines={2}>{item.name_en}</Text>
              <Text style={styles.sub} numberOfLines={1}>{item.sub}</Text>
            </View>
          </TouchableOpacity>
        )
      }}
    />
  )
}

const styles = StyleSheet.create({
  row: { gap: 10, marginBottom: 10 },
  cell: {
    flex: 1,
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    overflow: 'hidden',
    borderColor: 'transparent',
    borderWidth: 2,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  emojiBox: {
    height: 80,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emoji: { fontSize: 32 },
  textBox: { padding: 10, gap: 2 },
  name: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 13,
    color: COLORS.text1,
    lineHeight: 18,
  },
  sub: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 11,
    color: COLORS.text2,
  },
})
