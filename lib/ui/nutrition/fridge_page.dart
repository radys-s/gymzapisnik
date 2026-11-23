import 'package:flutter/material.dart';

import '../../ai/fridge_coach.dart';
import '../../ai/photo.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/parse.dart';
import '../../state/app_state.dart';
import '../design/tokens.dart';
import '../design/components.dart';
import '../widgets/ai_photo.dart';
import 'meal_ideas_page.dart';

export '../widgets/ai_photo.dart' show PhotoPicker, confirmAiNotice, pickPhoto;

String itemAmount(PantryItem i) {
  final a = i.amount;
  if (a == null) return '';
  return '${formatKg(double.parse(a.toStringAsFixed(1)))} '
      '${i.unit ?? tr('(jednotka neznámá)', '(unit unknown)')}';
}

/// „Co mám v ledničce“: fotka -> seznam potravin -> návrhy jídel.
class FridgePage extends StatefulWidget {
  final AppState state;
  final PhotoPicker picker;
  const FridgePage(this.state, {super.key, this.picker = pickPhoto});

  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  late List<PantryItem> items = [...widget.state.pantry];

  /// Názvy (malými písmeny) vynechané z návrhu.
  late Set<String> skipped = {...state.pantryExcluded};
  late int minutes = state.pantryMinutes;
  String? busy;
  bool inFlight = false;
  String? error;
  int requestId = 0;

  void _cancel() {
    requestId++;
    final coach = state.coach;
    if (coach is CancellableFridgeCoach) {
      (coach as CancellableFridgeCoach).cancelPending();
    }
    setState(() {
      inFlight = false;
      busy = null;
    });
  }

  @override
  void dispose() {
    requestId++;
    final coach = state.coach;
    if (coach is CancellableFridgeCoach) {
      (coach as CancellableFridgeCoach).cancelPending();
    }
    super.dispose();
  }

  AppState get state => widget.state;
  bool get aiEnabled => state.coach.enabled;

  Future<void> _store(List<PantryItem> next) async {
    await state.savePantry(next);
    if (mounted) setState(() => items = next);
  }

  Future<void> _scan(bool camera) async {
    if (inFlight) return;
    final request = ++requestId;
    setState(() {
      inFlight = true;
      error = null;
    });
    try {
      if (!await confirmAiNotice(context, state) ||
          !mounted ||
          request != requestId) {
        return;
      }
      setState(() => error = null);
      final raw = await widget.picker(camera);
      if (raw == null || !mounted || request != requestId) return;
      setState(() => busy = tr('Prohlížím fotku…', 'Reading photo…'));
      final jpeg = prepareJpeg(raw);
      if (jpeg == null) {
        setState(() {
          busy = null;
          error = tr(
            'Tenhle formát fotky neumím přečíst. Zkus jinou.',
            'I cannot read this photo format. Try another one.',
          );
        });
        return;
      }
      final result = await state.coach.scanFridge(jpeg);
      if (!mounted || request != requestId) return;
      switch (result) {
        case AiOk(:final value):
          if (value.isEmpty) {
            setState(
              () => error = tr(
                'Na fotce AI žádné jídlo nenašla. Můžeš ho přidat ručně.',
                'AI found no food in the photo. You can add it manually.',
              ),
            );
            break;
          }
          setState(() => busy = null);
          final confirmed = await Navigator.push<List<PantryItem>>(
            context,
            MaterialPageRoute(builder: (_) => _PhotoReviewPage(value)),
          );
          if (!mounted || request != requestId || confirmed == null) return;
          await _store(mergePantry(items, confirmed));
          if (!mounted || request != requestId) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  tr(
                    'Potvrzený seznam je uložený. Shodné potraviny mají aktualizované množství.',
                    'Confirmed list saved. Matching foods have updated amounts.',
                  ),
                ),
              ),
            );
        case AiError(:final message):
          setState(() {
            busy = null;
            error = message;
          });
      }
    } catch (_) {
      if (mounted && request == requestId) {
        setState(
          () => error = tr(
            'Fotku nebo seznam se nepodařilo '
                'zpracovat a uložit. Zkus to znovu.',
            'Could not process and save the photo or list. Try again.',
          ),
        );
      }
    } finally {
      if (mounted && request == requestId) {
        setState(() {
          busy = null;
          inFlight = false;
        });
      }
    }
  }

  Future<void> _edit([int? index]) async {
    final edited = await showDialog<PantryItem>(
      context: context,
      builder: (_) => _ItemDialog(index == null ? null : items[index]),
    );
    if (edited == null || !mounted) return;
    if (items.indexed.any(
      (pair) =>
          pair.$1 != index && pantryKey(pair.$2.name) == pantryKey(edited.name),
    )) {
      setState(
        () => error = tr(
          'Tato potravina už v seznamu je. Uprav její množství.',
          'This food is already in the list. Edit its amount.',
        ),
      );
      return;
    }
    final next = [...items];
    if (index == null) {
      next.add(edited);
    } else {
      // Vyřazení drží jen přejmenování; změna množství ho nezruší.
      final before = pantryKey(items[index].name);
      final after = pantryKey(edited.name);
      if (before != after && skipped.remove(before)) skipped.add(after);
      next[index] = edited;
    }
    await _saveList(next);
  }

  Future<void> _remove(int index) async {
    // Během ukládání nic neměnit, jinak se výběr tiše rozejde se seznamem.
    if (inFlight) return;
    final removed = items[index];
    final wasSkipped = skipped.remove(pantryKey(removed.name));
    await _saveList([...items]..removeAt(index));
    if (!mounted ||
        items.any((i) => pantryKey(i.name) == pantryKey(removed.name))) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr('Odebráno: ${removed.name}', 'Removed: ${removed.name}'),
        ),
        action: SnackBarAction(
          label: tr('Vrátit', 'Undo'),
          onPressed: () async {
            if (inFlight ||
                items.any(
                  (i) => pantryKey(i.name) == pantryKey(removed.name),
                )) {
              return;
            }
            if (wasSkipped) skipped.add(pantryKey(removed.name));
            await _saveList(
              [...items]..insert(index.clamp(0, items.length), removed),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveList(List<PantryItem> next) async {
    if (inFlight) return;
    setState(() {
      inFlight = true;
      busy = tr('Ukládám seznam…', 'Saving list…');
      error = null;
    });
    try {
      await _store(next);
      await state.savePantrySelection(skipped, minutes);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = tr(
            'Seznam se nepodařilo uložit. '
                'Zkus změnu znovu; aplikaci zatím nezavírej.',
            'Could not save the list. Try the change again; keep the app open.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = null;
          inFlight = false;
        });
      }
    }
  }

  Future<void> _suggest() async {
    if (inFlight) return;
    final request = ++requestId;
    final chosen = [
      for (final i in items)
        if (!skipped.contains(pantryKey(i.name))) i,
    ];
    if (chosen.isEmpty) {
      setState(
        () => error = tr(
          'Vyber aspoň jednu potravinu.',
          'Pick at least one food.',
        ),
      );
      return;
    }
    if (chosen.length > 40) {
      setState(
        () => error = tr(
          'Pro návrh vyber nejvýš 40 potravin.',
          'Pick at most 40 foods for suggestions.',
        ),
      );
      return;
    }
    setState(() {
      inFlight = true;
      error = null;
    });
    try {
      if (!await confirmAiNotice(context, state) ||
          !mounted ||
          request != requestId) {
        return;
      }
      setState(() => busy = tr('Vymýšlím jídla…', 'Coming up with meals…'));
      final result = await state.coach.suggestMeals(
        chosen,
        state.mealContext(maxMinutes: minutes),
      );
      if (!mounted || request != requestId) return;
      setState(() => busy = null);
      switch (result) {
        case AiOk(:final value):
          await state.saveMealIdeas(value);
          if (!mounted || request != requestId) return;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MealIdeasPage(state, value)),
          );
        case AiError(:final message):
          setState(() => error = message);
      }
    } catch (_) {
      if (mounted && request == requestId) {
        setState(
          () => error = tr(
            'Návrh se nepodařilo načíst. '
                'Zkus to znovu; seznam zůstává uložený.',
            'Could not load suggestions. Try again; your list stays saved.',
          ),
        );
      }
    } finally {
      if (mounted && request == requestId) {
        setState(() {
          busy = null;
          inFlight = false;
        });
      }
    }
  }

  Future<void> _selection({String? name, bool? include, int? time}) async {
    if (inFlight) return;
    setState(() => inFlight = true);
    final next = {...skipped};
    if (name != null) {
      include == true
          ? next.remove(pantryKey(name))
          : next.add(pantryKey(name));
    }
    try {
      await state.savePantrySelection(next, time ?? minutes);
      if (mounted) {
        setState(() {
          skipped = next;
          minutes = time ?? minutes;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = tr(
            'Výběr se nepodařilo uložit. Zkus to znovu.',
            'Could not save selection. Try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => inFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final working = inFlight;
    final left = state.proteinLeft();
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 21;
    final photos = [
      OutlinedButton.icon(
        onPressed: working || !aiEnabled ? null : () => _scan(true),
        icon: const Icon(Icons.photo_camera_outlined),
        label: Text(tr('Vyfotit', 'Take photo')),
      ),
      OutlinedButton.icon(
        onPressed: working || !aiEnabled ? null : () => _scan(false),
        icon: const Icon(Icons.photo_library_outlined),
        label: Text(tr('Z galerie', 'From gallery')),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Co mám v ledničce', 'What is in my fridge')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          Space.s,
          Space.page,
          Space.xxl,
        ),
        children: [
          Text(
            tr('1  Přidej potraviny', '1  Add food'),
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          if (!aiEnabled)
            Panel(
              child: Text(
                tr(
                  'AI v této verzi aplikace zatím není zapnutá. Seznam '
                      'potravin si můžeš vést ručně.',
                  'AI is not enabled in this version. You can still keep '
                      'a grocery list by hand.',
                ),
                style: text.bodyMedium,
              ),
            ),
          if (largeText)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [photos.first, const SizedBox(height: 8), photos.last],
            )
          else
            Row(
              children: [
                Expanded(child: photos.first),
                const SizedBox(width: 12),
                Expanded(child: photos.last),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Vyfoť otevřenou ledničku nebo potraviny na stole. Seznam pak '
                  'můžeš upravit.',
              'Take a photo of your open fridge or food on the table. '
                  'You can edit the list afterwards.',
            ),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (busy != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(busy!),
                  if (busy == tr('Prohlížím fotku…', 'Reading photo…') ||
                      busy == tr('Vymýšlím jídla…', 'Coming up with meals…'))
                    TextButton(
                      onPressed: _cancel,
                      child: Text(tr('Zrušit čekání', 'Cancel waiting')),
                    ),
                ],
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: TextStyle(color: scheme.error)),
            ),
          const SizedBox(height: 16),
          if (largeText) ...[
            Text(
              items.isEmpty
                  ? tr('2  Zkontroluj seznam', '2  Review the list')
                  : tr('2  Vyber potraviny', '2  Pick foods'),
              style: text.titleMedium,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: working ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: Text(tr('Přidat ručně', 'Add manually')),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    items.isEmpty
                        ? tr('2  Zkontroluj seznam', '2  Review the list')
                        : tr('2  Vyber potraviny', '2  Pick foods'),
                    style: text.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: working ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: Text(tr('Přidat ručně', 'Add manually')),
                ),
              ],
            ),
          for (final (index, item) in items.indexed)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: !skipped.contains(pantryKey(item.name)),
              onChanged: working
                  ? null
                  : (on) => _selection(name: item.name, include: on),
              title: Text(item.name),
              subtitle: itemAmount(item).isEmpty
                  ? null
                  : Text(itemAmount(item)),
              secondary: PopupMenuButton<String>(
                tooltip: tr('Možnosti: ${item.name}', 'Options: ${item.name}'),
                enabled: !working,
                onSelected: (action) =>
                    action == 'edit' ? _edit(index) : _remove(index),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(tr('Upravit množství', 'Edit amount')),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(tr('Odebrat potravinu', 'Remove food')),
                  ),
                ],
              ),
            ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              tr('3  Vyber čas na přípravu', '3  Choose prep time'),
              style: text.titleMedium,
            ),
            const SizedBox(height: 8),
            if (largeText)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in [10, 20, 40])
                    ChoiceChip(
                      label: Text('$time min'),
                      selected: minutes == time,
                      onSelected: working
                          ? null
                          : (_) => _selection(time: time),
                    ),
                ],
              )
            else
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 10, label: Text('10 min')),
                  ButtonSegment(value: 20, label: Text('20 min')),
                  ButtonSegment(value: 40, label: Text('40 min')),
                ],
                selected: {minutes},
                onSelectionChanged: working
                    ? null
                    : (s) => _selection(time: s.first),
              ),
            if (left != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  left > 0
                      ? tr(
                          'Do cíle bílkovin ti dnes chybí ${left.round()} g. '
                              'Návrhy to zohlední.',
                          'You are ${left.round()} g short of your protein '
                              'goal today. Suggestions will account for it.',
                        )
                      : tr(
                          'Cíl bílkovin máš dnes splněný.',
                          'Protein goal reached today.',
                        ),
                  style: text.bodySmall,
                ),
              ),
            const SizedBox(height: Space.l),
            PrimaryButton(
              tr('Navrhni jídlo', 'Suggest a meal'),
              icon: Icons.restaurant_menu,
              onPressed: working || !aiEnabled ? null : _suggest,
            ),
          ],
          if (state.savedMealIdeas.isNotEmpty) ...[
            const SizedBox(height: Space.l),
            GroupedSection(
              children: [
                GroupedRow(
                  icon: Icons.history,
                  title: tr('Poslední návrhy', 'Recent ideas'),
                  subtitle: tr(
                    'Uložené v zařízení, dostupné i bez internetu',
                    'Saved on your device, available offline',
                  ),
                  onTap: working
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MealIdeasPage(state, state.savedMealIdeas),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoReviewPage extends StatefulWidget {
  final List<PantryItem> items;
  const _PhotoReviewPage(this.items);
  @override
  State<_PhotoReviewPage> createState() => _PhotoReviewPageState();
}

class _PhotoReviewPageState extends State<_PhotoReviewPage> {
  late List<PantryItem> items = mergePantry([], widget.items);

  Future<void> _edit(int index) async {
    final item = await showDialog<PantryItem>(
      context: context,
      builder: (_) => _ItemDialog(items[index]),
    );
    if (item == null || !mounted) return;
    setState(() => items = mergePantry([], [...items]..[index] = item));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(tr('Zkontroluj rozpoznání', 'Review detection')),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.page,
        Space.s,
        Space.page,
        Space.xxl,
      ),
      children: [
        Text(
          tr(
            'AI se může splést. Oprav názvy, množství a jednotky. Shodná potravina aktualizuje množství v tvém seznamu až po potvrzení.',
            'AI can make mistakes. Fix names, amounts and units. Matching '
                'foods update in your list only after you confirm.',
          ),
        ),
        if (items.isNotEmpty)
          GroupedSection(
            children: [
              for (final (index, item) in items.indexed)
                GroupedRow(
                  title: item.name,
                  subtitle: itemAmount(item).isEmpty
                      ? tr('Množství neznámé', 'Amount unknown')
                      : itemAmount(item),
                  onTap: () => _edit(index),
                  chevron: false,
                  trailing: IconButton(
                    tooltip: tr('Odebrat ${item.name}', 'Remove ${item.name}'),
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => items.removeAt(index)),
                  ),
                ),
            ],
          ),
        const SizedBox(height: Space.l),
        PrimaryButton(
          tr('Potvrdit seznam', 'Confirm list'),
          onPressed: items.isEmpty ? null : () => Navigator.pop(context, items),
        ),
      ],
    ),
  );
}

class _ItemDialog extends StatefulWidget {
  final PantryItem? item;
  const _ItemDialog(this.item);

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final name = TextEditingController(text: widget.item?.name ?? '');
  late final amount = TextEditingController(
    text: widget.item?.amount == null
        ? ''
        : formatKg(double.parse(widget.item!.amount!.toStringAsFixed(1))),
  );
  late String unit = widget.item == null ? 'g' : widget.item!.unit ?? 'unknown';
  String? error;

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  void _save() {
    final n = name.text.trim();
    if (n.isEmpty) {
      setState(() => error = tr('Zadej název.', 'Enter a name.'));
      return;
    }
    final raw = amount.text.trim();
    final a = raw.isEmpty ? null : parseNum(raw);
    if (raw.isNotEmpty && (a == null || a <= 0 || a > 100000)) {
      setState(
        () => error = tr(
          'Množství musí být kladné číslo.',
          'Amount must be a positive number.',
        ),
      );
      return;
    }
    if (a != null && unit == 'unknown') {
      setState(
        () => error = tr('Vyber jednotku množství.', 'Pick an amount unit.'),
      );
      return;
    }
    Navigator.pop(
      context,
      PantryItem(
        n.length > 60 ? n.substring(0, 60) : n,
        amount: a,
        unit: a == null ? null : unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.item == null
          ? tr('Přidat potravinu', 'Add food')
          : tr('Upravit potravinu', 'Edit food'),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          autofocus: widget.item == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: tr('Název', 'Name')),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: tr('Množství (nepovinné)', 'Amount (optional)'),
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'unknown', label: Text('?')),
            ButtonSegment(value: 'g', label: Text('g')),
            ButtonSegment(value: 'ml', label: Text('ml')),
            ButtonSegment(value: 'ks', label: Text(tr('ks', 'pcs'))),
          ],
          selected: {unit},
          onSelectionChanged: (s) => setState(() => unit = s.first),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
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
