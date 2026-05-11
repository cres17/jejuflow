import { StyleSheet } from 'react-native'

export const FONT_FAMILY = {
  regular:   'Outfit_400Regular',
  medium:    'Outfit_500Medium',
  semiBold:  'Outfit_600SemiBold',
  bold:      'Outfit_700Bold',
  extraBold: 'Outfit_800ExtraBold',
}

export const TEXT = StyleSheet.create({
  h1: {
    fontFamily: 'Outfit_800ExtraBold',
    fontSize: 28,
    letterSpacing: -0.7,
    color: '#111110',
  },
  h2: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 20,
    letterSpacing: -0.3,
    color: '#111110',
  },
  h3: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 17,
    color: '#111110',
  },
  body: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 15,
    color: '#111110',
  },
  bodyBold: {
    fontFamily: 'Outfit_600SemiBold',
    fontSize: 15,
    color: '#111110',
  },
  small: {
    fontFamily: 'Outfit_400Regular',
    fontSize: 12,
    color: '#6B6860',
  },
  smallBold: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 11,
    letterSpacing: 0.5,
    color: '#B0ADA6',
  },
  label: {
    fontFamily: 'Outfit_700Bold',
    fontSize: 11,
    letterSpacing: 1.2,
    color: '#B0ADA6',
  },
})
