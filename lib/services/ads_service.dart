import 'consent_service.dart';

class AdsService {
  final ConsentService _consent;
  AdsService(this._consent);

  bool get canShowAds => _consent.canShowPersonalizedAds;

  Future<void> initialize() async {}

  Future<bool> showInterstitial({required bool isPro}) async {
    if (isPro || !canShowAds) return false;
    return true;
  }

  Future<bool> showRewardedForHint({required bool isPro}) async {
    if (isPro) return true;
    if (!canShowAds) return false;
    return true;
  }
}
