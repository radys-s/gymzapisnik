import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n.dart';
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
        error = tr(
          'Zadej čárový kód (8, 12, 13 nebo 14 číslic) se správnou '
              'kontrolní číslicí.',
          'Enter a barcode (8, 12, 13 or 14 digits) with a valid check digit.',
        );
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
          error = tr(
            'Produkt v databázi není. Můžeš ho zapsat ručně.',
            'Product not found. You can enter it manually.',
          );
        });
      case LookupFailed(:final message):
        setState(() {
          busy = false;
          offerManual = true;
          error = tr(
            '$message Můžeš ho zapsat ručně.',
            '$message You can enter it manually.',
          );
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr('Čárový kód', 'Barcode')),
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
            labelText: tr(
              'Číslo pod čárovým kódem',
              'Number below the barcode',
            ),
            errorText: error,
            errorMaxLines: 4,
          ),
          onSubmitted: (_) => _search(),
        ),
        const SizedBox(height: 8),
        Text(
          tr(
            'Kód se odešle do Open Food Facts. Nic jiného se neodesílá.',
            'The code is sent to Open Food Facts. Nothing else is sent.',
          ),
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
        child: Text(tr('Zrušit', 'Cancel')),
      ),
      if (offerManual)
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            BarcodeOutcome(null, controller.text.trim()),
          ),
          child: Text(tr('Zadat ručně', 'Enter manually')),
        ),
      FilledButton(
        onPressed: busy ? null : _search,
        child: Text(tr('Najít', 'Search')),
      ),
    ],
  );
}
