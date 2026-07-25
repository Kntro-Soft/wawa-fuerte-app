/// Tests for Plan History (Flow D / Histórico).
library;

import "package:flutter_test/flutter_test.dart";
import "package:wawafuerte/app/routes.dart";
import "package:wawafuerte/core/domain/recipe.dart";
import "package:wawafuerte/core/domain/weekly_plan.dart";
import "package:wawafuerte/features/plan/plan_history_screen.dart";

import "../support/pump_app.dart";

void main() {
  setUpAll(configureFontsForTest);

  group("PlanHistoryScreen", () {
    testWidgets("renders empty state when child has no historical plans", (
      tester,
    ) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: "Rosita")],
      );

      await harness.profiles.save(testChild(name: "Rosita"));

      await tester.tap(find.text("Historial"));
      await tester.pumpAndSettle();

      expect(find.byType(PlanHistoryScreen), findsOneWidget);
      expect(find.text("Aún no hay historial de menús"), findsOneWidget);
    });

    testWidgets("lists historical plans when present", (tester) async {
      final child = testChild(id: "child-1", name: "Rosita");
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [child],
      );

      final pastPlan = WeeklyPlan(
        childId: child.id,
        weekStart: DateTime(2026, 7, 13),
        days: [
          for (var i = 0; i < 7; i++)
            PlanDay(
              dayIndex: i,
              prepared: i < 3,
              recipe: Recipe(
                id: 200 + i,
                name: "Receta test $i",
                ingredients: const ["sangrecita", "papa"],
                preparation: "Paso 1. Cocinar.",
                ironMg: 4.0,
                minAgeMonths: 6,
                referenceCostPen: 3.0,
              ),
            ),
        ],
        coverage: const IronCoverage(providedMg: 28, requiredMg: 35),
      );

      await harness.plans.save(pastPlan);

      await tester.tap(find.text("Historial"));
      await tester.pumpAndSettle();

      expect(find.byType(PlanHistoryScreen), findsOneWidget);
      expect(find.text("Menús anteriores"), findsOneWidget);
      expect(find.textContaining("80% de hierro cubierto"), findsOneWidget);
      expect(find.textContaining("3 de 7 comidas preparadas"), findsOneWidget);
    });

    testWidgets("tapping a historical plan opens detail screen and recipe modal", (
      tester,
    ) async {
      final child = testChild(id: "child-1", name: "Rosita");
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [child],
      );

      final pastPlan = WeeklyPlan(
        childId: child.id,
        weekStart: DateTime(2026, 7, 13),
        days: [
          for (var i = 0; i < 7; i++)
            PlanDay(
              dayIndex: i,
              prepared: i < 2,
              recipe: Recipe(
                id: 300 + i,
                name: "Estofado sangrecita $i",
                ingredients: const ["sangrecita", "arroz"],
                preparation: "Paso 1. Freír sangrecita.",
                ironMg: 4.0,
                minAgeMonths: 6,
                referenceCostPen: 3.0,
              ),
            ),
        ],
        coverage: const IronCoverage(providedMg: 28, requiredMg: 35),
      );

      await harness.plans.save(pastPlan);

      await tester.tap(find.text("Historial"));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining("80% de hierro cubierto"));
      await tester.pumpAndSettle();

      expect(find.text("Menú de Rosita"), findsOneWidget);
      expect(find.textContaining("Se prepararon 2 de 7 comidas"), findsOneWidget);

      await scrollTo(tester, find.text("Estofado sangrecita 0"));
      await tester.tap(find.text("Estofado sangrecita 0"));
      await tester.pumpAndSettle();

      expect(find.text("Qué necesitas"), findsOneWidget);
      expect(find.text("Cómo se prepara"), findsOneWidget);
    });
  });
}
