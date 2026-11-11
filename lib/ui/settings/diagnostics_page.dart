import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/diagnostics.dart';
import '../../core/format.dart';
import '../../core/version.dart';
import '../../data/storage_status.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Úložiště jednou větou (web: smí prohlížeč data smazat?).
String? storageStatusLine() => switch (storagePersisted()) {
  true => 'Prohlížeč data sám nesmaže.',
  false =>
    'Prohlížeč může data smazat při nedostatku místa. Přidej aplikaci '
        'na plochu a pravidelně si ukládej zálohu.',
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
        title: 'Diagnostika',
        children: [
          GroupedSection(
            header: 'Úložiště',
            children: [
              GroupedRow(
                icon: Icons.storage_rounded,
                title: storageStatusLine() ?? 'Data drží systém telefonu.',
              ),
            ],
          ),
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Žádné chyby',
              message: 'Od spuštění aplikace se nic nepokazilo.',
            )
          else ...[
            GroupedSection(
              header: 'Chyby od spuštění (${entries.length})',
              footer:
                  'Jen v tomto zařízení a jen do zavření aplikace. Text '
                  'neobsahuje tréninky ani jídla.',
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
              'Zkopírovat pro vývojáře',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: Diagnostics.report(version: appVersion)),
                );
                if (context.mounted) showToast(context, 'Zkopírováno.');
              },
            ),
            const SizedBox(height: Space.s),
            SecondaryButton('Vymazat', onPressed: Diagnostics.clear),
          ],
          const SizedBox(height: Space.xxl),
        ],
      );
    },
  );
}
