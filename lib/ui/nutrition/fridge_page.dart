import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../ai/fridge_coach.dart';
import '../../ai/photo.dart';
import '../../core/format.dart';
import '../../core/parse.dart';
import '../../state/app_state.dart';
import 'meal_ideas_page.dart';

/// Vybere fotku (`camera` = fotoaparát, jinak galerie). `null` = zrušeno.
typedef PhotoPicker = Future<Uint8List?> Function(bool camera);

Future<Uint8List?> pickPhoto(bool camera) async {
  final file = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: maxPhotoSide.toDouble(),
    maxHeight: maxPhotoSide.toDouble(),
    imageQuality: 80,
  );
  return file?.readAsBytes();
}

String itemAmount(PantryItem i) {
  final a = i.amount;
  if (a == null) return '';
  return '${formatKg(double.parse(a.toStringAsFixed(1)))} '
      '${i.unit ?? '(jednotka neznámá)'}';
}

/// Upozornění před prvním použitím AI. Vrací `true`, když uživatel souhlasí.
Future<bool> confirmAiNotice(BuildContext context, AppState state) async {
  if (state.profile.aiNoticeAccepted) return true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Než použiješ AI'),
      content: const Text(
        'Fotka nebo seznam potravin se odešle přes server aplikace do '
        'Cloudflare Workers AI kvůli rozpoznání nebo návrhu jídel. '
        'Potvrzený seznam a poslední návrhy si aplikace pamatuje v zařízení.\n\n'
        'AI se může splést: seznam i hodnoty si vždy zkontroluj. Návrhy jídel '
        'jsou jen inspirace, ne výživové ani zdravotní doporučení.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Zrušit'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: const Text('Rozumím'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await state.acceptAiNotice();
  return true;
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
      setState(() => busy = 'Prohlížím fotku…');
      final jpeg = prepareJpeg(raw);
      if (jpeg == null) {
        setState(() {
          busy = null;
          error = 'Tenhle formát fotky neumím přečíst. Zkus jinou.';
        });
        return;
      }
      final result = await state.coach.scanFridge(jpeg);
      if (!mounted || request != requestId) return;
      switch (result) {
        case AiOk(:final value):
          if (value.isEmpty) {
            setState(
              () => error =
                  'Na fotce AI žádné jídlo nenašla. Můžeš ho přidat ručně.',
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
                  'Potvrzený seznam je uložený. Shodné potraviny mají aktualizované množství.',
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
          () => error =
              'Fotku nebo seznam se nepodařilo '
              'zpracovat a uložit. Zkus to znovu.',
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
        () => error = 'Tato potravina už v seznamu je. Uprav její množství.',
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
    final removed = items[index];
    final wasSkipped = skipped.remove(pantryKey(removed.name));
    await _saveList([...items]..removeAt(index));
    if (!mounted ||
        items.any((i) => pantryKey(i.name) == pantryKey(removed.name))) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Odebráno: ${removed.name}'),
        action: SnackBarAction(
          label: 'Vrátit',
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
      busy = 'Ukládám seznam…';
      error = null;
    });
    try {
      await _store(next);
      await state.savePantrySelection(skipped, minutes);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Seznam se nepodařilo uložit. '
              'Zkus změnu znovu; aplikaci zatím nezavírej.',
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
      setState(() => error = 'Vyber aspoň jednu potravinu.');
      return;
    }
    if (chosen.length > 40) {
      setState(() => error = 'Pro návrh vyber nejvýš 40 potravin.');
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
      setState(() => busy = 'Vymýšlím jídla…');
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
          () => error =
              'Návrh se nepodařilo načíst. '
              'Zkus to znovu; seznam zůstává uložený.',
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
        setState(() => error = 'Výběr se nepodařilo uložit. Zkus to znovu.');
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
        label: const Text('Vyfotit'),
      ),
      OutlinedButton.icon(
        onPressed: working || !aiEnabled ? null : () => _scan(false),
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Z galerie'),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Co mám v ledničce')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('1  Přidej potraviny', style: text.titleLarge),
          const SizedBox(height: 8),
          if (!aiEnabled)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'AI v této verzi aplikace zatím není zapnutá. Seznam '
                  'potravin si můžeš vést ručně.',
                  style: text.bodyMedium,
                ),
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
            'Vyfoť otevřenou ledničku nebo potraviny na stole. Seznam pak '
            'můžeš upravit.',
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
                  if (busy == 'Prohlížím fotku…' || busy == 'Vymýšlím jídla…')
                    TextButton(
                      onPressed: _cancel,
                      child: const Text('Zrušit čekání'),
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
              items.isEmpty ? '2  Zkontroluj seznam' : '2  Vyber potraviny',
              style: text.titleMedium,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: working ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Přidat ručně'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    items.isEmpty
                        ? '2  Zkontroluj seznam'
                        : '2  Vyber potraviny',
                    style: text.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: working ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat ručně'),
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
                tooltip: 'Možnosti: ${item.name}',
                enabled: !working,
                onSelected: (action) =>
                    action == 'edit' ? _edit(index) : _remove(index),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Upravit množství')),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Odebrat potravinu'),
                  ),
                ],
              ),
            ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('3  Vyber čas na přípravu', style: text.titleMedium),
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
                      ? 'Do cíle bílkovin ti dnes chybí ${left.round()} g. '
                            'Návrhy to zohlední.'
                      : 'Cíl bílkovin máš dnes splněný.',
                  style: text.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: working || !aiEnabled ? null : _suggest,
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Navrhni jídlo'),
            ),
          ],
          if (state.savedMealIdeas.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: const Text('Poslední návrhy'),
              subtitle: const Text(
                'Uložené v zařízení, dostupné i bez internetu',
              ),
              trailing: const Icon(Icons.chevron_right),
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
    appBar: AppBar(title: const Text('Zkontroluj rozpoznání')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'AI se může splést. Oprav názvy, množství a jednotky. Shodná potravina aktualizuje množství v tvém seznamu až po potvrzení.',
        ),
        const SizedBox(height: 16),
        for (final (index, item) in items.indexed)
          Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                itemAmount(item).isEmpty
                    ? 'Množství neznámé'
                    : itemAmount(item),
              ),
              onTap: () => _edit(index),
              trailing: IconButton(
                tooltip: 'Odebrat ${item.name}',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => items.removeAt(index)),
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: items.isEmpty ? null : () => Navigator.pop(context, items),
          child: const Text('Potvrdit seznam'),
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
      setState(() => error = 'Zadej název.');
      return;
    }
    final raw = amount.text.trim();
    final a = raw.isEmpty ? null : parseNum(raw);
    if (raw.isNotEmpty && (a == null || a <= 0 || a > 100000)) {
      setState(() => error = 'Množství musí být kladné číslo.');
      return;
    }
    if (a != null && unit == 'unknown') {
      setState(() => error = 'Vyber jednotku množství.');
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
    title: Text(widget.item == null ? 'Přidat potravinu' : 'Upravit potravinu'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          autofocus: widget.item == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Název'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Množství (nepovinné)'),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'unknown', label: Text('?')),
            ButtonSegment(value: 'g', label: Text('g')),
            ButtonSegment(value: 'ml', label: Text('ml')),
            ButtonSegment(value: 'ks', label: Text('ks')),
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
        child: const Text('Zrušit'),
      ),
      FilledButton(onPressed: _save, child: const Text('Uložit')),
    ],
  );
}
