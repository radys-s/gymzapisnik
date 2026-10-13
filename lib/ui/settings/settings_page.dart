import 'package:flutter/material.dart';

import '../../core/parse.dart';

import 'package:flutter/services.dart';

import '../../core/version.dart';
import '../../notify/notifier.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../onboarding/accent_picker.dart';
import '../premium/premium_page.dart';
import '../program/program_page.dart';
import '../program/program_widgets.dart';
import '../welcome/whats_new.dart';
import '../widgets/labels.dart';
import 'file_io.dart';
import 'legal_page.dart';

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
    String mime, {
    Future<void> Function()? onSaved,
  }) async {
    try {
      final saved = await files.saveText(name, content(), mime);
      if (saved) await onSaved?.call();
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

  static String _clock(int minutes) =>
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  Future<void> _setReminder(BuildContext context, int? minutes) async {
    final ok = await state.setReminder(minutes);
    if (!ok && context.mounted) {
      _toast(
        context,
        'Oznámení nejsou povolená. Zapni je v nastavení telefonu.',
      );
    }
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final current = state.profile.reminderMinutes ?? 18 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: 'Čas připomínky',
    );
    if (picked == null || !context.mounted) return;
    await _setReminder(context, picked.hour * 60 + picked.minute);
  }

  Future<void> _feedback(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: feedbackContact));
    if (!context.mounted) return;
    await showAdaptiveDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog.adaptive(
        title: const Text('Zpětná vazba'),
        content: const Text(
          'Napiš na $feedbackContact (adresa je zkopírovaná). Připiš verzi '
          '$appVersion a co jsi dělal.',
        ),
        actions: [
          adaptiveAction(
            dialog,
            label: 'Zavřít',
            strong: true,
            onPressed: () => Navigator.pop(dialog),
          ),
        ],
      ),
    );
  }

  Future<void> _wipe(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Smazat všechna data?',
      message:
          'Tréninky, vlastní cviky i nastavení v tomto zařízení se trvale '
          'smažou. Nejdřív si ulož zálohu do souboru.',
      confirm: 'Smazat vše',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    Navigator.popUntil(context, (r) => r.isFirst);
    await state.wipeAll();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final p = context.palette;
      final profile = state.profile;
      final rest = profile.restSeconds;
      return LargeTitlePage(
        title: 'Nastavení',
        children: [
          GroupedSection(
            header: 'Trénink',
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.timer_outlined,
                iconColor: _orange,
                title: 'Pauza mezi sériemi',
                trailing: DropdownButton<int>(
                  value: restOptions.contains(rest) ? rest : null,
                  hint: Text(restLabel(rest)),
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(Radii.card),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.secondaryLabel,
                    fontFeatures: tabular,
                  ),
                  items: [
                    for (final s in restOptions)
                      DropdownMenuItem(value: s, child: Text(restLabel(s))),
                  ],
                  onChanged: (s) => state.setPreferences(restSeconds: s),
                ),
              ),
              GroupedRow(
                icon: Icons.flag_outlined,
                iconColor: _green,
                title: 'Frekvence tréninku',
                value: profile.trainingDays == null
                    ? perWeekLabel(state.weekGoal)
                    : [
                        for (final d in profile.trainingDays!)
                          weekdayShort[d - 1],
                      ].join(', '),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProgramPage(state)),
                ),
              ),
            ],
          ),
          GroupedSection(
            header: 'Výživa',
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.egg_outlined,
                iconColor: _teal,
                title: 'Denní cíl bílkovin',
                value: profile.proteinTarget == null
                    ? 'Bez cíle'
                    : '${profile.proteinTarget!.round()} g',
                onTap: () => _editTarget(
                  context,
                  title: 'Denní cíl bílkovin (g)',
                  current: profile.proteinTarget,
                  min: 20,
                  max: 400,
                  hint:
                      'Číslo si zvol sám, třeba podle trenéra nebo lékaře. '
                      'Prázdné pole = bez cíle.',
                  save: (v) => state.setNutritionTargets(
                    protein: v,
                    kcal: profile.kcalTarget,
                  ),
                ),
              ),
              if (!profile.restrictWeightLoss)
                GroupedRow(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: _red,
                  title: 'Denní cíl energie',
                  value: profile.kcalTarget == null
                      ? 'Bez cíle'
                      : '${profile.kcalTarget!.round()} kcal',
                  onTap: () => _editTarget(
                    context,
                    title: 'Denní cíl energie (kcal)',
                    current: profile.kcalTarget,
                    min: 1000,
                    max: 6000,
                    hint: 'Prázdné pole = bez cíle.',
                    save: (v) => state.setNutritionTargets(
                      protein: profile.proteinTarget,
                      kcal: v,
                    ),
                  ),
                ),
            ],
          ),
          GroupedSection(
            header: 'Vzhled',
            dividerIndent: _indent,
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.m),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'system', label: Text('Systém')),
                    ButtonSegment(value: 'light', label: Text('Světlý')),
                    ButtonSegment(value: 'dark', label: Text('Tmavý')),
                  ],
                  selected: {profile.theme},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      state.setPreferences(theme: s.single),
                ),
              ),
              GroupedRow(
                icon: Icons.palette_outlined,
                iconColor: p.gradient.last,
                title: 'Vzhled a barva',
                subtitle:
                    '${Look.parse(profile.look).label} · '
                    '${Accent.parse(profile.accent).label}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AppearancePage(state)),
                ),
              ),
            ],
          ),
          GroupedSection(
            header: 'Připomínky',
            footer: state.notifier.supported
                ? 'Připomínka přijde jen v plánované dny a jen když týdenní '
                      'cíl ještě není splněný.'
                : null,
            dividerIndent: _indent,
            children: [
              if (!state.notifier.supported)
                const GroupedRow(
                  icon: Icons.notifications_off_outlined,
                  iconColor: _grey,
                  title: 'Připomínky tréninku',
                  subtitle:
                      'Ve webové verzi nejsou dostupné. Denní úkol od kouče '
                      'uvidíš po otevření aplikace.',
                )
              else ...[
                if (state.notifier is RestNotifier)
                  MergeSemantics(
                    child: GroupedRow(
                      onTap: () => _setRestAlerts(context, !state.restAlerts),
                      icon: Icons.timer_outlined,
                      iconColor: _orange,
                      title: 'Upozornit na konec pauzy',
                      subtitle:
                          'Místní oznámení i při zamčeném telefonu. '
                          'Android může doručení opozdit.',
                      trailing: Switch.adaptive(
                        value: state.restAlerts,
                        onChanged: (on) => _setRestAlerts(context, on),
                      ),
                    ),
                  ),
                MergeSemantics(
                  child: GroupedRow(
                    onTap: () => _setReminder(
                      context,
                      profile.reminderMinutes == null ? 18 * 60 : null,
                    ),
                    icon: Icons.notifications_outlined,
                    iconColor: _red,
                    title: 'Připomínat trénink',
                    trailing: Switch.adaptive(
                      value: profile.reminderMinutes != null,
                      onChanged: (on) =>
                          _setReminder(context, on ? 18 * 60 : null),
                    ),
                  ),
                ),
                if (profile.reminderMinutes != null)
                  GroupedRow(
                    icon: Icons.schedule_rounded,
                    iconColor: _blue,
                    title: 'Čas připomínky',
                    value: _clock(profile.reminderMinutes!),
                    onTap: () => _pickReminderTime(context),
                  ),
              ],
            ],
          ),
          GroupedSection(
            header: 'Gym zápisník Pro',
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.workspace_premium_outlined,
                iconColor: _purple,
                title: 'Co obsahuje Pro',
                subtitle: state.paywall
                    ? null
                    : 'Zatím odemčeno zdarma pro testery',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PremiumPage(state)),
                ),
              ),
            ],
          ),
          GroupedSection(
            header: 'Data',
            footer:
                'Data jsou jen v tomto zařízení. Zálohu si ulož do souboru '
                'aspoň jednou za pár týdnů.',
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.save_alt_rounded,
                iconColor: _blue,
                title: 'Uložit zálohu',
                subtitle: 'Všechny tréninky a nastavení do souboru',
                chevron: false,
                onTap: () => _save(
                  context,
                  'gymzapisnik-zaloha-${_stamp()}.json',
                  state.exportBackup,
                  'application/json',
                  onSaved: state.markBackedUp,
                ),
              ),
              GroupedRow(
                icon: Icons.restore_rounded,
                iconColor: _green,
                title: 'Obnovit ze zálohy',
                subtitle: 'Doplní tréninky ze souboru, nic nesmaže',
                chevron: false,
                onTap: () => _restore(context),
              ),
              GroupedRow(
                icon: Icons.swap_horiz_rounded,
                iconColor: _indigo,
                title: 'Import z Hevy',
                subtitle:
                    'Soubor workout_data.csv z Hevy (Export data), nic nesmaže',
                chevron: false,
                onTap: () => _importHevy(context),
              ),
              GroupedRow(
                icon: Icons.table_chart_outlined,
                iconColor: _teal,
                title: 'Export do Excelu (CSV)',
                subtitle: 'Jedna řádka na sérii',
                chevron: false,
                onTap: () => _save(
                  context,
                  'gymzapisnik-serie-${_stamp()}.csv',
                  state.exportCsv,
                  'text/csv',
                ),
              ),
            ],
          ),
          GroupedSection(
            children: [
              GroupedRow(
                title: 'Smazat všechna data',
                destructive: true,
                chevron: false,
                onTap: () => _wipe(context),
              ),
            ],
          ),
          GroupedSection(
            header: 'O aplikaci',
            footer:
                'Gym zápisník, verze $appVersion. Aplikace nenahrazuje '
                'trenéra ani lékaře.',
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.mail_outline_rounded,
                iconColor: _blue,
                title: 'Napsat zpětnou vazbu',
                subtitle: 'Co tě zdrželo, co chybělo, co nefunguje',
                chevron: false,
                onTap: () => _feedback(context),
              ),
              GroupedRow(
                icon: Icons.auto_awesome_outlined,
                iconColor: _purple,
                title: 'Novinky',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WhatsNewPage()),
                ),
              ),
              GroupedRow(
                icon: Icons.policy_outlined,
                iconColor: _grey,
                title: 'Podmínky a soukromí',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegalPage()),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  Future<void> _setRestAlerts(BuildContext context, bool on) async {
    try {
      final ok = await state.setRestAlerts(on);
      if (!ok && context.mounted) {
        _toast(
          context,
          'Oznámení nejsou povolená. Zapni je v nastavení telefonu.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        _toast(context, 'Nastavení se nepodařilo uložit. Zkus to znovu.');
      }
    }
  }
}

/// Odsazení oddělovače za barevnou ikonou řádku.
const _indent = Space.l + 30 + Space.m;

// Barvy ikon jako v Nastavení iPhonu (stejné ve světlém i tmavém).
const _orange = Color(0xFFFF9500);
const _green = Color(0xFF34C759);
const _teal = Color(0xFF30B0C7);
const _blue = Color(0xFF007AFF);
const _indigo = Color(0xFF5856D6);
const _purple = Color(0xFFAF52DE);
const _red = Color(0xFFFF3B30);
const _grey = Color(0xFF8E8E93);

/// Dialog pro vlastní denní cíl. Prázdné pole cíl zruší.
Future<void> _editTarget(
  BuildContext context, {
  required String title,
  required double? current,
  required double min,
  required double max,
  required String hint,
  required Future<void> Function(double? value) save,
}) async {
  final result = await showDialog<(double?,)>(
    context: context,
    builder: (_) => _TargetDialog(
      title: title,
      current: current,
      min: min,
      max: max,
      hint: hint,
    ),
  );
  if (result != null) await save(result.$1);
}

class _TargetDialog extends StatefulWidget {
  final String title;
  final double? current;
  final double min;
  final double max;
  final String hint;
  const _TargetDialog({
    required this.title,
    required this.current,
    required this.min,
    required this.max,
    required this.hint,
  });

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  late final controller = TextEditingController(
    text: widget.current == null ? '' : widget.current!.round().toString(),
  );
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _save() {
    final raw = controller.text.trim();
    if (raw.isEmpty) {
      Navigator.pop(context, (null,));
      return;
    }
    final v = parseNum(raw);
    if (v == null || v < widget.min || v > widget.max) {
      setState(
        () => error =
            'Zadej číslo od ${widget.min.round()} do ${widget.max.round()}.',
      );
      return;
    }
    Navigator.pop(context, (v,));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        helperText: widget.hint,
        helperMaxLines: 3,
        errorText: error,
      ),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Zrušit'),
      ),
      FilledButton(onPressed: _save, child: const Text('Uložit')),
    ],
  );
}
