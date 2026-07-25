/// Onboarding: one scrollable screen (old Flow 0 + Flow A merged).
///
/// OWNER: P3 (UI).
///
/// ## What was removed, and why
///
/// **The doctor's photograph.** It implied a clinical endorsement the app does
/// not have — Wawa Fuerte is not a medical device, it has no clinician behind
/// it, and it must not be read as a substitute for the CRED check-up. It was
/// also visibly AI-generated, which is exactly the wrong first impression for a
/// tool asking a mother to trust it with her child's nutrition. The header is
/// now the wordmark, one line saying what the app does, and the first question.
/// **No pictures of people anywhere in this app**, and no purple circle with a
/// heart in it either.
///
/// **The mother's-name screen.** A whole screen, and a whole tap, to personalise
/// a greeting. It is now the last field here, clearly marked optional.
///
/// **The segmented progress bar.** See [QuestionSection].
///
/// ## What replaced them
///
/// The screen asks its questions in one column, largest-first, with the CTA
/// anchored at the bottom of the viewport rather than at the bottom of the
/// scroll — so the way forward is visible from the first frame instead of being
/// something the user has to discover by scrolling.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/domain/child_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/andean_band.dart';
import '../../core/widgets/selectable_card.dart';
import '../../core/widgets/spanish_date.dart';
import 'age_band.dart';
import 'onboarding_controller.dart';
import 'widgets/question_section.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Seeded once from the controller so editing opens with the child's name
  /// already in the box. Owned by the state, like the budget field on the plan
  /// form: a controller rebuilt every frame would fight the keyboard.
  ///
  /// **The hemoglobin field gets no equivalent, on purpose.** It is the one
  /// input in this app that must never open with a number in it.
  TextEditingController? _name;

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  TextEditingController _nameField(OnboardingController controller) {
    return _name ??= TextEditingController(text: controller.childName);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final theme = Theme.of(context);
    final editing = controller.isEditing;

    return Scaffold(
      // Show an AppBar with a back arrow whenever there is something to go back
      // to — this covers both "Agregar otro niño" (pushed from Home) and the
      // edit flow. First-run has nothing behind it and shows no bar at all.
      appBar: (editing || Navigator.canPop(context))
          ? AppBar(
              title: Text(
                editing
                    ? 'Los datos de ${controller.existing!.name}'
                    : 'Registrar niña o niño',
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xl,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            // --- Header. No illustration, no photograph, no mascot. ----------
            if (!editing) ...[
              Text('Wawa Fuerte', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              // The one ornamental mark on the screen, under the wordmark.
              const AndeanBand(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Menús de la semana con hierro, con lo que ya tienes en casa.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],

            // --- 1. Name. ----------------------------------------------------
            QuestionSection(
              // No slash: "niña/o" is a reading obstacle for someone who is
              // decoding rather than recognising words.
              question: '¿Cómo se llama tu niña o niño?',
              child: TextField(
                controller: _nameField(controller),
                onChanged: controller.setChildName,
                textCapitalization: TextCapitalization.words,
                style: theme.textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Escribe su nombre',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // --- 2. Age, as ranges. ------------------------------------------
            QuestionSection(
              question: '¿Qué edad tiene?',
              child: Column(
                children: [
                  for (final band in AgeBand.values) ...[
                    SelectableCard(
                      label: band.label,
                      description: band.description,
                      selected: controller.ageBand == band,
                      onTap: () => controller.setAgeBand(band),
                    ),
                    if (band != AgeBand.values.last)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // --- 3. Region. --------------------------------------------------
            QuestionSection(
              question: '¿Dónde viven?',
              help: 'Así te sugerimos comidas que se consiguen por tu zona.',
              child: Column(
                children: [
                  for (final entry in _regionLabels.entries) ...[
                    SelectableCard(
                      label: entry.value,
                      // Coast, highlands and jungle are the one set of options
                      // here a picture genuinely helps with: the three are told
                      // apart by landscape long before they are read.
                      leading: _regionIcons[entry.key],
                      selected: controller.region == entry.key,
                      onTap: () => controller.setRegion(entry.key),
                    ),
                    if (entry.key != _regionLabels.keys.last)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // --- 4. Sex. Optional, and no crossed-out-eye icon. --------------
            //
            // The old build marked "Prefiero no decir" with an eye-with-a-slash.
            // In every app a user has ever seen, that glyph means "hide the
            // password". Here the option is just a third card with a label, like
            // the other two.
            QuestionSection(
              question: '¿Es niña o niño?',
              optional: true,
              child: Column(
                children: [
                  for (final entry in _sexLabels.entries) ...[
                    SelectableCard(
                      label: entry.value,
                      selected: controller.sex == entry.key,
                      onTap: () => controller.setSex(entry.key),
                    ),
                    if (entry.key != _sexLabels.keys.last)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // --- 5. CRED booklet (ADR-0007). ---------------------------------
            QuestionSection(
              question: '¿Tienes a la mano el carné de tu wawa?',
              help:
                  'Es el cuadernito que te dan en la posta cada vez que la '
                  'pesan y la miden. Si no lo tienes, no importa: igual '
                  'armamos el menú.',
              child: Column(
                children: [
                  for (final answer in CredAnswer.values) ...[
                    SelectableCard(
                      label: answer.label,
                      leading: _credIcons[answer],
                      selected: controller.credAnswer == answer,
                      onTap: () => controller.setCredAnswer(answer),
                    ),
                    if (answer != CredAnswer.values.last)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),

            // --- 6. Hemoglobin. Only when the booklet is at hand. ------------
            if (controller.credAnswer == CredAnswer.yes) ...[
              const SizedBox(height: AppSpacing.xxl),
              QuestionSection(
                question: '¿Qué número dice en Hemoglobina?',
                // Never "Hemoglobina (Hb)" and never "g/dL" bare. The help text
                // tells her where to look, which is the only thing she needs.
                help: editing && controller.existing!.hasHemoglobin
                    ? 'Si le hicieron un control nuevo, escribe aquí el '
                          'número de ese control. Si lo dejas vacío, se queda '
                          'el que ya teníamos.'
                    : 'Es el número que anotaron en el cuadrito de Hemoglobina '
                          'de su carné. Si no lo encuentras, puedes dejarlo '
                          'vacío.',
                optional: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The reading on file is shown as *text*, never poured into
                    // the input. See OnboardingController's class doc.
                    if (editing && controller.existing!.hasHemoglobin) ...[
                      _StoredReading(child: controller.existing!),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    TextField(
                      // Never prefilled. The field starts empty and stays empty
                      // until she types — see OnboardingController.
                      onChanged: controller.setHemoglobinText,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: theme.textTheme.titleLarge,
                      decoration: const InputDecoration(
                        // A grey example, not a value. It is visibly an example
                        // because it sits in hint styling and disappears on
                        // typing.
                        hintText: 'Por ejemplo: 10.5',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // --- 7. Caregiver name. Asked once, on the first run only. -------
            //
            // After that it lives behind the button on the Home header. See
            // OnboardingController.asksCaregiverName.
            if (controller.asksCaregiverName) ...[
              const SizedBox(height: AppSpacing.xxl),
              QuestionSection(
                question: '¿Cómo te llamamos?',
                optional: true,
                child: TextField(
                  onChanged: controller.setCaregiverName,
                  textCapitalization: TextCapitalization.words,
                  style: theme.textTheme.titleLarge,
                  decoration: const InputDecoration(hintText: 'Tu nombre'),
                ),
              ),
            ],
          ],
        ),
      ),

      // Anchored, not at the end of the scroll: always reachable, never hunted.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton(
          onPressed: controller.canSubmit && !controller.isSaving
              ? () => _submit(context)
              : null,
          child: Text(editing ? 'Guardar los cambios' : 'Guardar y continuar'),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final controller = context.read<OnboardingController>();
    final navigator = Navigator.of(context);
    final editing = controller.isEditing;

    final saved = await controller.submit();
    if (saved == null) return;

    if (editing) {
      // Editing was pushed from Home, which reloads when this pops.
      navigator.pop();
      return;
    }

    // Registration is reached with nothing worth going back to, so it is
    // replaced rather than stacked.
    navigator.pushReplacementNamed(Routes.home);
  }

  static const Map<Region, String> _regionLabels = {
    Region.coast: 'Costa',
    Region.highlands: 'Sierra',
    Region.jungle: 'Selva',
  };

  /// Landscape, not flags or crests: what a family sees out of the door.
  static const Map<Region, IconData> _regionIcons = {
    Region.coast: LucideIcons.waves600,
    Region.highlands: LucideIcons.mountain600,
    Region.jungle: LucideIcons.treePalm600,
  };

  /// The booklet, the booklet put away, and the honest question mark for
  /// "no sé qué es eso" — which ADR-0007 requires as a real answer, not as a
  /// dead end.
  static const Map<CredAnswer, IconData> _credIcons = {
    CredAnswer.yes: LucideIcons.notebookPen600,
    CredAnswer.no: LucideIcons.bookX600,
    CredAnswer.unknown: LucideIcons.circleQuestionMark600,
  };

  static const Map<Sex, String> _sexLabels = {
    Sex.female: 'Niña',
    Sex.male: 'Niño',
    Sex.unspecified: 'Prefiero no decir',
  };
}

/// The reading already on file, shown while editing.
///
/// Read-only by construction: it is a `Text`, not a field, so there is no way
/// for an old number to be re-saved as if it had been measured today. Its date
/// is spelled out because a reading's age is what tells the caregiver whether
/// it is still worth anything.
class _StoredReading extends StatelessWidget {
  const _StoredReading({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = child.hemoglobin!.toStringAsFixed(1).replaceAll('.', ',');
    final date = child.hemoglobinDate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(
          color: AppColors.outline,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Icon(
              LucideIcons.notebookPen600,
              size: AppSpacing.iconSize,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El número que ya tenemos es $value',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Lo anotaste el ${spanishDate(date)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
