import 'package:shared_preferences/shared_preferences.dart';

enum ConsentStatus { unknown, required, obtained, notRequired, declined }

class ConsentService {
  static const _consentKey = 'consent_status';
  static const _tcStringKey = 'tc_string';
  static const _gpcKey = 'gpc_enabled';

  final SharedPreferences _prefs;
  ConsentService(this._prefs);

  static Future<ConsentService> load() async {
    final p = await SharedPreferences.getInstance();
    return ConsentService(p);
  }

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

  Future<void> setGpc(bool v) => _prefs.setBool(_gpcKey, v);

  bool get canShowPersonalizedAds => status == ConsentStatus.obtained || status == ConsentStatus.notRequired;
  bool get canUseAnalytics => status == ConsentStatus.obtained || status == ConsentStatus.notRequired;
  bool get canShowNonPersonalized => status != ConsentStatus.declined && status != ConsentStatus.unknown || status == ConsentStatus.notRequired;

  static bool isEEAOrUK(String variantId) =>
      variantId.startsWith('pt') || variantId.startsWith('es') || variantId == 'en-GB';

  static bool requiresConsent(String variantId) => isEEAOrUK(variantId);

  Future<ConsentStatus> requestConsentIfNeeded(String variantId) async {
    if (!requiresConsent(variantId)) {
      if (status == ConsentStatus.unknown) await setStatus(ConsentStatus.notRequired);
      return status;
    }
    if (status == ConsentStatus.obtained || status == ConsentStatus.declined || status == ConsentStatus.notRequired) return status;
    await setStatus(ConsentStatus.required);
    return ConsentStatus.required;
  }
}
