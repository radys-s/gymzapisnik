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
  return '${formatKg(double.parse(a.toStringAsFixed(1)))} ${i.unit ?? ''}'
      .trim();
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
        'Cloudflare Workers AI. Nic se neukládá a nepoužívá k ničemu jinému.\n\n'
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
  final skipped = <String>{};
  int minutes = 20;
  String? busy;
  String? error;

  AppState get state => widget.state;
  bool get aiEnabled => state.coach.enabled;

  Future<void> _store(List<PantryItem> next) async {
    setState(() => items = next);
    await state.savePantry(next);
  }

  Future<void> _scan(bool camera) async {
    if (!await confirmAiNotice(context, state) || !mounted) return;
    setState(() => error = null);
    final Uint8List? raw;
    try {
      raw = await widget.picker(camera);
    } catch (_) {
      if (mounted) setState(() => error = 'Fotku se nepodařilo načíst.');
      return;
    }
    if (raw == null || !mounted) return;
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
    if (!mounted) return;
    switch (result) {
      case AiOk(:final value):
        final have = {for (final i in items) i.name.toLowerCase()};
        final added = [
          for (final i in value)
            if (have.add(i.name.toLowerCase())) i,
        ];
        setState(() => busy = null);
        await _store([...items, ...added]);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                value.isEmpty
                    ? 'Na fotce AI žádné jídlo nenašla.'
                    : added.isEmpty
                    ? 'Nic nového, všechno už v seznamu je.'
                    : 'Přidáno ${added.length}. Zkontroluj seznam.',
              ),
            ),
          );
      case AiError(:final message):
        setState(() {
          busy = null;
          error = message;
        });
    }
  }

  Future<void> _edit([int? index]) async {
    final edited = await showDialog<PantryItem>(
      context: context,
      builder: (_) => _ItemDialog(index == null ? null : items[index]),
    );
    if (edited == null) return;
    final next = [...items];
    if (index == null) {
      next.add(edited);
    } else {
      skipped.remove(items[index].name.toLowerCase());
      next[index] = edited;
    }
    await _store(next);
  }

  Future<void> _remove(int index) async {
    skipped.remove(items[index].name.toLowerCase());
    await _store([...items]..removeAt(index));
  }

  Future<void> _suggest() async {
    final chosen = [
      for (final i in items)
        if (!skipped.contains(i.name.toLowerCase())) i,
    ];
    if (chosen.isEmpty) {
      setState(() => error = 'Vyber aspoň jednu potravinu.');
      return;
    }
    if (!await confirmAiNotice(context, state) || !mounted) return;
    setState(() {
      busy = 'Vymýšlím jídla…';
      error = null;
    });
    final result = await state.coach.suggestMeals(
      chosen,
      state.mealContext(maxMinutes: minutes),
    );
    if (!mounted) return;
    setState(() => busy = null);
    switch (result) {
      case AiOk(:final value):
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MealIdeasPage(state, value)),
        );
      case AiError(:final message):
        setState(() => error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final working = busy != null;
    final left = state.proteinLeft();
    return Scaffold(
      appBar: AppBar(title: const Text('Co mám v ledničce')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
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
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: working || !aiEnabled ? null : () => _scan(true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Vyfotit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working || !aiEnabled ? null : () => _scan(false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Z galerie'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Vyfoť otevřenou ledničku nebo potraviny na stole. Seznam pak '
            'můžeš upravit.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (working)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(busy!),
                ],
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: TextStyle(color: scheme.error)),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  items.isEmpty ? 'Seznam je prázdný' : 'Potraviny doma',
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
              value: !skipped.contains(item.name.toLowerCase()),
              onChanged: working
                  ? null
                  : (on) => setState(() {
                      final key = item.name.toLowerCase();
                      on == true ? skipped.remove(key) : skipped.add(key);
                    }),
              title: Text(item.name),
              subtitle: itemAmount(item).isEmpty
                  ? null
                  : Text(itemAmount(item)),
              secondary: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Upravit ${item.name}',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: working ? null : () => _edit(index),
                  ),
                  IconButton(
                    tooltip: 'Odebrat ${item.name}',
                    icon: const Icon(Icons.close),
                    onPressed: working ? null : () => _remove(index),
                  ),
                ],
              ),
            ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Kolik máš času?', style: text.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10 min')),
                ButtonSegment(value: 20, label: Text('20 min')),
                ButtonSegment(value: 40, label: Text('40 min')),
              ],
              selected: {minutes},
              onSelectionChanged: working
                  ? null
                  : (s) => setState(() => minutes = s.first),
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
        ],
      ),
    );
  }
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
  late String unit = widget.item?.unit ?? 'g';
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
