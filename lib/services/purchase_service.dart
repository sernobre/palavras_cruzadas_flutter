import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'progress.dart';

const String kProLifetimeId = 'palavras_pro_lifetime';

const purchaseProductIds = {kProLifetimeId};

const Map<String, String> regionalPrice = {
  'pt-PT': '€4,49',
  'pt-BR': 'R\$ 19,90',
  'es-ES': '€4,49',
  'es-419': '\$4.99',
  'en-US': '\$4.99',
  'en-GB': '£4.49',
};

String priceFor(String variantId) => regionalPrice[variantId] ?? '€4,49';

class PurchaseService {
  final ProgressStore _store;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<bool>? _buyCompleter;
  String? _pendingVariant;

  PurchaseService(this._store);

  Future<bool> isAvailable() async => _iap.isAvailable();

  Future<List<ProductDetails>> fetchProducts() async {
    if (!await isAvailable()) return [];
    final resp = await _iap.queryProductDetails(purchaseProductIds);
    if (resp.error != null || resp.productDetails.isEmpty) return [];
    return resp.productDetails;
  }

  String localizedPrice(String variantId, List<ProductDetails>? storeProducts) {
    if (storeProducts != null) {
      for (final p in storeProducts) {
        if (p.id == kProLifetimeId) return p.price;
      }
    }
    return priceFor(variantId);
  }

  Future<bool> buy(String productId, String variantId) async {
    if (!await isAvailable()) {
      await _store.setPro(true, source: 'purchase:$productId:$variantId:mock');
      return true;
    }
    final products = await fetchProducts();
    final product = products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      await _store.setPro(true, source: 'purchase:$productId:$variantId:mock_fallback');
      return true;
    }
    _pendingVariant = variantId;
    _buyCompleter = Completer<bool>();
    _ensureListener();
    final param = PurchaseParam(productDetails: product);
    final ok = await _iap.buyNonConsumable(purchaseParam: param);
    if (!ok) {
      _buyCompleter?.complete(false);
      _buyCompleter = null;
      return false;
    }
    return _buyCompleter!.future.timeout(const Duration(seconds: 60), onTimeout: () => false);
  }

  Future<bool> restore() async {
    if (!await isAvailable()) return _store.isPro;
    _ensureListener();
    await _iap.restorePurchases();
    await Future.delayed(const Duration(seconds: 1));
    return _store.isPro;
  }

  void _ensureListener() {
    _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (_) {
      if (_buyCompleter != null && !_buyCompleter!.isCompleted) _buyCompleter!.complete(false);
    });
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        if (purchaseProductIds.contains(p.productID)) {
          await _store.setPro(true, source: 'store:${p.productID}:${_pendingVariant ?? ''}:${p.purchaseID}');
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          if (_buyCompleter != null && !_buyCompleter!.isCompleted) _buyCompleter!.complete(true);
        }
      } else if (p.status == PurchaseStatus.error) {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        if (_buyCompleter != null && !_buyCompleter!.isCompleted) _buyCompleter!.complete(false);
      } else if (p.status == PurchaseStatus.canceled) {
        if (_buyCompleter != null && !_buyCompleter!.isCompleted) _buyCompleter!.complete(false);
      }
      if (p.status == PurchaseStatus.pending) {}
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
