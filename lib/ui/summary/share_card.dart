import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
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
}) {
  final d = workout.date.toLocal();
  return showShareImage(
    context,
    fileName: 'trenink-${d.year}-${d.month}-${d.day}.png',
    child: ShareCard(
      state: state,
      workout: workout,
      number: number,
      records: records,
    ),
  );
}

/// Náhled pevné karty a tlačítko, které ji sdílí jako PNG.
Future<void> showShareImage(
  BuildContext context, {
  required String fileName,
  required Widget child,
  String? button,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      ShareImageSheet(fileName: fileName, button: button, child: child),
);

class ShareImageSheet extends StatefulWidget {
  final String fileName;
  final String? button;
  final Widget child;
  const ShareImageSheet({
    super.key,
    required this.fileName,
    required this.child,
    this.button,
  });

  @override
  State<ShareImageSheet> createState() => _ShareImageSheetState();
}

class _ShareImageSheetState extends State<ShareImageSheet> {
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
      final name = widget.fileName;
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
      if (mounted) {
        showToast(
          context,
          tr('Obrázek se nepodařilo sdílet.', 'Could not share the image.'),
        );
      }
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
                child: RepaintBoundary(key: _key, child: widget.child),
              ),
            ),
          ),
          const SizedBox(height: Space.l),
          PrimaryButton(
            widget.button ?? tr('Sdílet obrázek', 'Share image'),
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

  static const _bg = AppPalette.ink;
  static const _muted = Color(0xFFA1A1A8);
  static const _line = Color(0xFF2A2A2E);

  @override
  Widget build(BuildContext context) {
    final duration = workout.finishedAt?.difference(workout.startedAt);
    var kg = 0.0;
    var sets = 0;
    final lines = <(String, String)>[];
    for (final e in workout.exercises) {
      final type = state.typeOf(e.exerciseId);
      sets += e.countedSets.length;
      if (type == ExerciseType.weighted) kg += volume(type, e.sets);
      final best = bestSet(type, e.sets);
      if (best != null && lines.length < 5) {
        lines.add((state.exercise(e.exerciseId).name, setLabel(type, best)));
      }
    }
    const white = TextStyle(color: Colors.white, fontFamily: textFont);
    const figure = TextStyle(
      color: Colors.white,
      fontFamily: condensedFont,
      fontWeight: FontWeight.w700,
      fontFeatures: tabular,
      height: 1,
    );
    return SizedBox(
      width: 360,
      height: 450,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: _bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 4, color: AppPalette.ember),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppMark(size: 24),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              tr('GYM ZÁPISNÍK', 'GYM LOG'),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: white.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            tr('TRÉNINK Č. $number', 'WORKOUT #$number'),
                            style: white.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${formatVolume(kg)} kg',
                          style: figure.copyWith(fontSize: 64),
                        ),
                      ),
                      Text(
                        tr('zvednuto celkem', 'total lifted'),
                        style: white.copyWith(fontSize: 12, color: _muted),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        workout.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: white.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        formatDate(workout.date),
                        style: white.copyWith(fontSize: 13, color: _muted),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: _line),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (duration != null)
                              _stat(
                                figure,
                                durationLabel(duration),
                                tr('délka', 'duration'),
                              ),
                            _stat(figure, '$sets', tr('série', 'sets')),
                            _stat(
                              figure,
                              '${workout.exercises.length}',
                              tr('cviků', 'exercises'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final (name, best) in lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: white.copyWith(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                best,
                                style: white.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
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
                              color: AppPalette.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                records == 1
                                    ? tr(
                                        'Nový osobní rekord',
                                        'New personal record',
                                      )
                                    : tr(
                                        'Nové osobní rekordy: $records',
                                        'New personal records: $records',
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: white.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(TextStyle figure, String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: figure.copyWith(fontSize: 24)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: textFont,
            fontSize: 11,
            color: _muted,
          ),
        ),
      ],
    ),
  );
}
