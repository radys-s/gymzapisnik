import 'package:flutter/material.dart';

import '../../domain/technique.dart';
import '../design/tokens.dart';

/// Malý náhled cviku do seznamů. Vlastní cvik má ikonu činky.
class ExerciseThumb extends StatelessWidget {
  final String exerciseId;
  final double size;
  const ExerciseThumb(this.exerciseId, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final images = exerciseImages(exerciseId);
    final placeholder = Container(
      color: p.fill,
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center_rounded,
        size: size * 0.5,
        color: p.secondaryLabel,
      ),
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: SizedBox.square(
          dimension: size,
          child: images.isEmpty
              ? placeholder
              : Image.asset(
                  // Druhá fotka je konec pohybu: na náhledu čitelnější.
                  images.last,
                  fit: BoxFit.cover,
                  cacheWidth: (size * 3).round(),
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}

/// Fotky začátku a konce pohybu s přepínáním (posun nebo klepnutí).
class ExerciseGallery extends StatefulWidget {
  final String exerciseId;
  const ExerciseGallery(this.exerciseId, {super.key});

  @override
  State<ExerciseGallery> createState() => _ExerciseGalleryState();
}

class _ExerciseGalleryState extends State<ExerciseGallery> {
  final _pages = PageController();
  int page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final images = exerciseImages(widget.exerciseId);
    if (images.isEmpty) return const SizedBox.shrink();
    const labels = ['Začátek pohybu', 'Konec pohybu'];
    void next() => _pages.animateToPage(
      (page + 1) % images.length,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    return Semantics(
      label: 'Fotka cviku: ${labels[page]}',
      hint: 'Klepnutím další fotka',
      onTap: next,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.hero),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => page = i),
                children: [
                  for (final path in images)
                    GestureDetector(
                      onTap: next,
                      child: Image.asset(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(color: p.fill),
                      ),
                    ),
                ],
              ),
              Positioned(
                left: Space.m,
                bottom: Space.m,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    labels[page],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: Space.m,
                bottom: Space.m + 6,
                child: Row(
                  children: [
                    for (var i = 0; i < images.length; i++)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == page ? Colors.white : Colors.white54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
