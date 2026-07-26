/// Home: pick a child, see this week's status (Flow E).
///
/// OWNER: P3 (UI).
///
/// The domain supports **any number of children** and so does this screen —
/// there is no "primary child" and no cap. Each child is one card carrying her
/// name and one line about her week, and "Agregar otro niño o niña" is a real,
/// permanent entry at the end of the list rather than a small `+` in a corner.
///
/// Removed from the old header: the **profile icon**. It went nowhere — there is
/// no account, no settings screen and no server to have an account on (ADR-0002)
/// — and a control that does nothing costs a user a tap and a moment of doubt
/// about whether she broke something. What sits in the header now is the
/// opposite case: a labelled button that opens one dialog and changes one thing,
/// her own name. It is in the body rather than in the app bar, so the bar stays
/// what it was — a title and nothing else.
///
/// ## Three targets per card, not three targets in a row
///
/// A card does three things — open the week, edit the child, delete her — and
/// the failure mode to avoid is three controls a few millimetres apart under a
/// wet fingertip. So the card is split: the **whole upper block** opens the
/// week, and the two administrative actions sit below a rule, in their own row,
/// each 56 dp tall and 12 dp apart, each with its word beside its icon. Editing
/// and deleting are rare; opening the week happens every time, and the layout
/// says so.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/route_arguments.dart';
import '../../app/routes.dart';
import '../../core/domain/child_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/andean_band.dart';
import '../../core/widgets/empty_state.dart';
import 'home_controller.dart';
import 'widgets/caregiver_name_dialog.dart';
import 'widgets/child_card.dart';
import 'widgets/delete_child_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Reloads on every entry, including on the way back from a generated plan,
    // so the week status a caregiver sees is never stale.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final theme = Theme.of(context);

    return Scaffold(
      // No status chip here: it lives in the app shell so it is on every
      // route, not only on the one screen that happened to draw it.
      appBar: AppBar(title: const Text('Wawa Fuerte')),
      body: SafeArea(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                children: [
                  _GreetingHeader(
                    caregiverName: controller.caregiverName,
                    onChangeName: _changeCaregiverName,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (controller.isEmpty)
                    // Home's empty state. Says what is missing, that it is
                    // normal, and the one thing to do about it.
                    const EmptyState(
                      icon: LucideIcons.users600,
                      title: 'Todavía no has registrado a nadie',
                      message:
                          'Registra a tu niña o niño y armamos su menú de la '
                          'semana con lo que tengas en casa.',
                    )
                  else ...[
                    Row(
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            LucideIcons.cookingPot600,
                            size: AppSpacing.iconSize,
                            color: AppColors.earth,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            '¿Para quién cocinamos?',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final (index, child) in controller.children.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ChildCard(
                          child: child,
                          accentIndex: index,
                          planSummary: _planSummary(controller, child),
                          planIcon: _planIcon(controller, child),
                          onTap: () => Navigator.of(context).pushNamed(
                            Routes.plan,
                            arguments: PlanArguments(child: child),
                          ),
                          onHistory: () => Navigator.of(context).pushNamed(
                            Routes.planHistory,
                            arguments: PlanHistoryArguments(child: child),
                          ),
                          onEdit: () => _editChild(child),
                          onDelete: () => _deleteChild(child),
                        ),
                      ),
                  ],
                ],
              ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton.icon(
          onPressed: _addChild,
          icon: const Icon(
            LucideIcons.userPlus600,
            size: AppSpacing.actionIconSize,
          ),
          label: const Text('Agregar otro niño o niña'),
        ),
      ),
    );
  }

  /// The week's status in one sentence, or the "no plan yet" empty state for
  /// that child.
  String _planSummary(HomeController controller, ChildProfile child) {
    final plan = controller.planFor(child.id);
    if (plan == null) {
      return 'Todavía no tiene menú de esta semana';
    }
    if (plan.preparedCount == 0) {
      return 'Su menú está listo · 7 comidas';
    }
    return 'Preparaste ${plan.preparedCount} de 7 comidas';
  }

  /// The mark that goes with [_planSummary]. Never shown without it.
  IconData _planIcon(HomeController controller, ChildProfile child) {
    final plan = controller.planFor(child.id);
    if (plan == null) return LucideIcons.calendarPlus600;
    if (plan.preparedCount == 0) return LucideIcons.bookOpen600;
    return LucideIcons.circleCheck600;
  }

  Future<void> _addChild() async {
    await Navigator.of(context).pushNamed(Routes.onboarding);
    if (mounted) await context.read<HomeController>().load();
  }

  /// Opens the registration form on a child who already exists (see
  /// [OnboardingArguments]) and picks up whatever changed when it pops.
  Future<void> _editChild(ChildProfile child) async {
    await Navigator.of(context).pushNamed(
      Routes.onboarding,
      arguments: OnboardingArguments(child: child),
    );
    if (mounted) await context.read<HomeController>().load();
  }

  /// Never deletes without asking: the write cascades to every plan the child
  /// ever had, and there is no undo and no backup (ADR-0013).
  Future<void> _deleteChild(ChildProfile child) async {
    final confirmed = await showDeleteChildDialog(
      context,
      childName: child.name,
    );
    if (!confirmed || !mounted) return;

    final controller = context.read<HomeController>();
    final messenger = ScaffoldMessenger.of(context);
    await controller.deleteChild(child.id);

    messenger.showSnackBar(
      SnackBar(content: Text('Se borraron los datos de ${child.name}')),
    );
  }

  Future<void> _changeCaregiverName() async {
    final controller = context.read<HomeController>();
    // Null means she cancelled; an empty string means she cleared the name.
    // They are different answers and the dialog keeps them apart.
    final typed = await showCaregiverNameDialog(
      context,
      currentName: controller.caregiverName,
    );
    if (typed == null) return;
    await controller.setCaregiverName(typed);
  }
}

/// The greeting, and the only way to change the name in it.
///
/// The name is never invented: with nothing stored the greeting is simply
/// "Hola" and the button says what it would do. Flow 0's old default addressed
/// a mother as "Usuario" — a word from a login screen she never saw, for an
/// account that does not exist.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.caregiverName,
    required this.onChangeName,
  });

  final String? caregiverName;
  final VoidCallback onChangeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final named = caregiverName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          decoration: const BoxDecoration(color: AppColors.earthContainer),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  named ? 'Hola, $caregiverName' : 'Hola',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.onEarthContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              TextButton.icon(
                onPressed: onChangeName,
                style: ButtonStyle(
                  foregroundColor: const WidgetStatePropertyAll(
                    AppColors.onEarthContainer,
                  ),
                  minimumSize: const WidgetStatePropertyAll(
                    Size(0, AppSpacing.minTouchTarget),
                  ),
                  // No underline here: the band already separates this from the
                  // running text, and an underlined label inside a tinted strip
                  // reads as a web link.
                  textStyle: WidgetStatePropertyAll(
                    theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                icon: const Icon(
                  LucideIcons.pencil600,
                  size: AppSpacing.iconSize,
                ),
                label: Text(named ? 'Mi nombre' : 'Poner mi nombre'),
              ),
            ],
          ),
        ),
        // The one ornamental mark on the screen. See AndeanBand.
        const AndeanBand(),
      ],
    );
  }
}
