import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejuflow/core/models/saved_route.dart';
import 'package:jejuflow/core/models/spot.dart';
import 'package:jejuflow/core/utils/route_utils.dart';

void main() {
  group('Route Utilities Tests', () {
    Spot createMockSpot({
      required String id,
      required String name,
      required List<String> tags,
      required double lat,
      required double lng,
      SpotCategory category = SpotCategory.outdoor,
    }) {
      return Spot(
        id: id,
        nameEn: name,
        emoji: '📍',
        sub: 'Test sub',
        category: category,
        region: SpotRegion.jejuCity,
        nearestStop: 'Test Stop',
        stopId: '123',
        busRoutes: ['101'],
        walkMinutes: 5,
        busWaitMinutes: 10,
        bgColor: Colors.white,
        accentColor: Colors.black,
        fee: 0,
        hours: '09:00 - 18:00',
        tags: tags,
        altSpotId: null,
        contentId: 'test_content',
        lat: lat,
        lng: lng,
      );
    }

    test('Geographical distance calculation (distanceKmBetween)', () {
      // Hallasan Observatory roughly 33.3617, 126.5332
      // Jeju Airport roughly 33.5104, 126.4913
      final hallasan = createMockSpot(
        id: 'hallasan',
        name: 'Hallasan Mountain',
        tags: ['volcanic'],
        lat: 33.3617,
        lng: 126.5332,
      );

      final airport = createMockSpot(
        id: 'airport',
        name: 'Jeju Airport',
        tags: ['airport'],
        lat: 33.5104,
        lng: 126.4913,
      );

      final dist = distanceKmBetween(hallasan, airport);
      // The distance should be approximately 16.9 km
      expect(dist, greaterThan(16.0));
      expect(dist, lessThan(18.0));
    });

    test('Visit duration estimation (estimateVisitMinutes)', () {
      final beachSpot = createMockSpot(
        id: 'beach_spot',
        name: 'Hyeopjae Beach',
        tags: ['beach'],
        lat: 33.36,
        lng: 126.5,
      );

      final indoorSpot = createMockSpot(
        id: 'indoor_spot',
        name: 'O\'sulloc Tea Museum',
        tags: ['museum'],
        category: SpotCategory.indoor,
        lat: 33.36,
        lng: 126.5,
      );

      final waterfallSpot = createMockSpot(
        id: 'waterfall_spot',
        name: 'Cheonjiyeon Waterfall',
        tags: ['scenic'],
        lat: 33.36,
        lng: 126.5,
      );

      expect(estimateVisitMinutes(beachSpot), equals(90));
      expect(estimateVisitMinutes(indoorSpot), equals(70));
      expect(
        estimateVisitMinutes(waterfallSpot),
        equals(55),
      ); // Cheonjiyeon has 'waterfall' in nameEn
    });

    test('Day plan timeline creation (buildDayPlan)', () {
      final spotA = createMockSpot(
        id: 'spot_a',
        name: 'Spot A',
        tags: ['scenic'],
        lat: 33.5,
        lng: 126.5,
      );

      final spotB = createMockSpot(
        id: 'spot_b',
        name: 'Spot B',
        tags: ['scenic'],
        lat: 33.4,
        lng: 126.6, // Far enough to calculate non-zero transfer time
      );

      final baseTime = DateTime(2026, 6, 29, 10, 0);

      final routeA = SavedRoute(
        id: 'route_a',
        spotId: 'spot_a',
        spotName: 'Spot A',
        spotEmoji: '📍',
        accent: Colors.black,
        savedAt: baseTime,
        totalMinutes: 20,
        fee: 0,
        steps: [],
        lat: 33.5,
        lng: 126.5,
        koreanName: 'Spot A',
        contentId: 'content_a',
      );

      final routeB = SavedRoute(
        id: 'route_b',
        spotId: 'spot_b',
        spotName: 'Spot B',
        spotEmoji: '📍',
        accent: Colors.black,
        savedAt: baseTime.add(
          const Duration(minutes: 30),
        ), // Saved 30 mins after route A
        totalMinutes: 20,
        fee: 0,
        steps: [],
        lat: 33.4,
        lng: 126.6,
        koreanName: 'Spot B',
        contentId: 'content_b',
      );

      final spotsMap = {'spot_a': spotA, 'spot_b': spotB};

      final plan = buildDayPlan([routeA, routeB], spotsMap);

      expect(plan.length, equals(2));
      expect(plan[0].spot?.id, equals('spot_a'));
      expect(plan[1].spot?.id, equals('spot_b'));

      // First spot arrival should match routeA savedAt
      expect(plan[0].arrival, equals(baseTime));
      // First spot stay is estimateVisitMinutes(spotA) which is 75 mins
      expect(plan[0].stayMinutes, equals(75));
      expect(
        plan[0].departure,
        equals(baseTime.add(const Duration(minutes: 75))),
      );

      // Second spot earliest arrival is plan[0].departure + transfer time
      // Check that it's after the departure of the first spot
      expect(plan[1].arrival.isAfter(plan[0].departure), isTrue);
    });
  });
}
