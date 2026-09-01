import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

String levelKey(String langId, String diffId, String levelName) =>
    '${langId}_${diffId}_$levelName';

String variantLevelKey(String variantId, String diffId, String levelName) =>
    '${variantId}_${diffId}_$levelName';

String dailyKey(String langId, DateTime day) =>
    'daily_${langId}_${_dayString(day)}';

String _dayString(DateTime d) => '${d.year}-${d.month}-${d.day}';

class ProgressStore {
  static const String _starsPrefix = 'stars_';
  static const String _proKey = 'pro_unlocked';
  static const String _proSourceKey = 'pro_source';
  static const String _proExpiryKey = 'pro_expiry';
  static const String _streakKey = 'streak';
  static const String _lastDailyKey = 'last_daily';
  static const String _savePrefix = 'save_';
  static const String _bestTimePrefix = 'best_time_';
  static const String _selectedVariantKey = 'selected_variant';

  final SharedPreferences _prefs;

  ProgressStore(this._prefs);

  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = ProgressStore(prefs);
    await store._migrateLegacyKeys();
    return store;
  }

  SharedPreferences get prefs => _prefs;

  Future<void> _migrateLegacyKeys() async {
    const legacyMap = {'pt': 'pt-PT', 'es': 'es-ES', 'en': 'en-US'};
    for (final entry in legacyMap.entries) {
      final legacyPrefixStars = '${_starsPrefix}${entry.key}_';
      final newPrefixStars = '${_starsPrefix}${entry.value}_';
      final legacyPrefixSave = '${_savePrefix}${entry.key}_';
      final newPrefixSave = '${_savePrefix}${entry.value}_';
      final legacyPrefixTime = '${_bestTimePrefix}${entry.key}_';
      final newPrefixTime = '${_bestTimePrefix}${entry.value}_';
      for (final k in _prefs.getKeys().toList()) {
        if (k.startsWith(legacyPrefixStars) && !_prefs.containsKey(k.replaceFirst(legacyPrefixStars, newPrefixStars))) {
          final v = _prefs.getInt(k);
          if (v != null) await _prefs.setInt(k.replaceFirst(legacyPrefixStars, newPrefixStars), v);
        }
        if (k.startsWith(legacyPrefixSave) && !_prefs.containsKey(k.replaceFirst(legacyPrefixSave, newPrefixSave))) {
          final v = _prefs.getString(k);
          if (v != null) await _prefs.setString(k.replaceFirst(legacyPrefixSave, newPrefixSave), v);
        }
        if (k.startsWith(legacyPrefixTime) && !_prefs.containsKey(k.replaceFirst(legacyPrefixTime, newPrefixTime))) {
          final v = _prefs.getInt(k);
          if (v != null) await _prefs.setInt(k.replaceFirst(legacyPrefixTime, newPrefixTime), v);
        }
        if (k.startsWith('daily_${entry.key}_') && !_prefs.containsKey(k.replaceFirst('daily_${entry.key}_', 'daily_${entry.value}_'))) {
          final v = _prefs.getInt(k);
          if (v != null) await _prefs.setInt(k.replaceFirst('daily_${entry.key}_', 'daily_${entry.value}_'), v);
        }
      }
    }
  }

  int starsFor(String key) => _prefs.getInt('$_starsPrefix$key') ?? 0;

  Future<void> recordStars(String key, int stars) async {
    if (stars > starsFor(key)) {
      await _prefs.setInt('$_starsPrefix$key', stars);
    }
  }

  int totalStars() {
    var total = 0;
    for (final k in _prefs.getKeys()) {
      if (k.startsWith(_starsPrefix)) total += _prefs.getInt(k) ?? 0;
    }
    return total;
  }

  int completedCount(List<String> keys) =>
      keys.where((k) => starsFor(k) > 0).length;

  bool get isPro => _prefs.getBool(_proKey) ?? false;
  String? get proSource => _prefs.getString(_proSourceKey);
  DateTime? get proExpiry {
    final v = _prefs.getInt(_proExpiryKey);
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  bool get isProValid {
    if (!isPro) return false;
    final exp = proExpiry;
    if (exp == null) return true;
    return DateTime.now().isBefore(exp);
  }

  Future<void> setPro(bool value, {String source = 'mock', DateTime? expiry}) async {
    await _prefs.setBool(_proKey, value);
    if (value) {
      await _prefs.setString(_proSourceKey, source);
      if (expiry != null) await _prefs.setInt(_proExpiryKey, expiry.millisecondsSinceEpoch);
    } else {
      await _prefs.remove(_proSourceKey);
      await _prefs.remove(_proExpiryKey);
    }
  }

  int get streak => _prefs.getInt(_streakKey) ?? 0;

  DateTime? get lastDailyDate {
    final s = _prefs.getString(_lastDailyKey);
    return s == null ? null : DateTime.tryParse(s);
  }

  bool dailyCompletedToday(String langId, DateTime day) =>
      _prefs.getInt(dailyKey(langId, day)) == 1;

  Future<void> recordDaily(String langId, DateTime day) async {
    final today = DateTime(day.year, day.month, day.day);
    final last = lastDailyDate;
    var s = streak;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        s += 1;
      } else if (diff != 0) {
        s = 1;
      }
    } else {
      s = 1;
    }
    await _prefs.setInt(_streakKey, s);
    await _prefs.setString(_lastDailyKey, today.toIso8601String());
    await _prefs.setInt(dailyKey(langId, today), 1);
  }

  Future<void> saveGameState(String levelKey, Map<String, String> input, Set<String> revealed, int hintsUsed, int elapsedSeconds) async {
    final data = jsonEncode({
      'input': input,
      'revealed': revealed.toList(),
      'hints': hintsUsed,
      'elapsed': elapsedSeconds,
    });
    await _prefs.setString('$_savePrefix$levelKey', data);
  }

  Map<String, dynamic>? loadGameState(String levelKey) {
    final raw = _prefs.getString('$_savePrefix$levelKey');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearGameState(String levelKey) async {
    await _prefs.remove('$_savePrefix$levelKey');
  }

  int? bestTimeFor(String key) => _prefs.getInt('$_bestTimePrefix$key');

  Future<void> recordBestTime(String key, int seconds) async {
    final current = bestTimeFor(key);
    if (current == null || seconds < current) {
      await _prefs.setInt('$_bestTimePrefix$key', seconds);
    }
  }

  String? get selectedVariantId => _prefs.getString(_selectedVariantKey);
  Future<void> setSelectedVariant(String v) => _prefs.setString(_selectedVariantKey, v);
}
