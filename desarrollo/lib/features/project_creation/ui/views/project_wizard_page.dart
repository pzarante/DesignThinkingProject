import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_wizard_progress.dart';
import '../viewmodels/project_creation_controller.dart';
import '../widgets/basics_step.dart';
import '../widgets/goal_step.dart';
import '../widgets/problem_step.dart';
import '../widgets/resources_step.dart';
import '../widgets/stage_step.dart';
import '../widgets/team_step.dart';

/// Asistente de creación de proyecto: seis pasos sobre la misma ruta, con la
/// barra de progreso arriba y las acciones fijas abajo.
class ProjectWizardPage extends StatefulWidget {
  const ProjectWizardPage({super.key});

  @override
  State<ProjectWizardPage> createState() => _ProjectWizardPageState();
}

class _ProjectWizardPageState extends State<ProjectWizardPage> {
  final ProjectCreationController controller = Get.find();

  @override
  void initState() {
    super.initState();
    // Entrar al asistente siempre empieza un borrador nuevo; volver desde la
    // revisión no pasa por aquí, así que no se pierde lo escrito.
    final arguments = Get.arguments;
    controller.startDraft(
      fromCommunity:
          arguments is Map && arguments['fromCommunity'] == true,
    );
  }

  void _goBack() {
    if (controller.currentStep.value == 1) {
      Get.back();
      return;
    }
    controller.previousStep();
  }

  void _goForward() {
    if (controller.currentStep.value < ProjectCreationController.totalSteps) {
      controller.nextStep();
      return;
    }
    Get.toNamed(AppRoutes.createProjectReview);
  }

  Widget _stepBody(int step) {
    switch (step) {
      case 1:
        return StageStep(controller: controller);
      case 2:
        return BasicsStep(controller: controller);
      case 3:
        return ProblemStep(controller: controller);
      case 4:
        return GoalStep(controller: controller);
      case 5:
        return TeamStep(controller: controller);
      default:
        return ResourcesStep(controller: controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBack),
        title: Obx(() => Text(controller.currentStepTitle)),
      ),
      body: Obx(() {
        final step = controller.currentStep.value;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            AppWizardProgress(
              currentStep: step,
              totalSteps: ProjectCreationController.totalSteps,
            ),
            const SizedBox(height: AppSpacing.lg),
            _stepBody(step),
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          secondaryLabel: 'Atrás',
          onSecondary: _goBack,
          primaryLabel:
              controller.currentStep.value ==
                  ProjectCreationController.totalSteps
              ? 'Revisar proyecto'
              : 'Siguiente',
          onPrimary: controller.canContinue ? _goForward : null,
        ),
      ),
    );
  }
}
