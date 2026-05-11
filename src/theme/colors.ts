import type { WeatherCondition, TimeOfDay } from '@/types'

export interface Theme {
  bg1: string
  bg2: string
  accent: string
  surface: string
  text1: string
  text2: string
  text3: string
  separator: string
}

type ThemeKey = `${WeatherCondition}-${TimeOfDay}`

export const WEATHER_THEMES: Record<ThemeKey, Theme> = {
  'clear-morning':    { bg1: '#0F2A12', bg2: '#060E07', accent: '#2A7A4A', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'clear-noon':       { bg1: '#003A58', bg2: '#001C2C', accent: '#1876A8', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'clear-afternoon':  { bg1: '#182808', bg2: '#0A1404', accent: '#2A7A4A', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'clear-evening':    { bg1: '#281408', bg2: '#140A04', accent: '#B86820', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'clear-night':      { bg1: '#080818', bg2: '#04040E', accent: '#3848A8', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'cloudy-morning':   { bg1: '#1A1E28', bg2: '#0E1018', accent: '#6878A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'cloudy-noon':      { bg1: '#222830', bg2: '#111418', accent: '#6878A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'cloudy-afternoon': { bg1: '#1C2028', bg2: '#0C1018', accent: '#6878A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'cloudy-evening':   { bg1: '#201818', bg2: '#100C0C', accent: '#906858', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'cloudy-night':     { bg1: '#101018', bg2: '#08080E', accent: '#4858A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'rain-morning':     { bg1: '#0C1828', bg2: '#060C14', accent: '#3860A8', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'rain-noon':        { bg1: '#102030', bg2: '#081018', accent: '#3860A8', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'rain-afternoon':   { bg1: '#0E1A28', bg2: '#070D14', accent: '#3860A8', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'rain-evening':     { bg1: '#140E20', bg2: '#0A0810', accent: '#604898', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'rain-night':       { bg1: '#080C18', bg2: '#04060C', accent: '#3040A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'windy-morning':    { bg1: '#0A2020', bg2: '#050E0E', accent: '#1890A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'windy-noon':       { bg1: '#082828', bg2: '#041414', accent: '#1890A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'windy-afternoon':  { bg1: '#0C1E20', bg2: '#060F10', accent: '#1890A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'windy-evening':    { bg1: '#181008', bg2: '#0C0804', accent: '#A06818', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'windy-night':      { bg1: '#080C18', bg2: '#04060C', accent: '#1840A0', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'storm-morning':    { bg1: '#200808', bg2: '#100404', accent: '#C82828', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'storm-noon':       { bg1: '#281010', bg2: '#140808', accent: '#C82828', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'storm-afternoon':  { bg1: '#200C08', bg2: '#100604', accent: '#C82828', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'storm-evening':    { bg1: '#1C0808', bg2: '#0E0404', accent: '#A02020', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
  'storm-night':      { bg1: '#100408', bg2: '#080204', accent: '#802020', surface: '#FFFFFF', text1: '#111110', text2: '#6B6860', text3: '#B0ADA6', separator: '#E8E6E1' },
}

export function getTheme(condition: WeatherCondition, timeOfDay: TimeOfDay): Theme {
  const key = `${condition}-${timeOfDay}` as ThemeKey
  return WEATHER_THEMES[key] ?? WEATHER_THEMES['clear-morning']
}

export const COLORS = {
  bg:        '#F5F4F0',
  surface:   '#FFFFFF',
  surface2:  '#F0EEE9',
  text1:     '#111110',
  text2:     '#6B6860',
  text3:     '#B0ADA6',
  separator: '#E8E6E1',
  accent:    '#2A7A4A',
  red:       '#D63B2A',
  yellow:    '#C8920A',
  green:     '#1F7A42',
  blue:      '#1A5FA8',
  greenBg:   '#E6F4EC',
  yellowBg:  '#FEF6E4',
  redBg:     '#FCECEA',
  blueBg:    '#E8F0FF',
}
