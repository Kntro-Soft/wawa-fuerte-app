/// Home screen: the child selector, its empty state, and no dead controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/app/routes.dart';

import '../support/pump_app.dart';

void main() {
  setUpAll(configureFontsForTest);

  group('HomeScreen', () {
    testWidgets('renders the selector and the add-a-child action', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );

      expect(find.text('¿Para quién cocinamos?'), findsOneWidget);
      expect(find.text('Rosita'), findsOneWidget);
      expect(find.text('Agregar otro niño o niña'), findsOneWidget);
    });

    testWidgets('lists every registered child — the domain has no limit', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [
          testChild(id: 'a', name: 'Rosita'),
          testChild(id: 'b', name: 'Manuelito'),
          testChild(id: 'c', name: 'Ana Lucía'),
        ],
      );

      expect(find.text('Rosita'), findsOneWidget);
      expect(find.text('Manuelito'), findsOneWidget);
      expect(find.text('Ana Lucía'), findsOneWidget);
    });

    testWidgets('shows the empty state when nobody is registered', (
      tester,
    ) async {
      await pumpApp(tester, initialRoute: Routes.home);

      expect(find.text('Todavía no has registrado a nadie'), findsOneWidget);
      // The empty state still offers the one action that resolves it.
      expect(find.text('Agregar otro niño o niña'), findsOneWidget);
    });

    testWidgets('says a child has no plan yet rather than showing nothing', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );

      expect(
        find.text('Todavía no tiene menú de esta semana'),
        findsOneWidget,
      );
    });

    testWidgets('has no destination-less profile icon in the header', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild()],
      );

      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
      // The only thing in the bar is the title. A control that goes nowhere
      // costs a tap and a moment of doubt.
      expect(
        find.descendant(of: appBar, matching: find.byType(IconButton)),
        findsNothing,
      );
    });

    testWidgets('tapping a child opens the plan route', (tester) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );

      await tester.tap(find.text('Rosita'));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué tienes en casa?'), findsOneWidget);
    });
  });
}
