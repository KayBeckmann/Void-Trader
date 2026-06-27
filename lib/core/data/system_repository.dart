import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/star_system.dart';

class SystemRepository {
  static List<StarSystem>? _cache;

  static Future<List<StarSystem>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/core_systems.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['systems'] as List<dynamic>)
        .map((s) => StarSystem.fromJson(s as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  static Future<StarSystem?> findById(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
