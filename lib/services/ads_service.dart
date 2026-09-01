import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'consent_service.dart' as consent;

class AdsService {
  final consent.ConsentService _consent;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _levelsSinceAd = 0;

  AdsService(this._consent);

  bool get canShowAds => _consent.canShowPersonalizedAds;
  bool get canShowNonPersonalized => _consent.status != consent.ConsentStatus.declined;

  Future<void> initialize() async {
    if (!canShowNonPersonalized) return;
    await MobileAds.instance.initialize();
    _preloadInterstitial();
    _preloadRewarded();
  }

  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  void _preloadInterstitial() {
    if (!canShowNonPersonalized) return;
    InterstitialAd.load(
      adUnitId: _testInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void _preloadRewarded() {
    if (!canShowNonPersonalized) return;
    RewardedAd.load(
      adUnitId: _testRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  Future<bool> showInterstitial({required bool isPro, int freqCap = 3}) async {
    if (isPro || !canShowNonPersonalized) return false;
    _levelsSinceAd++;
    if (_levelsSinceAd < freqCap) return false;
    final ad = _interstitial;
    if (ad == null) {
      _preloadInterstitial();
      return false;
    }
    _levelsSinceAd = 0;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) { a.dispose(); _preloadInterstitial(); },
      onAdFailedToShowFullScreenContent: (a, _) { a.dispose(); _preloadInterstitial(); },
    );
    await ad.show();
    _interstitial = null;
    return true;
  }

  Future<bool> showRewardedForHint({required bool isPro}) async {
    if (isPro) return true;
    if (!canShowNonPersonalized) return false;
    final ad = _rewarded;
    if (ad == null) {
      _preloadRewarded();
      return false;
    }
    bool earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) { a.dispose(); _preloadRewarded(); },
      onAdFailedToShowFullScreenContent: (a, _) { a.dispose(); _preloadRewarded(); },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    _rewarded = null;
    return earned;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
