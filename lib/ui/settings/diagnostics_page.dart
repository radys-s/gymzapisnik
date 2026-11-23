import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/diagnostics.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/version.dart';
import '../../data/storage_status.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Úložiště jednou větou (web: smí prohlížeč data smazat?).
String? storageStatusLine() => switch (storagePersisted()) {
  true => tr('Prohlížeč data sám nesmaže.', 'Your browser keeps the data.'),
  false => tr(
    'Prohlížeč může data smazat při nedostatku místa. Přidej aplikaci '
        'na plochu a pravidelně si ukládej zálohu.',
    'Your browser may clear data when space runs low. Add the app to your '
        'home screen and back up regularly.',
  ),
  null => null,
};

/// Posledních pár chyb za běh aplikace a stav úložiště. Pro testery:
/// jedním klepnutím zkopírují text a pošlou ho vývojáři.
class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Diagnostics.changes,
    builder: (context, _, _) {
      final entries = Diagnostics.entries;
      final text = Theme.of(context).textTheme;
      final p = context.palette;
      return LargeTitlePage(
        title: tr('Diagnostika', 'Diagnostics'),
        children: [
          GroupedSection(
            header: tr('Úložiště', 'Storage'),
            children: [
              GroupedRow(
                icon: Icons.storage_rounded,
                title:
                    storageStatusLine() ??
                    tr(
                      'Data drží systém telefonu.',
                      'Data is kept by your phone.',
                    ),
              ),
            ],
          ),
          if (entries.isEmpty)
            EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: tr('Žádné chyby', 'No errors'),
              message: tr(
                'Od spuštění aplikace se nic nepokazilo.',
                'Nothing has gone wrong since launch.',
              ),
            )
          else ...[
            GroupedSection(
              header: tr(
                'Chyby od spuštění (${entries.length})',
                'Errors since launch (${entries.length})',
              ),
              footer: tr(
                'Jen v tomto zařízení a jen do zavření aplikace. Před '
                    'odesláním si text projdi.',
                'Only on this device and only until you close the app. '
                    'Review the text before sending.',
              ),
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.all(Space.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatTime(e.at)} · ${e.where}',
                          style: text.labelMedium?.copyWith(
                            color: p.secondaryLabel,
                            fontFeatures: tabular,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.message,
                          style: text.bodyMedium,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.l),
            PrimaryButton(
              tr('Zkopírovat pro vývojáře', 'Copy for developers'),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: Diagnostics.report(version: appVersion)),
                );
                if (context.mounted)
                  showToast(context, tr('Zkopírováno.', 'Copied.'));
              },
            ),
            const SizedBox(height: Space.s),
            SecondaryButton(
              tr('Vymazat', 'Clear'),
              onPressed: Diagnostics.clear,
            ),
          ],
          const SizedBox(height: Space.xxl),
        ],
      );
    },
  );
}
