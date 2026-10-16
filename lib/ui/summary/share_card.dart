import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../widgets/labels.dart';

/// Náhled karty tréninku a sdílení jako obrázek (na webu se stáhne).
Future<void> showShareCard(
  BuildContext context,
  AppState state,
  Workout workout, {
  required int number,
  required int records,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ShareSheet(
    state: state,
    workout: workout,
    number: number,
    records: records,
  ),
);

class _ShareSheet extends StatefulWidget {
  final AppState state;
  final Workout workout;
  final int number;
  final int records;
  const _ShareSheet({
    required this.state,
    required this.workout,
    required this.number,
    required this.records,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final box = context.findRenderObject() as RenderBox?;
    try {
      final boundary =
          _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('png');
      final d = widget.workout.date.toLocal();
      final name = 'trenink-${d.year}-${d.month}-${d.day}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              data.buffer.asUint8List(),
              mimeType: 'image/png',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) showToast(context, 'Obrázek se nepodařilo sdílet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FittedBox(
              // Obrázek má pevnou velikost, systémové zvětšení písma ho neořízne.
              child: MediaQuery.withNoTextScaling(
                child: RepaintBoundary(
                  key: _key,
                  child: ShareCard(
                    state: widget.state,
                    workout: widget.workout,
                    number: widget.number,
                    records: widget.records,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.l),
          PrimaryButton(
            'Sdílet obrázek',
            icon: Icons.ios_share_rounded,
            busy: _busy,
            onPressed: _share,
          ),
        ],
      ),
    ),
  );
}

/// Karta tréninku k sdílení: vždy tmavá, pevná velikost.
class ShareCard extends StatelessWidget {
  final AppState state;
  final Workout workout;
  final int number;
  final int records;
  const ShareCard({
    super.key,
    required this.state,
    required this.workout,
    required this.number,
    required this.records,
  });

  static const _bg = Color(0xFF0C0C10);
  static const _muted = Color(0xFFB4B4BC);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final duration = workout.finishedAt?.difference(workout.startedAt);
    var kg = 0.0;
    var sets = 0;
    final lines = <String>[];
    for (final e in workout.exercises) {
      final type = state.typeOf(e.exerciseId);
      sets += e.countedSets.length;
      if (type == ExerciseType.weighted) kg += volume(type, e.sets);
      final best = bestSet(type, e.sets);
      if (best != null && lines.length < 5) {
        lines.add(
          '${state.exercise(e.exerciseId).name}|${setLabel(type, best)}',
        );
      }
    }
    const white = TextStyle(color: Colors.white);
    return SizedBox(
      width: 360,
      height: 450,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(28),
          gradient: RadialGradient(
            center: const Alignment(0.9, -1),
            radius: 1.2,
            // Neprůhledné barvy: průhledná záře by v PNG i ve světlém sheetu
            // propustila pozadí. Jen 30 % akcentu, ať je šedý text čitelný.
            colors: [
              Color.alphaBlend(p.gradient.first.withValues(alpha: 0.3), _bg),
              _bg,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppMark(size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gym zápisník',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: white.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trénink č. $number',
                    style: white.copyWith(fontSize: 13, color: _muted),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                workout.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: white.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                formatDate(workout.date),
                style: white.copyWith(fontSize: 14, color: _muted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (duration != null)
                    _stat(white, durationLabel(duration), 'délka'),
                  _stat(white, '${formatVolume(kg)} kg', 'objem'),
                  _stat(white, '$sets', 'série'),
                ],
              ),
              const SizedBox(height: 20),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.split('|').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: white.copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.split('|').last,
                        style: white.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFeatures: tabular,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (records > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD60A),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        records == 1
                            ? 'Nový osobní rekord'
                            : 'Nové osobní rekordy: $records',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: white.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(TextStyle base, String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: base.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFeatures: tabular,
            ),
          ),
        ),
        Text(label, style: base.copyWith(fontSize: 12, color: _muted)),
      ],
    ),
  );
}
