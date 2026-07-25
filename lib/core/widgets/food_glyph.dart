/// A drawn silhouette for one ingredient.
///
/// OWNER: P3 (UI).
///
/// `FoodChip` documents why these foods are **words** and not icons: papa,
/// sangrecita, quinua and tarwi have no glyph in Lucide, Material Symbols or
/// any other international set, because those sets were not drawn in the Andes.
/// That reasoning still holds — the word stays, at 20 sp, and it is what the
/// caregiver reads. This adds a mark *beside* the word, and the class doc for
/// `FoodChip` named exactly this as the honest upgrade: "flat vector
/// illustrations drawn for these specific foods — never stock photos".
///
/// So they are drawn here, with `Path`, in about a dozen shapes:
///
/// - **Not emoji.** Vendor-dependent, sized by the system font rather than by
///   our 28 dp floor, and read as decoration.
/// - **Not photographs.** Sourcing, licensing and megabytes, in an app already
///   carrying a half-gigabyte model.
/// - **Not an SVG asset.** Another file to load on a phone that has none to
///   spare, when the shapes are this simple.
///
/// Two rules keep them honest:
///
/// **1. The mark never replaces the word.** It is a second cue for a caregiver
/// scanning a wall of chips, not a pictogram to decode. Alone, none of these
/// would be guessable, and none of them is ever shown alone.
///
/// **2. The colour is the food's, not the app's.** Papa is the brown of earth,
/// sangrecita the dark red of what it is, quinua the gold of the grain. These
/// pigments say *which food*, never *which state* — selection stays fill plus a
/// 2 dp border plus a check, exactly as before, so a colour-blind user or one in
/// direct sun loses nothing.
library;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// The shape families. One family covers several foods: a caregiver needs to
/// tell sangrecita from quinua at a glance, not to identify a tuber by cultivar.
enum FoodShape { tuber, drop, grain, legume, egg, leaf, fish, root, crescent }

/// What one ingredient looks like.
class FoodVisual {
  const FoodVisual(this.shape, this.color);

  final FoodShape shape;
  final Color color;

  /// Looked up by the corpus form of the name — lowercase and unaccented, the
  /// same string the retriever matches on. Anything unknown falls back to a
  /// neutral tuber rather than to nothing, so a free-text ingredient still gets
  /// a mark and the row does not go ragged.
  static FoodVisual forIngredient(String ingredient) {
    return _byIngredient[ingredient.trim().toLowerCase()] ?? _fallback;
  }

  static const FoodVisual _fallback = FoodVisual(
    FoodShape.tuber,
    Color(0xFF7A6A55),
  );

  static const Map<String, FoodVisual> _byIngredient = <String, FoodVisual>{
    // The iron-dense heart of the INS anti-anemia recipe book. Dark red,
    // several shades off AppColors.primary so it cannot read as an action.
    'sangrecita': FoodVisual(FoodShape.drop, Color(0xFF6E1B22)),
    'higado de pollo': FoodVisual(FoodShape.drop, Color(0xFF7C2A24)),
    'bazo': FoodVisual(FoodShape.drop, Color(0xFF6E1B22)),

    // Tubers and squashes: earth.
    'papa': FoodVisual(FoodShape.tuber, Color(0xFF8B6B4A)),
    'camote': FoodVisual(FoodShape.tuber, Color(0xFFA8532F)),
    'yuca': FoodVisual(FoodShape.tuber, Color(0xFF9A8352)),
    'zapallo': FoodVisual(FoodShape.tuber, Color(0xFFB36A10)),
    'cebolla': FoodVisual(FoodShape.tuber, Color(0xFFA2846B)),

    // Grains. Quinua is the gold one.
    'quinua': FoodVisual(FoodShape.grain, Color(0xFFA97514)),
    'trigo': FoodVisual(FoodShape.grain, Color(0xFF9A8352)),
    'avena': FoodVisual(FoodShape.grain, Color(0xFF9A8352)),
    'arroz': FoodVisual(FoodShape.grain, Color(0xFF8A7A5E)),

    // Pulses.
    'lentejas': FoodVisual(FoodShape.legume, Color(0xFF7A5230)),
    'frijol': FoodVisual(FoodShape.legume, Color(0xFF6B3B2A)),
    'frejol': FoodVisual(FoodShape.legume, Color(0xFF6B3B2A)),
    'habas': FoodVisual(FoodShape.legume, Color(0xFF4F5B2A)),
    'tarwi': FoodVisual(FoodShape.legume, Color(0xFF97781C)),

    'huevo': FoodVisual(FoodShape.egg, Color(0xFFB8862B)),

    'acelga': FoodVisual(FoodShape.leaf, Color(0xFF3F5230)),
    'espinaca': FoodVisual(FoodShape.leaf, Color(0xFF3F5230)),

    'pescado': FoodVisual(FoodShape.fish, Color(0xFF5F6B57)),
    'pollo': FoodVisual(FoodShape.fish, Color(0xFF8A6A4A)),

    'zanahoria': FoodVisual(FoodShape.root, Color(0xFFB35A16)),

    'platano': FoodVisual(FoodShape.crescent, Color(0xFFA98A16)),
  };
}

class FoodGlyph extends StatelessWidget {
  const FoodGlyph({
    required this.ingredient,
    this.size = AppSpacing.iconSize,
    super.key,
  });

  /// The corpus form of the name, not the capitalised display form.
  final String ingredient;

  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = FoodVisual.forIngredient(ingredient);

    // Decorative by construction: the chip's own label is what TalkBack reads,
    // and it says everything this mark does.
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _FoodGlyphPainter(visual)),
      ),
    );
  }
}

class _FoodGlyphPainter extends CustomPainter {
  _FoodGlyphPainter(this.visual);

  final FoodVisual visual;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = visual.color;
    final w = size.width;
    final h = size.height;

    switch (visual.shape) {
      case FoodShape.tuber:
        // A lumpy oval. Real potatoes are not ellipses, and the asymmetry is
        // what makes it read as food rather than as a bullet point.
        final path = Path()
          ..moveTo(w * 0.10, h * 0.55)
          ..cubicTo(w * 0.05, h * 0.22, w * 0.38, h * 0.06, w * 0.60, h * 0.14)
          ..cubicTo(w * 0.92, h * 0.24, w * 0.98, h * 0.62, w * 0.76, h * 0.84)
          ..cubicTo(w * 0.54, h * 1.02, w * 0.16, h * 0.88, w * 0.10, h * 0.55)
          ..close();
        canvas.drawPath(path, fill);

      case FoodShape.drop:
        // A drop, point up.
        final path = Path()
          ..moveTo(w * 0.5, h * 0.06)
          ..cubicTo(w * 0.80, h * 0.38, w * 0.92, h * 0.58, w * 0.86, h * 0.72)
          ..arcToPoint(
            Offset(w * 0.14, h * 0.72),
            radius: Radius.circular(w * 0.36),
            clockwise: false,
          )
          ..cubicTo(w * 0.08, h * 0.58, w * 0.20, h * 0.38, w * 0.5, h * 0.06)
          ..close();
        canvas.drawPath(path, fill);

      case FoodShape.grain:
        // Three seeds on the diagonal, the way loose grain falls.
        for (final offset in const <Offset>[
          Offset(0.30, 0.26),
          Offset(0.62, 0.46),
          Offset(0.36, 0.72),
        ]) {
          canvas.save();
          canvas.translate(w * offset.dx, h * offset.dy);
          canvas.rotate(-0.6);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 0.30,
              height: h * 0.18,
            ),
            fill,
          );
          canvas.restore();
        }

      case FoodShape.legume:
        // A pod: a curved capsule with the seeds showing through.
        canvas.save();
        canvas.translate(w * 0.5, h * 0.5);
        canvas.rotate(-0.7);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 0.82,
              height: h * 0.34,
            ),
            Radius.circular(h * 0.17),
          ),
          fill,
        );
        final seed = Paint()..color = const Color(0x33FFFFFF);
        for (final dx in const <double>[-0.26, 0, 0.26]) {
          canvas.drawCircle(Offset(w * dx, 0), h * 0.10, seed);
        }
        canvas.restore();

      case FoodShape.egg:
        final path = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(w * 0.5, h * 0.54),
              width: w * 0.62,
              height: h * 0.82,
            ),
          );
        canvas.drawPath(path, fill);

      case FoodShape.leaf:
        final path = Path()
          ..moveTo(w * 0.14, h * 0.86)
          ..cubicTo(w * 0.10, h * 0.36, w * 0.44, h * 0.08, w * 0.88, h * 0.12)
          ..cubicTo(w * 0.92, h * 0.58, w * 0.62, h * 0.92, w * 0.14, h * 0.86)
          ..close();
        canvas.drawPath(path, fill);
        // The midrib, cut out rather than drawn on top, so it survives any
        // background.
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.18, h * 0.84)
            ..lineTo(w * 0.80, h * 0.20),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.07
            ..color = const Color(0x55FFFFFF),
        );

      case FoodShape.fish:
        final body = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(w * 0.42, h * 0.5),
              width: w * 0.70,
              height: h * 0.46,
            ),
          );
        final tail = Path()
          ..moveTo(w * 0.74, h * 0.5)
          ..lineTo(w * 0.98, h * 0.26)
          ..lineTo(w * 0.98, h * 0.74)
          ..close();
        canvas.drawPath(body, fill);
        canvas.drawPath(tail, fill);

      case FoodShape.root:
        // A tapered root with two fronds.
        final path = Path()
          ..moveTo(w * 0.30, h * 0.28)
          ..lineTo(w * 0.70, h * 0.34)
          ..lineTo(w * 0.46, h * 0.96)
          ..close();
        canvas.drawPath(path, fill);
        final frond = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.09
          ..strokeCap = StrokeCap.round
          ..color = visual.color;
        canvas.drawLine(
          Offset(w * 0.40, h * 0.28),
          Offset(w * 0.24, h * 0.06),
          frond,
        );
        canvas.drawLine(
          Offset(w * 0.56, h * 0.30),
          Offset(w * 0.72, h * 0.08),
          frond,
        );

      case FoodShape.crescent:
        final path = Path()
          ..moveTo(w * 0.18, h * 0.16)
          ..cubicTo(w * 0.34, h * 0.78, w * 0.62, h * 0.94, w * 0.92, h * 0.80)
          ..cubicTo(w * 0.62, h * 0.76, w * 0.40, h * 0.52, w * 0.34, h * 0.12)
          ..close();
        canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _FoodGlyphPainter oldDelegate) =>
      oldDelegate.visual.shape != visual.shape ||
      oldDelegate.visual.color != visual.color;
}
