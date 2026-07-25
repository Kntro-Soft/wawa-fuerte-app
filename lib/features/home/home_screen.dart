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
/// about whether she broke something.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/route_arguments.dart';
import '../../app/routes.dart';
import '../../core/domain/child_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import 'home_controller.dart';

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
      appBar: AppBar(title: const Text('Wawa Fuerte')),
      body: SafeArea(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  if (controller.isEmpty)
                    // Home's empty state. Says what is missing, that it is
                    // normal, and the one thing to do about it.
                    const EmptyState(
                      icon: LucideIcons.users600,
                      title: 'Todavía no has registrado a nadie',
                      message:
                          'Registra a tu niña o niño para armar su menú de '
                          'la semana.',
                    )
                  else ...[
                    Text(
                      '¿Para quién cocinamos?',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final child in controller.children) ...[
                      _ChildCard(
                        child: child,
                        planSummary: _planSummary(controller, child),
                        onTap: () => Navigator.of(context).pushNamed(
                          Routes.plan,
                          arguments: PlanArguments(child: child),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ],
              ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton(
          onPressed: () => Navigator.of(context).pushNamed(Routes.onboarding),
          child: const Text('Agregar otro niño o niña'),
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
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.planSummary,
    required this.onTap,
  });

  final ChildProfile child;
  final String planSummary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      child: Material(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.selectableCardHeight,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: AppColors.outline,
                width: AppSpacing.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Names are never truncated — see RecipeRow for the same
                      // rule applied to dishes.
                      Text(child.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(planSummary, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const ExcludeSemantics(
                  child: Icon(
                    LucideIcons.chevronRight600,
                    size: AppSpacing.actionIconSize,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
