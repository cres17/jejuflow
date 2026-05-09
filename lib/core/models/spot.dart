import 'package:flutter/material.dart';

enum SpotCategory { outdoor, indoor, both }
enum SpotRegion { jejuCity, seogwipo }

class Spot {
  final String id;
  final String nameEn;
  final String emoji;
  final String sub;
  final SpotCategory category;
  final SpotRegion region;
  final String nearestStop;
  final String stopId;
  final List<String> busRoutes;
  final int walkMinutes;
  final int busWaitMinutes;
  final Color bgColor;
  final Color accentColor;
  final int fee;
  final String hours;
  final List<String> tags;
  final String? altSpotId;
  final String contentId;
  final double lat;
  final double lng;

  // Populated from API
  String? photoUrl;
  String? descriptionEn;

  Spot({
    required this.id,
    required this.nameEn,
    required this.emoji,
    required this.sub,
    required this.category,
    required this.region,
    required this.nearestStop,
    required this.stopId,
    required this.busRoutes,
    required this.walkMinutes,
    required this.busWaitMinutes,
    required this.bgColor,
    required this.accentColor,
    required this.fee,
    required this.hours,
    required this.tags,
    required this.altSpotId,
    required this.contentId,
    required this.lat,
    required this.lng,
  });

  factory Spot.fromMap(Map<String, dynamic> m) => Spot(
    id:             m['id'],
    nameEn:         m['name_en'],
    emoji:          m['emoji'],
    sub:            m['sub'],
    category:       SpotCategory.values.firstWhere((e) => e.name == (m['category'] as String).replaceAll('-', '')),
    region:         m['region'] == 'jeju-city' ? SpotRegion.jejuCity : SpotRegion.seogwipo,
    nearestStop:    m['nearestStop'],
    stopId:         m['stopId'],
    busRoutes:      List<String>.from(m['busRoutes']),
    walkMinutes:    m['walkMinutes'],
    busWaitMinutes: m['busWaitMinutes'],
    bgColor:        Color(m['bgColor']),
    accentColor:    Color(m['accentColor']),
    fee:            m['fee'],
    hours:          m['hours'],
    tags:           List<String>.from(m['tags']),
    altSpotId:      m['altSpotId'],
    contentId:      m['contentId'],
    lat:            (m['lat'] as num).toDouble(),
    lng:            (m['lng'] as num).toDouble(),
  );

  bool get isOutdoor => category == SpotCategory.outdoor;
  bool get isIndoor  => category == SpotCategory.indoor || category == SpotCategory.both;
  bool get isInJejuCity => region == SpotRegion.jejuCity;
}
