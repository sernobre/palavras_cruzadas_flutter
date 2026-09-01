import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

String levelKey(String langId, String diffId, String levelName) =>
    '${langId}_${diffId}_$levelName';

String dailyKey(String langId, DateTime day) =>
    'daily_${langId}_${_dayString(day)}';

String _dayString(DateTime d) => '${d.year}-${d.month}-${d.day}';

class ProgressStore {
  static const String _starsPrefix = 'stars_';
  static const String _proKey = 'pro_unlocked';
  static const String _streakKey = 'streak';
  static const String _lastDailyKey = 'last_daily';
  static const String _savePrefix = 'save_';
  static const String _bestTimePrefix = 'best_time_';

  final SharedPreferences _prefs;

  ProgressStore(this._prefs);

  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore(prefs);
  }

  SharedPreferences get prefs => _prefs;

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

  Future<void> setPro(bool value) => _prefs.setBool(_proKey, value);

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
}
