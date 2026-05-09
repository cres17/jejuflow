import 'dart:convert';
import 'package:flutter/material.dart';

class RouteStep {
  final String type; // start | walk | bus | arrive
  final String icon;
  final String main;
  final String detail;
  final int durationMinutes;

  const RouteStep({
    required this.type,
    required this.icon,
    required this.main,
    required this.detail,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'icon': icon,
        'main': main,
        'detail': detail,
        'durationMinutes': durationMinutes,
      };

  factory RouteStep.fromJson(Map<String, dynamic> j) => RouteStep(
        type: j['type'],
        icon: j['icon'],
        main: j['main'],
        detail: j['detail'],
        durationMinutes: j['durationMinutes'],
      );
}

class SavedRoute {
  final String id;
  final String spotId;
  final String spotName;
  final String spotEmoji;
  final Color accent;
  final DateTime savedAt;
  final int totalMinutes;
  final int fee;
  final List<RouteStep> steps;
  final double? lat;
  final double? lng;
  final String? koreanName;
  final String? contentId;
  final String? photoUrl;

  const SavedRoute({
    required this.id,
    required this.spotId,
    required this.spotName,
    required this.spotEmoji,
    required this.accent,
    required this.savedAt,
    required this.totalMinutes,
    required this.fee,
    required this.steps,
    this.lat,
    this.lng,
    this.koreanName,
    this.contentId,
    this.photoUrl,
  });

  SavedRoute copyWith({
    String? id,
    String? spotId,
    String? spotName,
    String? spotEmoji,
    Color? accent,
    DateTime? savedAt,
    int? totalMinutes,
    int? fee,
    List<RouteStep>? steps,
    double? lat,
    double? lng,
    String? koreanName,
    String? contentId,
    String? photoUrl,
  }) {
    return SavedRoute(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      spotName: spotName ?? this.spotName,
      spotEmoji: spotEmoji ?? this.spotEmoji,
      accent: accent ?? this.accent,
      savedAt: savedAt ?? this.savedAt,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      fee: fee ?? this.fee,
      steps: steps ?? this.steps,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      koreanName: koreanName ?? this.koreanName,
      contentId: contentId ?? this.contentId,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  String toJson() => jsonEncode({
        'id': id,
        'spotId': spotId,
        'spotName': spotName,
        'spotEmoji': spotEmoji,
        'accentValue': accent.toARGB32(),
        'savedAt': savedAt.millisecondsSinceEpoch,
        'totalMinutes': totalMinutes,
        'fee': fee,
        'steps': steps.map((s) => s.toJson()).toList(),
        'lat': lat,
        'lng': lng,
        'koreanName': koreanName,
        'contentId': contentId,
        'photoUrl': photoUrl,
      });

  factory SavedRoute.fromJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return SavedRoute(
      id: j['id'],
      spotId: j['spotId'],
      spotName: j['spotName'],
      spotEmoji: j['spotEmoji'],
      accent: Color(j['accentValue']),
      savedAt: DateTime.fromMillisecondsSinceEpoch(j['savedAt']),
      totalMinutes: j['totalMinutes'],
      fee: j['fee'],
      steps: (j['steps'] as List).map((s) => RouteStep.fromJson(s)).toList(),
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      koreanName: j['koreanName'] as String?,
      contentId: j['contentId'] as String?,
      photoUrl: j['photoUrl'] as String?,
    );
  }
}
