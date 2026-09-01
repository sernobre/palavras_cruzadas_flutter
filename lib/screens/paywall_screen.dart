import 'package:flutter/material.dart';
import 'package:palavrascruzadas/services/progress.dart';
import 'package:palavrascruzadas/services/purchase_service.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  final String variantId;
  final ProgressStore store;

  const PaywallScreen({super.key, required this.variantId, required this.store});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final price = priceFor(widget.variantId);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context, false)),
        title: const Text('Pro'),
        actions: [
          TextButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    final svc = PurchaseService(widget.store);
                    final ok = await svc.restore();
                    if (!mounted) return;
                    setState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Compras restauradas' : 'Nenhuma compra encontrada')));
                    if (ok) Navigator.pop(context, true);
                  },
            child: const Text('Restaurar'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text('Desbloqueia Pro por $price',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(_subtitleFor(widget.variantId),
                      style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _Bullet(icon: Icons.all_inclusive_rounded, text: 'Dicas ilimitadas'),
            const _Bullet(icon: Icons.block_rounded, text: 'Sem anúncios'),
            const _Bullet(icon: Icons.timer_rounded, text: 'Estatísticas e melhor tempo'),
            const _Bullet(icon: Icons.calendar_today_rounded, text: 'Arquivo e streak sem limite'),
            const Spacer(),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      final svc = PurchaseService(widget.store);
                      final ok = await svc.buy('palavras_pro_lifetime', widget.variantId);
                      if (!mounted) return;
                      setState(() => _loading = false);
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pro desbloqueado!')));
                        Navigator.pop(context, true);
                      }
                    },
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Desbloquear por $price'),
            ),
            const SizedBox(height: 8),
            Text(_priceFootnote(widget.variantId), style: const TextStyle(color: AppTheme.muted, fontSize: 11), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () {}, child: const Text('Termos')),
                TextButton(onPressed: () {}, child: const Text('Privacidade')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(String v) {
    if (v.startsWith('pt')) return 'Pagamento único • Suporte PT/ES/EN';
    if (v.startsWith('es')) return 'Pago único • Soporte PT/ES/EN';
    return 'One-time purchase • PT/ES/EN support';
  }

  String _priceFootnote(String v) {
    if (v == 'pt-BR') return 'Preço em BRL • Compra única na loja';
    if (v == 'en-US') return 'One-time purchase via App Store / Play Store';
    if (v == 'en-GB') return 'One-time purchase • UK VAT included';
    return 'Compra única • IVA incluído';
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
