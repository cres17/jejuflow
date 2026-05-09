import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static final _box = Hive.box<String>('cache');

  static Future<T?> get<T>(String key, int ttlMs, T Function(dynamic) fromJson) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    final entry = jsonDecode(raw) as Map<String, dynamic>;
    final age = DateTime.now().millisecondsSinceEpoch - (entry['cachedAt'] as int);
    if (age > ttlMs) return null;
    try {
      return fromJson(entry['data']);
    } catch (_) {
      return null;
    }
  }

  static Future<T?> getStale<T>(String key, T Function(dynamic) fromJson) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    final entry = jsonDecode(raw) as Map<String, dynamic>;
    try {
      return fromJson(entry['data']);
    } catch (_) {
      return null;
    }
  }

  static Future<void> set(String key, dynamic data) async {
    final entry = {'data': data, 'cachedAt': DateTime.now().millisecondsSinceEpoch};
    await _box.put(key, jsonEncode(entry));
  }

  static const int minute = 60 * 1000;
  static const int tenMin  = 10 * 60 * 1000;
  static const int hour    = 60 * 60 * 1000;
  static const int day     = 24 * 60 * 60 * 1000;
  static const int month   = 30 * 24 * 60 * 60 * 1000;
}
