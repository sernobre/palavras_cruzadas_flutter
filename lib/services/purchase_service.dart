import 'progress.dart';

class PurchaseProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currency;

  const PurchaseProduct({required this.id, required this.title, required this.description, required this.price, required this.currency});
}

const purchaseProducts = [
  PurchaseProduct(id: 'palavras_pro_lifetime', title: 'Pro Lifetime', description: 'Dicas ilimitadas e sem anúncios', price: '€4,49', currency: 'EUR'),
];

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
  PurchaseService(this._store);

  Future<bool> buy(String productId, String variantId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _store.setPro(true, source: 'purchase:$productId:$variantId');
    return true;
  }

  Future<bool> restore() async {
    return _store.isPro;
  }

  String localizedPrice(String variantId) => priceFor(variantId);
}
