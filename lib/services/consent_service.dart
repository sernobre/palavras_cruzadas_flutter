import 'package:shared_preferences/shared_preferences.dart';

enum ConsentStatus { unknown, required, obtained, notRequired, declined }

class ConsentService {
  static const _consentKey = 'consent_status';
  static const _tcStringKey = 'tc_string';
  static const _gpcKey = 'gpc_enabled';

  final SharedPreferences _prefs;
  ConsentService(this._prefs);

  ConsentStatus get status {
    final v = _prefs.getString(_consentKey);
    return ConsentStatus.values.firstWhere((e) => e.name == v, orElse: () => ConsentStatus.unknown);
  }

  String? get tcString => _prefs.getString(_tcStringKey);
  bool get gpcEnabled => _prefs.getBool(_gpcKey) ?? false;

  Future<void> setStatus(ConsentStatus s, {String? tcString}) async {
    await _prefs.setString(_consentKey, s.name);
    if (tcString != null) await _prefs.setString(_tcStringKey, tcString);
  }

  bool get canShowPersonalizedAds =>
      status == ConsentStatus.obtained || status == ConsentStatus.notRequired;

  bool get canUseAnalytics =>
      status == ConsentStatus.obtained || status == ConsentStatus.notRequired;

  static bool isEEAOrUK(String variantId) =>
      variantId.startsWith('pt') || variantId.startsWith('es') || variantId == 'en-GB';

  static bool isUS(String variantId) => variantId == 'en-US';
}
