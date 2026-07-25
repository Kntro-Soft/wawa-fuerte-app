/// Plan route: form, generating, result — and the two rules that protect the
/// caregiver from a confidently wrong number.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wawafuerte/app/routes.dart';
import 'package:wawafuerte/features/plan/plan_screen.dart';
import 'package:wawafuerte/core/domain/weekly_plan.dart';
import 'package:wawafuerte/core/theme/app_colors.dart';
import 'package:wawafuerte/core/widgets/iron_coverage_bar.dart';
import 'package:wawafuerte/features/plan/plan_controller.dart';
import 'package:wawafuerte/features/plan/widgets/recipe_row.dart';

import '../support/pump_app.dart';

void main() {
  setUpAll(configureFontsForTest);

  /// Walks Home → Plan → filled form → generated result.
  Future<void> generateAPlan(WidgetTester tester, {int ageMonths = 18}) async {
    await pumpApp(
      tester,
      initialRoute: Routes.home,
      children: [testChild(name: 'Rosita', ageMonths: ageMonths)],
    );

    await tester.tap(find.text('Rosita'));
    await tester.pumpAndSettle();

    // The pantry is fourteen chips deep and each one now carries its drawn
    // silhouette, so the later ones sit below the fold on a small screen —
    // exactly as they do for a real user.
    await scrollTo(tester, find.text('Papa'));
    await tester.tap(find.text('Papa'));
    await tester.pumpAndSettle();

    // The budget section is below the fold on a small screen, exactly as it is
    // for a real user; the tests scroll to it rather than pretend otherwise.
    await scrollTo(tester, find.text('S/50'));
    await tester.tap(find.text('S/50'));
    await tester.pumpAndSettle();

    // The CTA is anchored, so it needs no scrolling.
    await tester.tap(find.text('Crear el menú de la semana'));

    // NOT pumpAndSettle: the app passes through PlanStatus.generating, whose
    // view animates indefinitely by design, so "settled" never arrives while it
    // is mounted. Pump discrete frames until the result replaces it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('PlanScreen form', () {
    testWidgets('renders the pantry, the budget and the CTA', (tester) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );
      await tester.tap(find.text('Rosita'));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué tienes en casa?'), findsOneWidget);

      await scrollTo(tester, find.text('¿Cuánto puedes gastar esta semana?'));
      expect(find.text('¿Cuánto puedes gastar esta semana?'), findsOneWidget);

      // The three tappable budgets, so a number rarely has to be typed.
      expect(find.text('S/30'), findsOneWidget);
      expect(find.text('S/50'), findsOneWidget);
      expect(find.text('S/80'), findsOneWidget);

      // The CTA names what it produces: a week, not a single recipe.
      expect(find.text('Crear el menú de la semana'), findsOneWidget);
      expect(find.text('Generar receta'), findsNothing);
    });

    testWidgets('the budget field carries a visible S/ prefix', (tester) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );
      await tester.tap(find.text('Rosita'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('S/'));
      expect(find.text('S/'), findsOneWidget);
    });

    testWidgets('the budget starts empty and a shortcut fills it', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );
      await tester.tap(find.text('Rosita'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('O escribe otro monto'));
      expect(
        find.text('O escribe otro monto'),
        findsOneWidget,
        reason: 'a hint, not a prefilled amount',
      );

      await tester.tap(find.text('S/50'));
      await tester.pumpAndSettle();

      final field = tester
          .widgetList<TextField>(find.byType(TextField))
          .firstWhere((f) => f.controller != null);
      expect(field.controller!.text, '50');
    });

    testWidgets('the CTA is disabled until an ingredient and a budget exist', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );
      await tester.tap(find.text('Rosita'));
      await tester.pumpAndSettle();

      FilledButton cta() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Crear el menú de la semana'),
      );

      expect(cta().onPressed, isNull);

      await scrollTo(tester, find.text('Papa'));
      await tester.tap(find.text('Papa'));
      await tester.pumpAndSettle();
      expect(cta().onPressed, isNull, reason: 'no budget yet');

      await scrollTo(tester, find.text('S/30'));
      await tester.tap(find.text('S/30'));
      await tester.pumpAndSettle();
      expect(cta().onPressed, isNotNull);
    });
  });

  group('PlanScreen result', () {
    testWidgets('shows seven days, named, with the coverage bar', (
      tester,
    ) async {
      await generateAPlan(tester);

      expect(find.text('El menú de Rosita'), findsOneWidget);
      expect(find.byType(IronCoverageBar), findsOneWidget);

      // The list is lazy, so only the rows in the viewport are built. The plan
      // itself is the thing that must have seven days.
      final controller = Provider.of<PlanController>(
        tester.element(find.byType(PlanScreen)),
        listen: false,
      );
      expect(controller.plan!.days, hasLength(7));

      await scrollTo(tester, find.text('Lunes'));
      expect(find.byType(RecipeRow), findsWidgets);
    });

    testWidgets('days carry real weekday names, never "Día 1"', (tester) async {
      await generateAPlan(tester);

      for (final day in const [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ]) {
        await scrollTo(tester, find.text(day));
        expect(find.text(day), findsOneWidget);
      }

      expect(find.textContaining('Día 1'), findsNothing);
    });

    testWidgets('"Volver al inicio" is a secondary link, not the loud button', (
      tester,
    ) async {
      await generateAPlan(tester);

      final backHome = find.text('Volver al inicio');
      await scrollTo(tester, backHome);

      // A TextButton, not a FilledButton: the weight on this screen belongs to
      // the recipes and the listen button.
      expect(
        find.ancestor(of: backHome, matching: find.byType(TextButton)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: backHome, matching: find.byType(FilledButton)),
        findsNothing,
      );
    });

    testWidgets('a plan without a hemoglobin reading is framed as advice', (
      tester,
    ) async {
      await generateAPlan(tester);

      // ADR-0007: never an error, never blocking.
      expect(find.text('Menú preventivo estándar'), findsOneWidget);
    });
  });

  // --- Recipe names are never truncated. -------------------------------------
  //
  // Peruvian dish names carry their ingredients, so the clipped half is the half
  // that tells a caregiver whether she can cook it tonight.
  group('recipe names are never truncated', () {
    testWidgets('no row sets maxLines or an overflow ellipsis', (tester) async {
      await generateAPlan(tester);

      // Walk the whole week, checking every row as it is built. The list is
      // lazy, so scrolling is what brings the later days into existence.
      for (final day in const [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ]) {
        await scrollTo(tester, find.text(day));

        final row = find.ancestor(
          of: find.text(day),
          matching: find.byType(RecipeRow),
        );
        expect(row, findsOneWidget, reason: '$day should have a row');

        final texts = tester.widgetList<Text>(
          find.descendant(of: row, matching: find.byType(Text)),
        );
        expect(texts, isNotEmpty);

        for (final text in texts) {
          expect(
            text.maxLines,
            isNull,
            reason: 'no text in a recipe row may be capped to N lines',
          );
          expect(
            text.overflow,
            anyOf(isNull, TextOverflow.visible),
            reason: 'a recipe name must never be cut with an ellipsis',
          );
        }
      }
    });

    testWidgets('a long name renders in full, over as many lines as it needs', (
      tester,
    ) async {
      await generateAPlan(tester);

      // The longest dish in the sample corpus. It is 46 characters and cannot
      // fit one line at 20 sp on a phone, so this only passes if the row wraps.
      const longName = 'Segundo de sangrecita con arroz y verduras';
      final finder = find.text(longName);
      await scrollTo(tester, finder);

      expect(finder, findsWidgets);

      final rendered = tester.widget<Text>(finder.first);
      expect(rendered.data, longName);
      expect(rendered.data, isNot(contains('…')));
      expect(rendered.data, isNot(contains('...')));

      // And the row actually grew to fit it, rather than clipping.
      final rowSize = tester.getSize(find.byType(RecipeRow).first);
      expect(rowSize.height, greaterThan(88));
    });
  });

  // --- The ADR-0012 guard. ---------------------------------------------------
  //
  // Below 6 months no dietary iron requirement is published, so `requiredMg` is
  // 0 — which makes `percent` return 0 and, far worse, `meetsTarget` return true
  // because 0 >= 0. Without the guard the app would tell the mother of a
  // three-month-old that her baby met his weekly iron target.
  group('hasOfficialRequirement guard', () {
    testWidgets('no percentage is shown for an age with no official figure', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IronCoverageBar(
              coverage: const IronCoverage(providedMg: 0, requiredMg: 0),
              // Three months: below the published floor of 6 months.
              ageMonths: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('mg'), findsNothing);
      expect(
        find.text('Todavía no podemos calcular el hierro'),
        findsOneWidget,
      );
      // And emphatically no claim that the target was met.
      expect(find.textContaining('cubre el hierro'), findsNothing);
    });

    testWidgets('no percentage is shown above the top published band', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IronCoverageBar(
              coverage: const IronCoverage(providedMg: 20, requiredMg: 0),
              // 11 years: FAO/WHO splits by sex and menarche status from here.
              ageMonths: 132,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('%'), findsNothing);
      expect(
        find.text('Todavía no podemos calcular el hierro'),
        findsOneWidget,
      );
    });

    testWidgets('a supported age shows the raw milligrams and the percentage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IronCoverageBar(
              coverage: const IronCoverage(providedMg: 27, requiredMg: 35),
              ageMonths: 18,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The percentage is the headline, at display size, because it answers
      // the question the caregiver opened the app with.
      expect(find.text('77 %'), findsOneWidget);

      // And the raw figure sits right under it. This is what ADR-0005
      // protects: a percentage with no numerator is an unverifiable score.
      expect(find.text('27,0 mg de los 35,0 mg de la semana'), findsOneWidget);
    });

    testWidgets('the coverage bar is green, not red', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IronCoverageBar(
              coverage: const IronCoverage(providedMg: 27, requiredMg: 35),
              ageMonths: 18,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.valueColor?.value, AppColors.success);
    });
  });

  group('PlanController generation states', () {
    testWidgets('shows the full-screen waiting state with no retry button', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );
      await tester.tap(find.text('Rosita'));
      await tester.pumpAndSettle();

      final controller = Provider.of<PlanController>(
        tester.element(find.byType(PlanScreen)),
        listen: false,
      );
      controller
        ..toggleIngredient('papa')
        ..selectBudgetShortcut(50);

      // Drive the state directly: the point is what the screen shows while the
      // model is busy, not how fast the fake finishes.
      unawaited(controller.generate());
      await tester.pump();

      expect(find.text('Estamos armando el menú de tu wawa…'), findsOneWidget);
      expect(find.textContaining('minutito'), findsOneWidget);

      // No retry, no cancel, no CTA — nothing to tap that starts a second run.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Volver a intentar'), findsNothing);

      // Deliberately NOT pumpAndSettle: the waiting state animates forever by
      // design, so "settled" never arrives while it is on screen. Pump discrete
      // frames until generation finishes and the view is torn down.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('El menú de Rosita'), findsOneWidget);
    });
  });
}
