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
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/domain/child_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/selectable_card.dart';
import 'age_band.dart';
import 'onboarding_controller.dart';
import 'widgets/question_section.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final theme = Theme.of(context);

    return Scaffold(
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
            Text('Wawa Fuerte', style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Menús de la semana con hierro, con lo que ya tienes en casa.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // --- 1. Name. ----------------------------------------------------
            QuestionSection(
              // No slash: "niña/o" is a reading obstacle for someone who is
              // decoding rather than recognising words.
              question: '¿Cómo se llama tu niña o niño?',
              child: TextField(
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
                help:
                    'Es el número que anotaron en el cuadrito de Hemoglobina '
                    'de su carné. Si no lo encuentras, puedes dejarlo vacío.',
                optional: true,
                child: TextField(
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
                    // because it sits in hint styling and disappears on typing.
                    hintText: 'Por ejemplo: 10.5',
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),

            // --- 7. Caregiver name. The old "your name" screen, shrunk. ------
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
        ),
      ),

      // Anchored, not at the end of the scroll: always reachable, never hunted.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton(
          onPressed: controller.canSubmit && !controller.isSaving
              ? () => _submit(context)
              : null,
          child: const Text('Guardar y continuar'),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final controller = context.read<OnboardingController>();
    final navigator = Navigator.of(context);

    final saved = await controller.submit();
    if (saved == null) return;

    // Onboarding is first-run only, so it is replaced rather than stacked:
    // there is nothing to go back to.
    navigator.pushReplacementNamed(Routes.home);
  }

  static const Map<Region, String> _regionLabels = {
    Region.coast: 'Costa',
    Region.highlands: 'Sierra',
    Region.jungle: 'Selva',
  };

  static const Map<Sex, String> _sexLabels = {
    Sex.female: 'Niña',
    Sex.male: 'Niño',
    Sex.unspecified: 'Prefiero no decir',
  };
}
