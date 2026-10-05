import 'package:flutter/material.dart';

import '../../core/version.dart';
import '../../state/app_state.dart';
import '../premium/premium_page.dart';
import '../widgets/labels.dart';
import 'file_io.dart';

/// Nastavení: pauza, motiv, záloha, export, smazání dat, o aplikaci.
class SettingsPage extends StatelessWidget {
  final AppState state;
  final FileIo files;
  const SettingsPage(
    this.state, {
    super.key,
    this.files = const PickerFileIo(),
  });

  static const restOptions = [60, 90, 120, 150, 180, 240, 300];

  static String restLabel(int s) => s % 60 == 0
      ? '${s ~/ 60} min'
      : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} min';

  static String _stamp() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void _toast(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save(
    BuildContext context,
    String name,
    String Function() content,
    String mime,
  ) async {
    try {
      final saved = await files.saveText(name, content(), mime);
      if (saved && context.mounted) _toast(context, 'Uloženo: $name');
    } catch (e) {
      if (context.mounted) _toast(context, 'Soubor se nepodařilo uložit: $e');
    }
  }

  Future<void> _restore(BuildContext context) async {
    final String? source;
    try {
      source = await files.pickText(const ['json']);
    } catch (e) {
      if (context.mounted) _toast(context, 'Soubor se nepodařilo otevřít: $e');
      return;
    }
    if (source == null || !context.mounted) return;
    try {
      final count = await state.restoreBackup(source);
      if (context.mounted) {
        _toast(context, 'Obnoveno: ${workoutsLabel(count)}.');
      }
    } on FormatException catch (e) {
      if (context.mounted) _toast(context, e.message);
    } catch (e) {
      if (context.mounted) _toast(context, 'Obnova se nezdařila: $e');
    }
  }

  Future<void> _importHevy(BuildContext context) async {
    final String? source;
    try {
      source = await files.pickText(const ['csv']);
    } catch (e) {
      if (context.mounted) _toast(context, 'Soubor se nepodařilo otevřít: $e');
      return;
    }
    if (source == null || !context.mounted) return;
    try {
      final count = await state.importHevy(source);
      if (context.mounted) {
        _toast(
          context,
          count == 0
              ? 'Nic nového, tyto tréninky už tu jsou.'
              : 'Z Hevy přidáno: ${workoutsLabel(count)}.',
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) _toast(context, e.message);
    } catch (e) {
      if (context.mounted) _toast(context, 'Import se nezdařil: $e');
    }
  }

  Future<void> _wipe(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Smazat všechna data?'),
        content: const Text(
          'Tréninky, vlastní cviky i nastavení v tomto zařízení se trvale '
          'smažou. Nejdřív si ulož zálohu do souboru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialog).colorScheme.error,
              foregroundColor: Theme.of(dialog).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Smazat vše'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.popUntil(context, (r) => r.isFirst);
    await state.wipeAll();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final profile = state.profile;
      final rest = profile.restSeconds;
      final scheme = Theme.of(context).colorScheme;
      final header = Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: scheme.primary);
      Widget section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title, style: header),
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Nastavení')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            section('Trénink'),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Pauza mezi sériemi'),
              trailing: DropdownButton<int>(
                value: restOptions.contains(rest) ? rest : null,
                hint: Text(restLabel(rest)),
                underline: const SizedBox.shrink(),
                items: [
                  for (final s in restOptions)
                    DropdownMenuItem(value: s, child: Text(restLabel(s))),
                ],
                onChanged: (s) => state.setPreferences(restSeconds: s),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Cíl tréninků týdně'),
              trailing: DropdownButton<int>(
                value: profile.weekGoal ?? 0,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('Podle splitu (${state.weekGoal}×)'),
                  ),
                  for (var n = 1; n <= 7; n++)
                    DropdownMenuItem(value: n, child: Text('$n×')),
                ],
                onChanged: (n) => state.setWeekGoal(n == 0 ? null : n),
              ),
            ),
            section('Vzhled'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'dark', label: Text('Tmavý')),
                  ButtonSegment(value: 'light', label: Text('Světlý')),
                  ButtonSegment(value: 'system', label: Text('Systém')),
                ],
                selected: {profile.theme},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    state.setPreferences(theme: s.single),
              ),
            ),
            section('Gym zápisník Pro'),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Co obsahuje Pro'),
              subtitle: Text(
                state.paywall
                    ? 'Zobrazit'
                    : 'Zatím odemčeno zdarma pro testery',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PremiumPage(state)),
              ),
            ),
            section('Data'),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Uložit zálohu'),
              subtitle: const Text('Všechny tréninky a nastavení do souboru'),
              onTap: () => _save(
                context,
                'gymzapisnik-zaloha-${_stamp()}.json',
                state.exportBackup,
                'application/json',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Obnovit ze zálohy'),
              subtitle: const Text('Doplní tréninky ze souboru, nic nesmaže'),
              onTap: () => _restore(context),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Import z Hevy'),
              subtitle: const Text(
                'Soubor workout_data.csv z Hevy (Export data), nic nesmaže',
              ),
              onTap: () => _importHevy(context),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export do Excelu (CSV)'),
              subtitle: const Text('Jedna řádka na sérii'),
              onTap: () => _save(
                context,
                'gymzapisnik-serie-${_stamp()}.csv',
                state.exportCsv,
                'text/csv',
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: scheme.error),
              title: const Text('Smazat všechna data'),
              onTap: () => _wipe(context),
            ),
            section('O aplikaci'),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Gym zápisník'),
              subtitle: Text(
                'Verze $appVersion\n'
                'Data jsou jen v tomto zařízení. Aplikace nenahrazuje '
                'trenéra ani lékaře.',
              ),
              isThreeLine: true,
            ),
          ],
        ),
      );
    },
  );
}
