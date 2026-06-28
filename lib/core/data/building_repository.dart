import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/building.dart';

class BuildingRepository {
  static List<BuildingDef>? _cache;

  static Future<List<BuildingDef>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/buildings.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['buildings'] as List<dynamic>)
        .map((b) => BuildingDef.fromJson(b as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  static Future<BuildingDef?> findById(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<BuildingDef>> tier1() async {
    final all = await loadAll();
    return all.where((b) => b.tier == BuildingTier.tier1).toList();
  }
}
