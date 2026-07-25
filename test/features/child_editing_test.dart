/// Editing a registered child, deleting her, and the caregiver's own name.
///
/// These three were missing until profiles started surviving a restart, at
/// which point a typo in a child's name became permanent and a hemoglobin
/// reading from an old CRED check-up had no way of ever being corrected.
///
/// The rule these tests exist to hold is the one from ADR-0007: **editing must
/// not become a back door for inventing a hemoglobin value.** The form comes
/// back prefilled with everything the caregiver typed — except that number.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/app/routes.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/settings/caregiver_repository.dart';
import 'package:wawafuerte/core/storage/in_memory_repositories.dart';
import 'package:wawafuerte/features/onboarding/age_band.dart';
import 'package:wawafuerte/features/onboarding/onboarding_controller.dart';

import '../support/pump_app.dart';

void main() {
  setUpAll(configureFontsForTest);

  /// Home → the Editar action on the first card → the prefilled form.
  Future<void> openTheEditForm(WidgetTester tester) async {
    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();
  }

  // --- Editing. --------------------------------------------------------------

  group('editing a registered child', () {
    testWidgets('every card offers Editar and Borrar, each with its word', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
      );

      // Never a bare glyph: the icon set is not universal to someone who has
      // used a phone for messaging and little else.
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Borrar'), findsOneWidget);
    });

    testWidgets('the form opens with what she already told us', (tester) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita', ageMonths: 18)],
      );
      await openTheEditForm(tester);

      // The same questions as registration, not a second screen to learn.
      expect(find.text('Los datos de Rosita'), findsOneWidget);
      expect(find.text('¿Cómo se llama tu niña o niño?'), findsOneWidget);
      expect(find.text('Guardar los cambios'), findsOneWidget);

      // Her name is in the box, ready to be corrected.
      final nameField = tester.widget<TextField>(find.byType(TextField).first);
      expect(nameField.controller?.text, 'Rosita');
    });

    testWidgets('a corrected name is persisted against the same child', (
      tester,
    ) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(id: 'child-1', name: 'Rosita')],
      );
      await openTheEditForm(tester);

      await tester.enterText(find.byType(TextField).first, 'Rosa María');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar los cambios'));
      await tester.pumpAndSettle();

      // One child, not two: editing writes over the same id, so her plans
      // survive (ADR-0013 keys them by child_id).
      final saved = (await harness.profiles.findAll()).single;
      expect(saved.id, 'child-1');
      expect(saved.name, 'Rosa María');

      // And Home shows the change without needing a restart.
      expect(find.text('Rosa María'), findsOneWidget);
      expect(find.text('Rosita'), findsNothing);
    });

    testWidgets('an unchanged age answer leaves the birth date alone', (
      tester,
    ) async {
      final birthDate = DateTime(2024, 3, 7);
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [
          testChild(
            id: 'child-1',
            name: 'Rosita',
          ).copyWith(birthDate: birthDate),
        ],
      );
      await openTheEditForm(tester);

      await tester.enterText(find.byType(TextField).first, 'Rosita María');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar los cambios'));
      await tester.pumpAndSettle();

      // The age question is asked in ranges. Re-deriving the date on every save
      // would drag a real birth date to the midpoint of its band, so a spelling
      // fix would silently change the child's age — and with it the iron
      // requirement band (ADR-0012).
      final saved = (await harness.profiles.findAll()).single;
      expect(saved.birthDate, birthDate);
    });
  });

  // --- The hemoglobin rule, applied to editing. ------------------------------

  group('editing never invents a hemoglobin reading', () {
    testWidgets('the reading on file is shown as text, never in the field', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita', hemoglobin: 10.5)],
      );
      await openTheEditForm(tester);

      await scrollTo(tester, find.text('El número que ya tenemos es 10,5'));
      expect(find.text('El número que ya tenemos es 10,5'), findsOneWidget);

      // The input itself is empty: what goes in there is a NEW reading from a
      // NEW check-up. This is the prefill bug ADR-0007 exists to prevent,
      // arriving through a different door.
      await scrollTo(tester, find.text('Por ejemplo: 10.5'));
      expect(find.text('Por ejemplo: 10.5'), findsOneWidget);

      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(
          field.controller?.text ?? '',
          isNot('10.5'),
          reason: 'no field may open with a hemoglobin value in it',
        );
      }
    });

    testWidgets('a new reading replaces the old one and is dated today', (
      tester,
    ) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [
          testChild(
            id: 'child-1',
            name: 'Rosita',
            hemoglobin: 9.8,
          ).copyWith(hemoglobinDate: DateTime(2025, 1, 4)),
        ],
      );
      await openTheEditForm(tester);

      final field = find.widgetWithText(TextField, 'Por ejemplo: 10.5');
      await scrollTo(tester, field);
      await tester.enterText(field, '11,4');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar los cambios'));
      await tester.pumpAndSettle();

      final saved = (await harness.profiles.findAll()).single;
      expect(saved.hemoglobin, 11.4);
      expect(saved.hemoglobinDate!.year, greaterThan(2025));
    });

    testWidgets('skipping the field keeps the stored reading untouched', (
      tester,
    ) async {
      final measured = DateTime(2025, 1, 4);
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [
          testChild(
            id: 'child-1',
            name: 'Rosita',
            hemoglobin: 9.8,
          ).copyWith(hemoglobinDate: measured),
        ],
      );
      await openTheEditForm(tester);

      await tester.enterText(find.byType(TextField).first, 'Rosita');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar los cambios'));
      await tester.pumpAndSettle();

      // An edit that skipped this field is not a statement that the old
      // reading is wrong — and it is emphatically not a fresh measurement
      // taken today.
      final saved = (await harness.profiles.findAll()).single;
      expect(saved.hemoglobin, 9.8);
      expect(saved.hemoglobinDate, measured);
    });

    testWidgets('a child with no reading still opens with an empty field', (
      tester,
    ) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(id: 'child-1', name: 'Rosita')],
      );
      await openTheEditForm(tester);

      expect(find.textContaining('El número que ya tenemos'), findsNothing);

      await tester.tap(find.text('Guardar los cambios'));
      await tester.pumpAndSettle();

      final saved = (await harness.profiles.findAll()).single;
      expect(saved.hemoglobin, isNull);
      expect(saved.hemoglobinDate, isNull);
    });
  });

  // --- Deleting. -------------------------------------------------------------

  group('deleting a child', () {
    testWidgets('asks before deleting, and names what disappears', (
      tester,
    ) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(id: 'child-1', name: 'Rosita')],
      );

      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Borrar a Rosita?'), findsOneWidget);
      expect(
        find.text(
          'Se borran sus datos y todos sus menús. No se puede '
          'recuperar.',
        ),
        findsOneWidget,
      );

      // Nothing is gone yet: the dialog is a question, not a receipt.
      expect(await harness.profiles.findAll(), hasLength(1));
    });

    testWidgets('cancelling keeps the child', (tester) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(id: 'child-1', name: 'Rosita')],
      );

      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No, mejor no'));
      await tester.pumpAndSettle();

      expect(await harness.profiles.findAll(), hasLength(1));
      expect(find.text('Rosita'), findsOneWidget);
    });

    testWidgets('confirming removes her, and Home says so', (tester) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [
          testChild(id: 'child-1', name: 'Rosita'),
          testChild(id: 'child-2', name: 'Manuelito'),
        ],
      );

      await tester.tap(find.text('Borrar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, borrar a Rosita'));
      await tester.pumpAndSettle();

      expect(await harness.profiles.findAll(), hasLength(1));
      expect(find.text('Rosita'), findsNothing);
      expect(find.text('Manuelito'), findsOneWidget);
      expect(find.text('Se borraron los datos de Rosita'), findsOneWidget);
    });

    testWidgets('deleting the last child lands on the empty state', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(id: 'child-1', name: 'Rosita')],
      );

      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, borrar a Rosita'));
      await tester.pumpAndSettle();

      expect(find.text('Todavía no has registrado a nadie'), findsOneWidget);
      expect(find.text('Agregar otro niño o niña'), findsOneWidget);
    });
  });

  // --- The caregiver's own name. ---------------------------------------------

  group('the caregiver name is asked once and never again', () {
    testWidgets('the first run asks for it', (tester) async {
      await pumpApp(tester);

      final question = find.text('¿Cómo te llamamos? (opcional)');
      await scrollTo(tester, question);
      expect(question, findsOneWidget);
    });

    testWidgets('it is saved with the first child', (tester) async {
      final harness = await pumpApp(tester);

      await tester.enterText(find.byType(TextField).first, 'Rosita');
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 año'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Sierra'));
      await tester.tap(find.text('Sierra'));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Tu nombre');
      await scrollTo(tester, nameField);
      await tester.enterText(nameField, 'Rosa');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar y continuar'));
      await tester.pumpAndSettle();

      expect(await harness.caregivers.read(), 'Rosa');
      // And it greets her straight away on Home.
      expect(find.text('Hola, Rosa'), findsOneWidget);
    });

    testWidgets('registering a second child does not ask again', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
        caregiverName: 'Rosa',
      );

      await tester.tap(find.text('Agregar otro niño o niña'));
      await tester.pumpAndSettle();

      // The child's questions are all there; hers is not.
      expect(find.text('¿Cómo se llama tu niña o niño?'), findsOneWidget);
      expect(find.text('¿Cómo te llamamos? (opcional)'), findsNothing);
      expect(find.widgetWithText(TextField, 'Tu nombre'), findsNothing);
    });

    testWidgets('editing a child does not ask for her name either', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild(name: 'Rosita')],
        caregiverName: 'Rosa',
      );

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo te llamamos? (opcional)'), findsNothing);
    });
  });

  group('the caregiver name on Home', () {
    testWidgets('greets her by name when there is one', (tester) async {
      await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild()],
        caregiverName: 'Rosa',
      );

      expect(find.text('Hola, Rosa'), findsOneWidget);
    });

    testWidgets('greets her plainly when there is none — never "Usuario"', (
      tester,
    ) async {
      await pumpApp(tester, initialRoute: Routes.home, children: [testChild()]);

      expect(find.text('Hola'), findsOneWidget);
      expect(find.textContaining('Usuario'), findsNothing);
      // The button says what it would do, rather than hiding behind a glyph.
      expect(find.text('Poner mi nombre'), findsOneWidget);
    });

    testWidgets('the dialog changes it without leaving Home', (tester) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild()],
        caregiverName: 'Rosa',
      );

      await tester.tap(find.text('Mi nombre'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo te llamamos?'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Tu nombre'),
        'Rosa Elvira',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(await harness.caregivers.read(), 'Rosa Elvira');
      expect(find.text('Hola, Rosa Elvira'), findsOneWidget);
      // Still Home: no route was pushed for one optional field.
      expect(find.text('¿Para quién cocinamos?'), findsOneWidget);
    });

    testWidgets('cancelling the dialog changes nothing', (tester) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild()],
        caregiverName: 'Rosa',
      );

      await tester.tap(find.text('Mi nombre'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Tu nombre'),
        'Otra cosa',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(await harness.caregivers.read(), 'Rosa');
      expect(find.text('Hola, Rosa'), findsOneWidget);
    });

    testWidgets('an emptied name is cleared, not stored as blank', (
      tester,
    ) async {
      final harness = await pumpApp(
        tester,
        initialRoute: Routes.home,
        children: [testChild()],
        caregiverName: 'Rosa',
      );

      await tester.tap(find.text('Mi nombre'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Tu nombre'), '  ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(await harness.caregivers.read(), isNull);
      expect(find.text('Hola'), findsOneWidget);
    });
  });

  // Controller-level cover for the same rules, so a UI refactor cannot quietly
  // undo them.
  group('OnboardingController in edit mode', () {
    OnboardingController editing(ChildProfile child) => OnboardingController(
      profiles: InMemoryProfileRepository([child]),
      caregivers: InMemoryCaregiverRepository(),
      existing: child,
    );

    test('prefills the answers but never the hemoglobin text', () {
      final child = testChild(name: 'Rosita', hemoglobin: 10.5);
      final controller = editing(child);

      expect(controller.isEditing, isTrue);
      expect(controller.childName, 'Rosita');
      expect(controller.region, child.region);
      expect(controller.ageBand, AgeBand.oneYear);
      // The one field that stays empty.
      expect(controller.hemoglobinText, isEmpty);
      expect(controller.hemoglobin, isNull);
    });

    test('never re-asks the caregiver name', () async {
      final controller = editing(testChild());
      await controller.load();
      expect(controller.asksCaregiverName, isFalse);
    });

    test('a changed age band does re-derive the birth date', () async {
      final child = testChild(id: 'child-1', ageMonths: 18);
      final controller = editing(child)..setAgeBand(AgeBand.threeToFiveYears);

      final saved = await controller.submit(now: DateTime(2026, 7, 25));
      expect(saved!.birthDate, isNot(child.birthDate));
      expect(saved.ageMonthsAt(DateTime(2026, 7, 25)), 48);
    });
  });
}
