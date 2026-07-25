/// A woven stepped band, drawn as a rule under a screen's title.
///
/// OWNER: P3 (UI).
///
/// The app needed to look like somebody made it, and the honest way to do that
/// here was to borrow a mark the user already owns: the stepped diamond of
/// Andean weaving, the shape that runs along the border of a *manta* or a
/// *chumpi*. It is drawn with `Path` — a few lines of geometry, no asset, no
/// bytes, and it scales to any screen density on a phone that cannot afford
/// either.
///
/// Deliberately restrained, because the line between *reference* and *costume*
/// is thin:
///
/// - **8 dp tall and it appears once per screen**, under the title. It is a
///   rule, not a frame and not wallpaper.
/// - **Three earth pigments**, repeating. No gradient, no shadow, no animation.
/// - **It carries no information.** Nothing about it changes with state, and it
///   is hidden from TalkBack. A screen reader user loses nothing, which is the
///   test of whether decoration is honest about being decoration.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AndeanBand extends StatelessWidget {
  const AndeanBand({this.height = 8, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _AndeanBandPainter()),
      ),
    );
  }
}

class _AndeanBandPainter extends CustomPainter {
  /// One motif per this many logical pixels. Wide enough that the steps read as
  /// steps rather than as a texture at arm's length in sunlight.
  static const double _unit = 22;

  static const List<Color> _pigments = <Color>[
    AppColors.clay,
    AppColors.ochre,
    AppColors.andean,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final step = size.height / 2;

    var index = 0;
    for (double x = 0; x < size.width; x += _unit) {
      paint.color = _pigments[index % _pigments.length];

      // A stepped half-diamond: up two steps, down two steps. The same shape a
      // treadle loom produces, because it is the shape a grid of threads can
      // make.
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + step, size.height)
        ..lineTo(x + step, size.height - step)
        ..lineTo(x + step * 2, size.height - step)
        ..lineTo(x + step * 2, 0)
        ..lineTo(x + step * 3, 0)
        ..lineTo(x + step * 3, size.height - step)
        ..lineTo(x + step * 4, size.height - step)
        ..lineTo(x + step * 4, size.height)
        ..close();

      canvas.drawPath(path, paint);
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _AndeanBandPainter oldDelegate) => false;
}
