/// Onboarding screen: renders, and never invents a hemoglobin reading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/features/onboarding/age_band.dart';
import 'package:wawafuerte/features/onboarding/onboarding_controller.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/settings/caregiver_repository.dart';
import 'package:wawafuerte/core/storage/in_memory_repositories.dart';

import '../support/pump_app.dart';

void main() {
  setUpAll(configureFontsForTest);

  group('OnboardingScreen', () {
    testWidgets('renders the wordmark, the questions and the CTA', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('Wawa Fuerte'), findsOneWidget);

      // The first question, with no slash in it.
      expect(find.text('¿Cómo se llama tu niña o niño?'), findsOneWidget);
      expect(find.textContaining('niña/o'), findsNothing);

      // Age is asked as tappable ranges, not as a number plus a unit toggle.
      expect(find.text('6 a 11 meses'), findsOneWidget);
      expect(find.text('1 año'), findsOneWidget);

      // The CTA is anchored and visible without scrolling.
      expect(find.text('Guardar y continuar'), findsOneWidget);
    });

    testWidgets('shows no photograph of a person and no decorative image', (
      tester,
    ) async {
      await pumpApp(tester);

      // The doctor's portrait and the purple heart circle are gone: there are
      // no raster images anywhere in this screen.
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('the caregiver name field is optional and last', (
      tester,
    ) async {
      await pumpApp(tester);

      final caregiverQuestion = find.text('¿Cómo te llamamos? (opcional)');
      await scrollTo(tester, caregiverQuestion);
      expect(caregiverQuestion, findsOneWidget);
    });

    testWidgets('the CTA stays disabled until name, age and region are given', (
      tester,
    ) async {
      await pumpApp(tester);

      FilledButton cta() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardar y continuar'),
      );

      expect(cta().onPressed, isNull, reason: 'nothing answered yet');

      await tester.enterText(find.byType(TextField).first, 'Rosita');
      await tester.pumpAndSettle();
      expect(cta().onPressed, isNull, reason: 'age and region still missing');

      await tester.tap(find.text('1 año'));
      await tester.pumpAndSettle();
      expect(cta().onPressed, isNull, reason: 'region still missing');

      await scrollTo(tester, find.text('Sierra'));
      await tester.tap(find.text('Sierra'));
      await tester.pumpAndSettle();
      expect(cta().onPressed, isNotNull);
    });
  });

  // --- The safety bug. -------------------------------------------------------
  //
  // The prototype prefilled hemoglobin with "11". A caregiver without her CRED
  // booklet would leave it, and the app would then generate and score a plan
  // against a number nobody measured. These tests pin the fix.
  group('hemoglobin is never invented', () {
    testWidgets('the hemoglobin field is hidden until the booklet is at hand', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('¿Qué número dice en Hemoglobina?'), findsNothing);

      await scrollTo(tester, find.text('Sí, lo tengo aquí'));
      await tester.tap(find.text('Sí, lo tengo aquí'));
      await tester.pumpAndSettle();

      await scrollTo(
        tester,
        find.text('¿Qué número dice en Hemoglobina? (opcional)'),
      );
      expect(
        find.text('¿Qué número dice en Hemoglobina? (opcional)'),
        findsOneWidget,
      );
    });

    testWidgets('the hemoglobin field starts empty, with only a grey hint', (
      tester,
    ) async {
      await pumpApp(tester);

      await scrollTo(tester, find.text('Sí, lo tengo aquí'));
      await tester.tap(find.text('Sí, lo tengo aquí'));
      await tester.pumpAndSettle();

      final hintFinder = find.text('Por ejemplo: 10.5');
      await scrollTo(tester, hintFinder);

      // A hint, not a value: no editable field contains a number.
      expect(hintFinder, findsOneWidget);
      expect(find.text('11'), findsNothing);

      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(
          field.controller?.text ?? '',
          isEmpty,
          reason: 'no field in onboarding may ship with a prefilled value',
        );
      }
    });

    testWidgets('an untouched hemoglobin field is saved as null', (
      tester,
    ) async {
      final harness = await pumpApp(tester);

      await tester.enterText(find.byType(TextField).first, 'Rosita');
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 año'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Sierra'));
      await tester.tap(find.text('Sierra'));
      await tester.pumpAndSettle();

      // Say the booklet IS at hand — so the field is on screen and visibly
      // skippable — then skip it, which is the exact path that used to save 11.
      await scrollTo(tester, find.text('Sí, lo tengo aquí'));
      await tester.tap(find.text('Sí, lo tengo aquí'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar y continuar'));
      await tester.pumpAndSettle();

      final saved = (await harness.profiles.findAll()).single;
      expect(saved.name, 'Rosita');
      expect(saved.hemoglobin, isNull);
      expect(saved.hemoglobinDate, isNull);
      expect(saved.hasHemoglobin, isFalse);
    });
  });

  // Controller-level coverage of the same rule, so a UI refactor cannot quietly
  // reintroduce a default.
  group('OnboardingController.hemoglobin', () {
    OnboardingController controller() => OnboardingController(
      profiles: InMemoryProfileRepository(),
      caregivers: InMemoryCaregiverRepository(),
    );

    test('is null when the field was never touched', () {
      expect(controller().hemoglobin, isNull);
    });

    test('is null for whitespace, junk and out-of-range typos', () {
      for (final input in ['', '   ', 'abc', '0', '-3', '99']) {
        final c = controller()
          ..setCredAnswer(CredAnswer.yes)
          ..setHemoglobinText(input);
        expect(c.hemoglobin, isNull, reason: 'input was "$input"');
      }
    });

    test('is null when the booklet is not at hand, whatever was typed', () {
      for (final answer in [CredAnswer.no, CredAnswer.unknown]) {
        final c = controller()
          ..setHemoglobinText('10.5')
          ..setCredAnswer(answer);
        expect(c.hemoglobin, isNull);
      }
    });

    test('parses a real reading, with either decimal mark', () {
      for (final input in ['10.5', '10,5']) {
        final c = controller()
          ..setCredAnswer(CredAnswer.yes)
          ..setHemoglobinText(input);
        expect(c.hemoglobin, 10.5);
      }
    });

    test(
      'a saved reading carries its date; a missing one carries none',
      () async {
        final withReading = controller()
          ..setChildName('Rosita')
          ..setAgeBand(AgeBand.oneYear)
          ..setRegion(Region.highlands)
          ..setCredAnswer(CredAnswer.yes)
          ..setHemoglobinText('10.5');

        final saved = await withReading.submit();
        expect(saved!.hemoglobin, 10.5);
        expect(saved.hemoglobinDate, isNotNull);
      },
    );
  });

  group('AgeBand', () {
    test('each range maps into the requirement band it claims', () {
      final now = DateTime(2026, 7, 25);
      final expected = {
        AgeBand.sixToElevenMonths: 9,
        AgeBand.oneYear: 18,
        AgeBand.twoYears: 30,
        AgeBand.threeToFiveYears: 48,
      };

      for (final entry in expected.entries) {
        final child = testChild().copyWith(
          birthDate: entry.key.birthDateFrom(now),
        );
        expect(
          child.ageMonthsAt(now),
          entry.value,
          reason: '${entry.key.label} should resolve to ${entry.value} months',
        );
      }
    });
  });
}
