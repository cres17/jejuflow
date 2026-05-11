export function formatArrivalTime(addMinutes: number): string {
  const d = new Date(Date.now() + addMinutes * 60_000)
  const h = String(d.getHours()).padStart(2, '0')
  const m = String(d.getMinutes()).padStart(2, '0')
  return `${h}:${m}`
}

export function formatKoreanWon(amount: number): string {
  if (amount === 0) return 'Free'
  return `₩${amount.toLocaleString()}`
}

const FORECAST_HOURS = [2, 5, 8, 11, 14, 17, 20, 23]

export function getKMABaseDateTime(): { date: string; time: string } {
  const now = new Date()
  const hour = now.getHours()
  const minute = now.getMinutes()

  let baseHour = FORECAST_HOURS[0]
  for (const h of FORECAST_HOURS) {
    if (hour > h || (hour === h && minute >= 10)) {
      baseHour = h
    }
  }

  const pad = (n: number) => String(n).padStart(2, '0')
  const y = now.getFullYear()
  const mo = pad(now.getMonth() + 1)
  const d = pad(now.getDate())

  return {
    date: `${y}${mo}${d}`,
    time: `${pad(baseHour)}00`,
  }
}
