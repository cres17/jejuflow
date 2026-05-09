String formatArrivalTime(int addMinutes) {
  final t = DateTime.now().add(Duration(minutes: addMinutes));
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

String formatWon(int amount) {
  if (amount == 0) return 'Free';
  return '₩${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

Map<String, String> getKMABaseDateTime() {
  const forecastHours = [2, 5, 8, 11, 14, 17, 20, 23];
  // Data available ~10 min after the base hour
  final ref = DateTime.now().subtract(const Duration(minutes: 10));

  int? base;
  var date = DateTime(ref.year, ref.month, ref.day);

  for (final h in forecastHours.reversed) {
    if (ref.hour >= h) { base = h; break; }
  }

  // Before 02:10 KST → use yesterday's 2300
  if (base == null) {
    date = date.subtract(const Duration(days: 1));
    base = 23;
  }

  final dateStr =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  final timeStr = '${base.toString().padLeft(2, '0')}00';
  return {'date': dateStr, 'time': timeStr};
}

String savedAgo(DateTime savedAt) {
  final d = DateTime.now().difference(savedAt).inMinutes;
  if (d < 60)   return '${d}m ago';
  if (d < 1440) return '${d ~/ 60}h ago';
  return '${d ~/ 1440}d ago';
}
