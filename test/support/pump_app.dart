/// Shared helpers for the widget tests.
///
/// Every screen test boots the **real** app — `AppProviders` plus
/// `WawaFuerteApp` — rather than pumping a screen in isolation. The wiring
/// (route table, provider graph, argument casts) is a real source of breakage in
/// a four-developer sprint, so the tests exercise it instead of stubbing it out.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/app/app.dart';
import 'package:wawafuerte/app/providers.dart';
import 'package:wawafuerte/app/routes.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/inference/fake_inference_service.dart';
import 'package:wawafuerte/core/rag/fake_recipe_retriever.dart';
import 'package:wawafuerte/core/settings/caregiver_repository.dart';
import 'package:wawafuerte/core/storage/in_memory_repositories.dart';

/// Kept as a no-op hook, called from every test file's `setUpAll`.
///
/// It used to disable `google_fonts`' runtime HTTP fetch. Lexend is now bundled
/// as an asset, so there is nothing to disable — but the seam stays, because
/// font loading is exactly the kind of thing that grows a setup step again, and
/// a hook that already exists is cheaper than retrofitting one into six files.
void configureFontsForTest() {}

/// Boots the app at [initialRoute] with in-memory storage and the fakes.
///
/// Returns the repositories so a test can assert on what was persisted.
Future<TestHarness> pumpApp(
  WidgetTester tester, {
  String initialRoute = Routes.onboarding,
  List<ChildProfile> children = const [],
  String? caregiverName,
}) async {
  final profiles = InMemoryProfileRepository(children);
  final plans = InMemoryPlanRepository();
  final caregivers = InMemoryCaregiverRepository(caregiverName);
  final retriever = FakeRecipeRetriever();
  await retriever.load();

  await tester.pumpWidget(
    AppProviders(
      profiles: profiles,
      plans: plans,
      caregivers: caregivers,
      retriever: retriever,
      // Zero latency: the tests that care about the generating state drive it
      // explicitly, and the rest should not wait.
      inference: FakeInferenceService(latency: Duration.zero),
      child: WawaFuerteApp(initialRoute: initialRoute),
    ),
  );
  await tester.pumpAndSettle();

  return TestHarness(profiles: profiles, plans: plans, caregivers: caregivers);
}

class TestHarness {
  const TestHarness({
    required this.profiles,
    required this.plans,
    required this.caregivers,
  });

  final InMemoryProfileRepository profiles;
  final InMemoryPlanRepository plans;
  final InMemoryCaregiverRepository caregivers;
}

/// A child old enough to have an official iron requirement (ADR-0012).
ChildProfile testChild({
  String id = 'child-1',
  String name = 'Rosita',
  int ageMonths = 18,
  double? hemoglobin,
}) {
  final now = DateTime.now();
  return ChildProfile(
    id: id,
    name: name,
    birthDate: DateTime(now.year, now.month - ageMonths, 15),
    region: Region.highlands,
    hemoglobin: hemoglobin,
  );
}

/// Scrolls until [finder] is on screen. The screens are long by design, so
/// almost every interaction needs this.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
