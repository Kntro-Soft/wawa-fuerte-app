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
///
/// ## Plan persistence (ADR-0013)
///
/// On construction, [PlanController] immediately reads the latest saved plan
/// for this child from SQLite. If a plan was generated this week, the screen
/// opens directly in [PlanStatus.ready] — the caregiver never sees the form
/// again until she explicitly asks for a new menu. The "Generar nuevo menú"
/// button on the result screen is the only way back to [PlanStatus.editing].
library;

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/domain/child_profile.dart';
import '../../core/domain/generate_weekly_plan.dart';
import '../../core/domain/weekly_plan.dart';
import '../../core/storage/repositories.dart';

enum PlanStatus {
  /// Loading the previously saved plan from the database.
  loading,

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
    required this.generatePlan,
    required this.plans,
    required this.child,
  }) {
    // Load the existing plan for this week immediately. If one exists the
    // screen opens in `ready` state and the caregiver skips the form. If none
    // exists it falls through to `editing` as before (ADR-0013).
    _loadExistingPlan();
  }

  final GenerateWeeklyPlan generatePlan;
  final PlanRepository plans;

  /// The child this plan is for. Fixed for the lifetime of the route.
  final ChildProfile child;

  PlanStatus _status = PlanStatus.loading;
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

  // --- Init: load existing plan. ----------------------------------------------

  /// Reads the most recent saved plan for this child. If it belongs to the
  /// current week the screen shows it directly; otherwise the form is shown.
  Future<void> _loadExistingPlan() async {
    final saved = await plans.latestFor(child.id);
    if (_isThisWeek(saved)) {
      _plan = saved;
      _status = PlanStatus.ready;
    } else {
      _status = PlanStatus.editing;
    }
    notifyListeners();
  }

  static bool _isThisWeek(WeeklyPlan? plan) {
    if (plan == null) return false;
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return plan.weekStart.year == monday.year &&
        plan.weekStart.month == monday.month &&
        plan.weekStart.day == monday.day;
  }

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

    // Fire and forget, deliberately NOT awaited. Keeping the screen on is a
    // nicety; generating the plan is the job. On platforms without a wakelock
    // implementation the platform call can hang rather than fail, and awaiting
    // it would mean a caregiver stares at the waiting screen forever because
    // her phone could not be told to stay awake.
    _enableWakelock();

    try {
      _plan = await generatePlan(
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
      _disableWakelock();
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

  /// Returns to the form from a result to allow generating a new plan.
  ///
  /// Only available from [PlanStatus.ready]. The caregiver has to explicitly
  /// ask for a new menu — it never happens by accident.
  void regenerate() {
    if (_status != PlanStatus.ready) return;
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

    await plans.markPrepared(
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

  // --- Shopping list (computed from the ready plan). --------------------------

  /// All unique ingredient names across all 7 days.
  List<String> get allPlanIngredients {
    final current = _plan;
    if (current == null) return const [];
    final seen = <String>{};
    for (final day in current.days) {
      seen.addAll(day.recipe.ingredients);
    }
    return seen.toList()..sort();
  }

  /// Ingredients from the plan that the family already said they have.
  ///
  /// Uses substring matching (same as the retriever) so "hígado de pollo"
  /// matches if the family tapped "higado de pollo" or wrote "pollo".
  Set<String> get haveIngredients {
    final pantry = _allIngredients().map((i) => i.toLowerCase()).toSet();
    // Also include items the user flipped manually to "tengo".
    return allPlanIngredients.where((ing) {
      final lower = ing.toLowerCase();
      // Pantry overlap — same logic as InsRecipeRetriever._overlap.
      final fromPantry = pantry.any(
        (w) => lower.contains(w) || w.contains(lower),
      );
      return fromPantry || _manuallyHave.contains(ing);
    }).toSet();
  }

  /// Ingredients the family still needs to buy.
  Set<String> get toBuyIngredients =>
      allPlanIngredients.toSet().difference(haveIngredients);

  /// Estimated total cost of the week, in Peruvian soles.
  ///
  /// This is a sum of `referenceCostPen` from the INS corpus — always
  /// an estimate, never a precise figure (ADR-0011).
  double get estimatedCostPen {
    final current = _plan;
    if (current == null) return 0;
    return current.days.fold(0.0, (sum, d) => sum + d.recipe.referenceCostPen);
  }

  /// Items the user has manually flipped to "ya lo tengo" from the shopping list.
  final Set<String> _manuallyHave = {};

  /// Flips an ingredient between "necesito comprar" ↔ "ya lo tengo".
  void toggleShoppingItem(String ingredient) {
    if (_manuallyHave.contains(ingredient)) {
      _manuallyHave.remove(ingredient);
    } else {
      _manuallyHave.add(ingredient);
    }
    notifyListeners();
  }

  void _enableWakelock() {
    try {
      // Errors are swallowed on both paths: an unsupported platform is not
      // something to tell the user about.
      WakelockPlus.enable().catchError((_) {});
    } catch (_) {}
  }

  void _disableWakelock() {
    try {
      WakelockPlus.disable().catchError((_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    // The screen may be popped mid-generation; never leave the lock held.
    _disableWakelock();
    super.dispose();
  }
}
