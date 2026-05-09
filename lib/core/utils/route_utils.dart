import 'dart:math' as math;

import '../models/bus_arrival.dart';
import '../models/saved_route.dart';
import '../models/spot.dart';
import 'time_utils.dart';

class DayPlanItem {
  const DayPlanItem({
    required this.route,
    required this.spot,
    required this.arrival,
    required this.departure,
    required this.stayMinutes,
    required this.distanceFromPreviousKm,
    required this.transferMinutes,
    required this.order,
  });

  final SavedRoute route;
  final Spot? spot;
  final DateTime arrival;
  final DateTime departure;
  final int stayMinutes;
  final double distanceFromPreviousKm;
  final int transferMinutes;
  final int order;
}

List<RouteStep> buildRouteSteps(Spot spot, BusArrival? busArrival) {
  final waitMin = busArrival?.arrivalMinutes ?? spot.busWaitMinutes;
  return [
    const RouteStep(
      type: 'start',
      icon: 'start',
      main: 'Your location',
      detail: 'Walk to nearest bus stop',
      durationMinutes: 0,
    ),
    RouteStep(
      type: 'walk',
      icon: 'walk',
      main: 'Walk to ${spot.nearestStop}',
      detail: '~3 min walk',
      durationMinutes: 3,
    ),
    RouteStep(
      type: 'bus',
      icon: 'bus',
      main: 'Bus ${spot.busRoutes[0]}',
      detail: 'Wait ~$waitMin min',
      durationMinutes: waitMin,
    ),
    RouteStep(
      type: 'walk',
      icon: 'walk',
      main: 'Walk to ${spot.nameEn}',
      detail: '${spot.walkMinutes} min from stop',
      durationMinutes: spot.walkMinutes,
    ),
    RouteStep(
      type: 'arrive',
      icon: 'arrive',
      main: spot.nameEn,
      detail: 'Open ${spot.hours} · ${formatWon(spot.fee)}',
      durationMinutes: 0,
    ),
  ];
}

int computeTotalMinutes(Spot spot, BusArrival? busArrival) {
  final waitMin = busArrival?.arrivalMinutes ?? spot.busWaitMinutes;
  return 3 + waitMin + spot.walkMinutes;
}

SavedRoute buildSavedRoute(Spot spot, BusArrival? busArrival,
    {DateTime? scheduledAt}) {
  final steps = buildRouteSteps(spot, busArrival);
  final total = computeTotalMinutes(spot, busArrival);
  final date = scheduledAt ?? DateTime.now();
  return SavedRoute(
    id: '${spot.id}-${date.millisecondsSinceEpoch}',
    spotId: spot.id,
    spotName: spot.nameEn,
    spotEmoji: spot.emoji,
    accent: spot.accentColor,
    savedAt: date,
    totalMinutes: total,
    fee: spot.fee,
    steps: steps,
    lat: spot.lat,
    lng: spot.lng,
    koreanName: spot.nameEn,
    contentId: spot.contentId,
    photoUrl: spot.photoUrl,
  );
}

({int minutes, int minKrw, int maxKrw}) estimateTaxi(int totalMinutes) => (
      minutes: (totalMinutes * 0.5).round(),
      minKrw: (totalMinutes * 600).round(),
      maxKrw: (totalMinutes * 900).round(),
    );

List<DayPlanItem> buildDayPlan(
    List<SavedRoute> routes, Map<String, Spot> spots) {
  final sorted = [...routes]..sort((a, b) => a.savedAt.compareTo(b.savedAt));
  final items = <DayPlanItem>[];
  DateTime? previousDeparture;
  Spot? previousSpot;

  for (final route in sorted) {
    final spot = spots[route.spotId];
    final distanceKm = previousSpot != null && spot != null
        ? distanceKmBetween(previousSpot, spot)
        : 0.0;
    final transferMinutes =
        previousSpot == null ? 0 : estimateTransferMinutes(distanceKm);
    final earliestArrival = previousDeparture == null
        ? route.savedAt
        : previousDeparture.add(Duration(minutes: transferMinutes));
    final arrival = earliestArrival.isAfter(route.savedAt)
        ? earliestArrival
        : route.savedAt;
    final stayMinutes = spot == null ? 70 : estimateVisitMinutes(spot);
    final departure = arrival.add(Duration(minutes: stayMinutes));

    items.add(DayPlanItem(
      route: route,
      spot: spot,
      arrival: arrival,
      departure: departure,
      stayMinutes: stayMinutes,
      distanceFromPreviousKm: distanceKm,
      transferMinutes: transferMinutes,
      order: items.length + 1,
    ));

    previousDeparture = departure;
    previousSpot = spot ?? previousSpot;
  }

  return items;
}

int estimateVisitMinutes(Spot spot) {
  final tags = spot.tags.map((tag) => tag.toLowerCase()).toSet();
  final name = spot.nameEn.toLowerCase();
  if (tags.contains('beach')) return 90;
  if (tags.contains('family') || tags.contains('garden')) return 110;
  if (tags.contains('crater') ||
      tags.contains('volcanic') ||
      name.contains('peak')) {
    return 85;
  }
  if (tags.contains('walking') || tags.contains('forest')) return 80;
  if (spot.category == SpotCategory.indoor) return 70;
  if (name.contains('waterfall') || tags.contains('photo')) return 55;
  return 75;
}

int estimateTransferMinutes(double distanceKm) {
  if (distanceKm <= 0) return 0;
  return math.max(12, (distanceKm / 24 * 60 + 8).round());
}

double distanceKmBetween(Spot a, Spot b) {
  const earthKm = 6371.0;
  final dLat = _degToRad(b.lat - a.lat);
  final dLng = _degToRad(b.lng - a.lng);
  final lat1 = _degToRad(a.lat);
  final lat2 = _degToRad(b.lat);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earthKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _degToRad(double deg) => deg * math.pi / 180;
