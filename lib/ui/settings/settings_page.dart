import '../../core/i18n.dart';
import '../../coach/plan_quiz.dart' show TrainingPlace;
import 'my_gym_page.dart';

import 'package:flutter/material.dart';

import '../../core/parse.dart';

import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/version.dart';
import '../../domain/profile.dart';
import '../../notify/notifier.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../premium/premium_page.dart';
import '../program/program_page.dart';
import '../program/program_widgets.dart';
import '../welcome/whats_new.dart';
import '../widgets/labels.dart';
import 'diagnostics_page.dart';
import 'file_io.dart';
import 'legal_page.dart';
import 'wipe_dialog.dart';

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
      if (saved && context.mounted) {
        _toast(context, tr('Uloženo: $name', 'Saved: $name'));
      }
    } catch (e) {
      if (context.mounted) {
        _toast(
          context,
          tr('Soubor se nepodařilo uložit: $e', 'Could not save file: $e'),
        );
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    final String? source;
    try {
      source = await files.pickText(const ['json']);
    } catch (e) {
      if (context.mounted) {
        _toast(
          context,
          tr('Soubor se nepodařilo otevřít: $e', 'Could not open file: $e'),
        );
      }
      return;
    }
    if (source == null || !context.mounted) return;
    try {
      final count = await state.restoreBackup(source);
      if (context.mounted) {
        _toast(context, 'Obnoveno: ${workoutsLabel(count)}.');
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        _toast(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        _toast(context, tr('Obnova se nezdařila: $e', 'Restore failed: $e'));
      }
    }
  }

  Future<void> _importHevy(BuildContext context) async {
    final String? source;
    try {
      source = await files.pickText(const ['csv']);
    } catch (e) {
      if (context.mounted) {
        _toast(
          context,
          tr('Soubor se nepodařilo otevřít: $e', 'Could not open file: $e'),
        );
      }
      return;
    }
    if (source == null || !context.mounted) return;
    try {
      final count = await state.importHevy(source);
      if (context.mounted) {
        _toast(
          context,
          count == 0
              ? tr(
                  'Nic nového, tyto tréninky už tu jsou.',
                  'Nothing new, these workouts are already here.',
                )
              : tr(
                  'Z Hevy přidáno: ${workoutsLabel(count)}.',
                  'Added from Hevy: ${workoutsLabel(count)}.',
                ),
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        _toast(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        _toast(context, tr('Import se nezdařil: $e', 'Import failed: $e'));
      }
    }
  }

  static String _clock(int minutes) =>
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  Future<void> _setReminder(BuildContext context, int? minutes) async {
    final ok = await state.setReminder(minutes);
    if (!ok && context.mounted) {
      _toast(
        context,
        tr(
          'Oznámení nejsou povolená. Zapni je v nastavení telefonu.',
          'Notifications are not allowed. Enable them in your phone settings.',
        ),
      );
    }
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final current = state.profile.reminderMinutes ?? 18 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: tr('Čas připomínky', 'Reminder time'),
    );
    if (picked == null || !context.mounted) return;
    await _setReminder(context, picked.hour * 60 + picked.minute);
  }

  Future<void> _feedback(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: feedbackContact));
    if (!context.mounted) return;
    await showAdaptiveDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog.adaptive(
        title: Text(tr('Zpětná vazba', 'Feedback')),
        content: Text(
          tr(
            'Napiš na $feedbackContact (adresa je zkopírovaná). Připiš verzi '
                '$appVersion a co jsi dělal.',
            'Write to $feedbackContact (address copied). Include version '
                '$appVersion and what you were doing.',
          ),
        ),
        actions: [
          adaptiveAction(
            dialog,
            label: tr('Zavřít', 'Close'),
            strong: true,
            onPressed: () => Navigator.pop(dialog),
          ),
        ],
      ),
    );
  }

  Future<void> _wipe(BuildContext context) async {
    final ok = await confirmWipe(context);
    if (!ok || !context.mounted) return;
    try {
      await state.wipeAll();
    } catch (_) {
      if (context.mounted) {
        showToast(
          context,
          tr(
            'Data se nepodařilo smazat. Zkus to znovu.',
            'Could not delete data. Try again.',
          ),
        );
      }
      return;
    }
    if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.resting,
    builder: (context, _) {
      final p = context.palette;
      final profile = state.profile;
      final rest = profile.restSeconds;
      return LargeTitlePage(
        title: tr('Nastavení', 'Settings'),
        children: [
          GroupedSection(
            header: tr('Trénink', 'Training'),
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.timer_outlined,
                title: tr('Pauza mezi sériemi', 'Rest between sets'),
                verticalPadding: 0,
                trailing: DropdownButton<int>(
                  value: restOptions.contains(rest) ? rest : null,
                  hint: Text(restLabel(rest)),
                  underline: const SizedBox.shrink(),
                  borderRadius: context.palette.cardRadius(),
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
                icon: Icons.exposure_rounded,
                title: tr('Krok tlačítek +/−', '+/− button step'),
                verticalPadding: 0,
                trailing: DropdownButton<double>(
                  value: profile.weightStep,
                  underline: const SizedBox.shrink(),
                  borderRadius: context.palette.cardRadius(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.secondaryLabel,
                    fontFeatures: tabular,
                  ),
                  items: [
                    for (final s in weightSteps)
                      DropdownMenuItem(
                        value: s,
                        child: Text('${formatKg(s)} kg'),
                      ),
                  ],
                  onChanged: (s) => state.setPreferences(weightStep: s),
                ),
              ),
              GroupedRow(
                icon: Icons.flag_outlined,
                title: tr('Frekvence tréninku', 'Training frequency'),
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
              GroupedRow(
                icon: Icons.fitness_center_rounded,
                title: tr('Moje posilovna', 'My gym'),
                value: (state.planAnswers?.place ?? TrainingPlace.gym).label,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyGymPage(state)),
                ),
              ),
            ],
          ),
          GroupedSection(
            header: tr('Výživa', 'Nutrition'),
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.egg_outlined,
                title: tr('Denní cíl bílkovin', 'Daily protein target'),
                value: profile.proteinTarget == null
                    ? tr('Bez cíle', 'No target')
                    : '${profile.proteinTarget!.round()} g',
                onTap: () => _editTarget(
                  context,
                  title: tr(
                    'Denní cíl bílkovin (g)',
                    'Daily protein target (g)',
                  ),
                  current: profile.proteinTarget,
                  min: 20,
                  max: 400,
                  hint: tr(
                    'Číslo si zvol sám, třeba podle trenéra nebo lékaře. '
                        'Prázdné pole = bez cíle.',
                    'Pick your own number, for example with your trainer or '
                        'doctor. Empty field = no target.',
                  ),
                  save: (v) => state.setNutritionTargets(
                    protein: v,
                    kcal: profile.kcalTarget,
                  ),
                ),
              ),
              if (!profile.restrictWeightLoss)
                GroupedRow(
                  icon: Icons.local_fire_department_outlined,
                  title: tr('Denní cíl energie', 'Daily calorie target'),
                  value: profile.kcalTarget == null
                      ? tr('Bez cíle', 'No target')
                      : '${profile.kcalTarget!.round()} kcal',
                  onTap: () => _editTarget(
                    context,
                    title: tr(
                      'Denní cíl energie (kcal)',
                      'Daily calorie target (kcal)',
                    ),
                    current: profile.kcalTarget,
                    min: 1000,
                    max: 6000,
                    hint: tr(
                      'Prázdné pole = bez cíle.',
                      'Empty field = no target.',
                    ),
                    save: (v) => state.setNutritionTargets(
                      protein: profile.proteinTarget,
                      kcal: v,
                    ),
                  ),
                ),
            ],
          ),
          GroupedSection(
            header: tr('Připomínky', 'Reminders'),
            footer: state.notifier.supported
                ? tr(
                    'Připomínka přijde jen v plánované dny a jen když týdenní '
                        'cíl ještě není splněný.',
                    'Reminders come only on planned days and only while the '
                        'weekly goal is not complete.',
                  )
                : null,
            dividerIndent: _indent,
            children: [
              if (!state.notifier.supported)
                GroupedRow(
                  icon: Icons.notifications_off_outlined,
                  title: tr('Připomínky tréninku', 'Workout reminders'),
                  subtitle: tr(
                    'Ve webové verzi nejsou dostupné. Denní úkol od kouče '
                        'uvidíš po otevření aplikace.',
                    'Not available on the web. You will see your coach’s '
                        'daily task when you open the app.',
                  ),
                )
              else ...[
                if (state.notifier is RestNotifier)
                  MergeSemantics(
                    child: GroupedRow(
                      onTap: () => _setRestAlerts(context, !state.restAlerts),
                      icon: Icons.timer_outlined,
                      title: tr(
                        'Upozornit na konec pauzy',
                        'Alert when rest ends',
                      ),
                      subtitle: tr(
                        'Místní oznámení i při zamčeném telefonu. '
                            'Android může doručení opozdit.',
                        'Local notification even with a locked phone. '
                            'Android may delay delivery.',
                      ),
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
                    title: tr('Připomínat trénink', 'Remind me to train'),
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
                    title: tr('Čas připomínky', 'Reminder time'),
                    value: _clock(profile.reminderMinutes!),
                    onTap: () => _pickReminderTime(context),
                  ),
              ],
            ],
          ),
          // Bez paywallu je všechno odemčené: nabídka Pro by jen mátla.
          if (state.paywall)
            GroupedSection(
              header: tr('Gym zápisník Pro', 'Gym Log Pro'),
              dividerIndent: _indent,
              children: [
                GroupedRow(
                  icon: Icons.workspace_premium_outlined,
                  title: tr('Co obsahuje Pro', 'What Pro includes'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PremiumPage(state)),
                  ),
                ),
              ],
            ),
          GroupedSection(
            header: tr('Data', 'Data'),
            footer: [
              tr(
                'Data jsou jen v tomto zařízení. Zálohu si ulož do souboru '
                    'aspoň jednou za pár týdnů.',
                'Data is only on this device. Save a backup to a file every '
                    'few weeks.',
              ),
              ?storageStatusLine(),
            ].join(' '),
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.save_alt_rounded,
                title: tr('Uložit zálohu', 'Save a backup'),
                subtitle: tr(
                  'Všechny tréninky a nastavení do souboru',
                  'All workouts and settings to a file',
                ),
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
                title: tr('Obnovit ze zálohy', 'Restore from backup'),
                subtitle: tr(
                  'Doplní tréninky ze souboru, nic nesmaže',
                  'Adds workouts from a file, deletes nothing',
                ),
                chevron: false,
                onTap: () => _restore(context),
              ),
              GroupedRow(
                icon: Icons.swap_horiz_rounded,
                title: tr('Import z Hevy', 'Import from Hevy'),
                subtitle: tr(
                  'Soubor workout_data.csv z Hevy (Export data), nic nesmaže',
                  'Hevy workout_data.csv file (Export data), deletes nothing',
                ),
                chevron: false,
                onTap: () => _importHevy(context),
              ),
              GroupedRow(
                icon: Icons.table_chart_outlined,
                title: tr('Export do Excelu (CSV)', 'Export to Excel (CSV)'),
                subtitle: tr('Jedna řádka na sérii', 'One row per set'),
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
            header: tr('O aplikaci', 'About'),
            footer: tr(
              'Gym zápisník, verze $appVersion. Aplikace nenahrazuje '
                  'trenéra ani lékaře.',
              'Gym Log, version $appVersion. The app does not replace '
                  'a trainer or a doctor.',
            ),
            dividerIndent: _indent,
            children: [
              GroupedRow(
                icon: Icons.language_rounded,
                title: tr('Jazyk', 'Language'),
                subtitle: 'Čeština · English',
                value: state.profile.appLanguage.native,
                onTap: () => _pickLanguage(context),
              ),
              if (feedbackContact.isNotEmpty)
                GroupedRow(
                  icon: Icons.mail_outline_rounded,
                  title: tr('Napsat zpětnou vazbu', 'Send feedback'),
                  subtitle: tr(
                    'Co tě zdrželo, co chybělo, co nefunguje',
                    'What slowed you down, what was missing, what broke',
                  ),
                  chevron: false,
                  onTap: () => _feedback(context),
                ),
              GroupedRow(
                icon: Icons.auto_awesome_outlined,
                title: tr('Novinky', "What's new"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WhatsNewPage()),
                ),
              ),
              GroupedRow(
                icon: Icons.policy_outlined,
                title: tr('Podmínky a soukromí', 'Terms and privacy'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegalPage()),
                ),
              ),
              GroupedRow(
                icon: Icons.bug_report_outlined,
                title: tr('Diagnostika', 'Diagnostics'),
                subtitle: tr(
                  'Chyby od spuštění a stav úložiště',
                  'Errors since launch and storage status',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiagnosticsPage()),
                ),
              ),
            ],
          ),
          // Schválně až úplně dole a přes víc kroků, ať se nedá smazat omylem.
          GroupedSection(
            children: [
              GroupedRow(
                title: tr('Smazat všechna data', 'Delete all data'),
                destructive: true,
                chevron: false,
                onTap: () => _wipe(context),
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
          tr(
            'Oznámení nejsou povolená. Zapni je v nastavení telefonu.',
            'Notifications are not allowed. Enable them in your phone settings.',
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        _toast(
          context,
          tr(
            'Nastavení se nepodařilo uložit. Zkus to znovu.',
            'Could not save settings. Try again.',
          ),
        );
      }
    }
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final current = state.profile.appLanguage;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                tr('Jazyk', 'Language'),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final lang in AppLang.values)
              ListTile(
                title: Text(lang.native),
                trailing: lang == current
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (lang != current) await state.setAppLanguage(lang);
                },
              ),
            const SizedBox(height: Space.s),
          ],
        ),
      ),
    );
  }
}

/// Odsazení oddělovače za barevnou ikonou řádku.
const _indent = Space.l + 30 + Space.m;

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
        () => error = tr(
          'Zadej číslo od ${widget.min.round()} do ${widget.max.round()}.',
          'Enter a number from ${widget.min.round()} to ${widget.max.round()}.',
        ),
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
        child: Text(tr('Zrušit', 'Cancel')),
      ),
      FilledButton(onPressed: _save, child: Text(tr('Uložit', 'Save'))),
    ],
  );
}
