import 'package:shared_preferences/shared_preferences.dart';

String levelKey(String langId, String diffId, String levelName) =>
    '${langId}_${diffId}_$levelName';

class ProgressStore {
  static const String _starsPrefix = 'stars_';
  static const String _proKey = 'pro_unlocked';

  final SharedPreferences _prefs;

  ProgressStore(this._prefs);

  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore(prefs);
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

  Future<void> setPro(bool value) => _prefs.setBool(_proKey, value);
}
