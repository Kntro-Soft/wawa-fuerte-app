/// Recipe screen: the detail, the listen button, and "Ya lo preparé".
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wawafuerte/app/routes.dart';
import 'package:wawafuerte/core/widgets/listen_button.dart';
import 'package:wawafuerte/features/plan/plan_controller.dart';
import 'package:wawafuerte/features/plan/plan_screen.dart';

import '../support/pump_app.dart';

void main() {
  setUpAll(configureFontsForTest);

  /// Walks all the way to Monday's recipe detail.
  Future<PlanController> openMondaysRecipe(WidgetTester tester) async {
    await pumpApp(
      tester,
      initialRoute: Routes.home,
      children: [testChild(name: 'Rosita')],
    );

    await tester.tap(find.text('Rosita'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Papa'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('S/50'));
    await tester.tap(find.text('S/50'));
    await tester.pumpAndSettle();

    final controller = Provider.of<PlanController>(
      tester.element(find.byType(PlanScreen)),
      listen: false,
    );

    await tester.tap(find.text('Crear el menú de la semana'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Lunes'));
    await tester.pumpAndSettle();

    return controller;
  }

  group('RecipeScreen', () {
    testWidgets('renders the day, the dish, the ingredients and the steps', (
      tester,
    ) async {
      await openMondaysRecipe(tester);

      // The weekday titles the screen — not "Día 1".
      expect(find.widgetWithText(AppBar, 'Lunes'), findsOneWidget);

      expect(find.text('Qué necesitas'), findsOneWidget);

      await scrollTo(tester, find.text('Cómo se prepara'));
      expect(find.text('Cómo se prepara'), findsOneWidget);
    });

    testWidgets('the listen button is present and carries the word Escuchar', (
      tester,
    ) async {
      await openMondaysRecipe(tester);

      expect(find.byType(ListenButton), findsOneWidget);
      // The icon never travels alone.
      expect(find.text('Escuchar'), findsOneWidget);
    });

    testWidgets('the listen button is at least 64 dp tall', (tester) async {
      await openMondaysRecipe(tester);

      final size = tester.getSize(find.byType(ListenButton));
      expect(
        size.height,
        greaterThanOrEqualTo(64),
        reason: 'the audio control is the core accessibility affordance',
      );
    });

    testWidgets('the recipe name is shown in full, never with an ellipsis', (
      tester,
    ) async {
      final controller = await openMondaysRecipe(tester);
      final name = controller.plan!.days.first.recipe.name;

      final heading = find.text(name);
      expect(heading, findsOneWidget);

      final rendered = tester.widget<Text>(heading);
      expect(rendered.maxLines, isNull);
      expect(rendered.overflow, anyOf(isNull, TextOverflow.visible));
      expect(rendered.data, isNot(contains('…')));
    });

    testWidgets('"Ya lo preparé" is labelled and persists when ticked', (
      tester,
    ) async {
      final controller = await openMondaysRecipe(tester);

      final toggle = find.text('Ya lo preparé');
      await scrollTo(tester, toggle);

      // Labelled, not a bare grey circle.
      expect(toggle, findsOneWidget);
      expect(controller.plan!.days.first.prepared, isFalse);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(controller.plan!.days.first.prepared, isTrue);
      // The label is stable across states so the control stays recognisable.
      expect(find.text('Ya lo preparé'), findsOneWidget);
    });

    testWidgets('ticking it is reflected back on the plan screen', (
      tester,
    ) async {
      await openMondaysRecipe(tester);

      await scrollTo(tester, find.text('Ya lo preparé'));
      await tester.tap(find.text('Ya lo preparé'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Ya lo preparaste'), findsOneWidget);
    });
  });
}
