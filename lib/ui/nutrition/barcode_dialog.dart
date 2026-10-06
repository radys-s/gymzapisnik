import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/off_client.dart';
import '../../domain/nutrition.dart';

/// Výsledek hledání: nalezený [product], nebo `null` = zadat ručně
/// (s kódem [barcode], který uživatel zadal).
class BarcodeOutcome {
  final OffProduct? product;
  final String barcode;
  const BarcodeOutcome(this.product, this.barcode);
}

Future<BarcodeOutcome?> showBarcodeDialog(
  BuildContext context,
  ProductLookup lookup,
) => showDialog<BarcodeOutcome>(
  context: context,
  builder: (_) => _BarcodeDialog(lookup),
);

class _BarcodeDialog extends StatefulWidget {
  final ProductLookup lookup;
  const _BarcodeDialog(this.lookup);

  @override
  State<_BarcodeDialog> createState() => _BarcodeDialogState();
}

class _BarcodeDialogState extends State<_BarcodeDialog> {
  final controller = TextEditingController();
  bool busy = false;
  String? error;

  /// Po neúspěchu nabídneme ruční zápis.
  bool offerManual = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = controller.text.trim();
    if (!validBarcode(code)) {
      setState(() {
        error =
            'Zadej čárový kód (8, 12, 13 nebo 14 číslic) se správnou '
            'kontrolní číslicí.';
        offerManual = false;
      });
      return;
    }
    setState(() {
      busy = true;
      error = null;
      offerManual = false;
    });
    final result = await widget.lookup.byBarcode(code);
    if (!mounted) return;
    switch (result) {
      case LookupFound(:final product):
        Navigator.pop(context, BarcodeOutcome(product, code));
      case LookupNotFound():
        setState(() {
          busy = false;
          offerManual = true;
          error = 'Produkt v databázi není. Můžeš ho zapsat ručně.';
        });
      case LookupFailed(:final message):
        setState(() {
          busy = false;
          offerManual = true;
          error = '$message Můžeš ho zapsat ručně.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Čárový kód'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          enabled: !busy,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Číslo pod čárovým kódem',
            errorText: error,
            errorMaxLines: 4,
          ),
          onSubmitted: (_) => _search(),
        ),
        const SizedBox(height: 8),
        Text(
          'Kód se odešle do Open Food Facts. Nic jiného se neodesílá.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Zrušit'),
      ),
      if (offerManual)
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            BarcodeOutcome(null, controller.text.trim()),
          ),
          child: const Text('Zadat ručně'),
        ),
      FilledButton(
        onPressed: busy ? null : _search,
        child: const Text('Najít'),
      ),
    ],
  );
}
