/// State for the plan route: form → generating → result (Flow B + Flow D).
///
/// OWNER: P3 (UI). **This is the reference `ChangeNotifier` named in ADR-0009** —
/// the other controllers copy its shape.
///
/// ## Why generation is a first-class state
///
/// The prototype had no loading state at all: it called the model and waited.
/// With Gemma running on-device on a low-end Android handset, that wait is tens
/// of seconds. A screen that does not visibly change for thirty seconds has, as
/// far as the user is concerned, crashed — so she taps again, or backs out, or
/// puts the phone down and it sleeps.
///
/// Hence [PlanStatus.generating] is an explicit state that:
///
/// - takes over the whole screen, so nothing else invites a tap;
/// - holds a **wakelock**, because the screen going dark mid-generation is
///   indistinguishable from a freeze, and on some devices the doze that follows
///   actually does slow the inference down;
/// - offers **no retry button while it runs**. A retry control during a long
///   wait is an invitation to start a second generation on a phone that is
///   struggling with the first one.
///
/// [PlanStatus.failed] is a real state too, not an exception that escapes into
/// a red Flutter screen — that is where retry lives.
library;

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/domain/child_profile.dart';
import '../../core/domain/generate_weekly_plan.dart';
import '../../core/domain/weekly_plan.dart';
import '../../core/storage/repositories.dart';

enum PlanStatus {
  /// The form: ingredients and budget.
  editing,

  /// The model is working. Full screen, wakelock held, no way to start another.
  generating,

  /// A plan exists and is on screen.
  ready,

  /// Generation failed. Retry lives here and only here.
  failed,
}

class PlanController extends ChangeNotifier {
  PlanController({
    required GenerateWeeklyPlan generatePlan,
    required PlanRepository plans,
    required this.child,
  }) : _generatePlan = generatePlan,
       _plans = plans;

  final GenerateWeeklyPlan _generatePlan;
  final PlanRepository _plans;

  /// The child this plan is for. Fixed for the lifetime of the route.
  final ChildProfile child;

  PlanStatus _status = PlanStatus.editing;
  PlanStatus get status => _status;

  WeeklyPlan? _plan;
  WeeklyPlan? get plan => _plan;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- Form state. ------------------------------------------------------------

  /// The pantry checklist. Ingredients the family actually has.
  final Set<String> selectedIngredients = <String>{};

  /// Free-text "other", for anything the preloaded list misses.
  String otherIngredients = '';

  /// Raw text. Empty until typed or filled by one of the shortcut buttons —
  /// like hemoglobin, this field never ships with a number already in it.
  String budgetText = '';

  /// The suggested weekly budgets. Typing a number on a phone keyboard while
  /// cooking is expensive; tapping one of three is close to free, and these
  /// three cover the realistic range.
  static const List<int> budgetShortcuts = <int>[30, 50, 80];

  double? get budget {
    final raw = budgetText.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// Flow B requires at least one ingredient and a budget.
  bool get canGenerate =>
      _allIngredients().isNotEmpty &&
      budget != null &&
      _status != PlanStatus.generating;

  /// Whether the plan was built without a hemoglobin reading (ADR-0007). Drives
  /// the "standard preventive plan" notice — advice, never an error.
  bool get isPreventivePlan => child.hemoglobin == null;

  // --- Mutations. -------------------------------------------------------------

  void toggleIngredient(String ingredient) {
    if (!selectedIngredients.remove(ingredient)) {
      selectedIngredients.add(ingredient);
    }
    notifyListeners();
  }

  void setOtherIngredients(String value) {
    otherIngredients = value;
    notifyListeners();
  }

  void setBudgetText(String value) {
    budgetText = value;
    notifyListeners();
  }

  void selectBudgetShortcut(int soles) {
    budgetText = '$soles';
    notifyListeners();
  }

  // --- Generation. ------------------------------------------------------------

  Future<void> generate() async {
    if (!canGenerate) return;

    _status = PlanStatus.generating;
    _errorMessage = null;
    notifyListeners();

    // Best-effort: wakelock is unsupported on some desktop targets and a failure
    // to hold the screen awake must never be the thing that stops a plan.
    await _enableWakelock();

    try {
      _plan = await _generatePlan(
        child: child,
        availableIngredients: _allIngredients(),
        weeklyBudgetPen: budget!,
      );
      _status = PlanStatus.ready;
    } catch (error) {
      // The message is for the caregiver, not for a developer: it says what to
      // do next, and never shows a stack trace or a model error verbatim.
      _errorMessage =
          'No pudimos armar el menú esta vez. Tu teléfono estaba ocupado. '
          'Vuelve a intentarlo.';
      debugPrint('Plan generation failed: $error');
      _status = PlanStatus.failed;
    } finally {
      await _disableWakelock();
      notifyListeners();
    }
  }

  /// Back to the form after a failure. Deliberately not reachable while
  /// [PlanStatus.generating].
  void retry() {
    if (_status != PlanStatus.failed) return;
    _status = PlanStatus.editing;
    _errorMessage = null;
    notifyListeners();
  }

  /// Ticks "Ya lo preparé" for one day and persists it (Flow D).
  Future<void> setPrepared({
    required int dayIndex,
    required bool prepared,
  }) async {
    final current = _plan;
    if (current == null) return;

    await _plans.markPrepared(
      childId: current.childId,
      weekStart: current.weekStart,
      dayIndex: dayIndex,
      prepared: prepared,
    );

    // Mirror the write locally so the checkbox responds immediately rather than
    // waiting on a re-read.
    _plan = WeeklyPlan(
      childId: current.childId,
      weekStart: current.weekStart,
      days: [
        for (final day in current.days)
          day.dayIndex == dayIndex ? day.copyWith(prepared: prepared) : day,
      ],
      coverage: current.coverage,
    );
    notifyListeners();
  }

  List<String> _allIngredients() {
    final extra = otherIngredients
        .split(RegExp(r'[,\n]'))
        .map((i) => i.trim())
        .where((i) => i.isNotEmpty);
    return {...selectedIngredients, ...extra}.toList();
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Unsupported platform. Not worth surfacing.
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Unsupported platform. Not worth surfacing.
    }
  }

  @override
  void dispose() {
    // The screen may be popped mid-generation; never leave the lock held.
    _disableWakelock();
    super.dispose();
  }
}
