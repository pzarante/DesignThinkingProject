import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_segmented_tab_bar.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../home/domain/models/project.dart';
import '../../../project_applications/ui/viewmodels/apply_controller.dart';
import '../../../project_applications/ui/viewmodels/applicants_controller.dart';
import '../../domain/models/project_detail.dart';
import '../viewmodels/project_detail_controller.dart';
import '../viewmodels/project_settings_controller.dart';
import '../widgets/application_form_sheet.dart';
import '../widgets/details_tab.dart';
import '../widgets/posts_tab.dart';
import '../widgets/project_detail_actions.dart';
import '../widgets/project_detail_header.dart';
import '../widgets/team_tab.dart';

/// Detalle completo de un proyecto publicado.
///
/// Recibe por [Get.arguments] el proyecto tal como lo conoce el feed y pide
/// a esta feature su información completa.
class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final ProjectDetailController controller = Get.find();

  /// El diseño abre en "Detalles".
  int _selectedTab = 1;

  static const List<String> _tabs = ['Publicaciones', 'Detalles', 'Equipo'];

  @override
  void initState() {
    super.initState();
    controller.load(Get.arguments as Project).then((_) {
      final detail = controller.detail;
      final applicant = controller.currentUser.value;
      if (detail == null) return;

      if (detail.viewerRole.canConfigure) {
        Get.find<ApplicantsController>().load(detail.projectId);
      }

      if (applicant == null) return;
      if (detail.viewerRole.belongsToProject) return;
      Get.find<ApplyController>().checkHasApplied(
        projectId: detail.projectId,
        applicantId: applicant.id,
      );
    });
  }

  void _notifyPending(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _shareProject(ProjectDetail detail) async {
    await Clipboard.setData(
      ClipboardData(text: 'innovation-hub://project/${detail.projectId}'),
    );
    if (mounted) _notifyPending('Enlace del proyecto copiado.');
  }

  /// Postularse usa el flujo que ya existe en la feature home; aquí solo se
  /// abre desde la pantalla nueva.
  Future<void> _apply(ProjectDetail detail) async {
    final applicant = controller.currentUser.value;

    final submitted = await showApplicationForm(
      context,
      projectId: detail.projectId,
      applicantId: applicant?.id ?? 'unknown',
      applicantName: applicant?.name ?? 'Sin nombre',
      applicantEmail: applicant?.email ?? '',
      openRoles: detail.openRoles,
    );

    if (submitted && mounted) _notifyPending('Postulación enviada.');
  }

  Future<void> _openSettings(ProjectDetail detail) async {
    final settingsController = Get.find<ProjectSettingsController>();
    settingsController.start(detail);
    await Get.toNamed(AppRoutes.projectSettings);

    final saved = settingsController.saved;
    if (saved != null) controller.applyUpdate(saved);
  }

  void _openDestination(int index) {
    final route = AppRoutes.mainDestinations[index];
    if (!AppRoutes.isRegistered(route)) {
      _notifyPending('Sección aún no disponible.');
      return;
    }
    Get.offAllNamed(route);
  }

  Widget _tabBody(ProjectDetail detail) {
    switch (_selectedTab) {
      case 0:
        return PostsTab(
          canPublish: detail.viewerRole.belongsToProject,
          onCreate: () =>
              _notifyPending('Crear publicación llegará en otra entrega.'),
        );
      case 2:
        return TeamTab(detail: detail);
      default:
        return DetailsTab(detail: detail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final detail = controller.detail;

      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (controller.errorMessage.value != null || detail == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    controller.errorMessage.value ??
                        'No se encontró el proyecto.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => controller.load(Get.arguments as Project),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const AppTagChip(label: 'Proyecto'),
          actions: [
            if (detail.viewerRole.canConfigure) ...[
              IconButton(
                tooltip: 'Postulaciones',
                onPressed: () => Get.toNamed(
                  AppRoutes.projectApplicants,
                  arguments: detail.projectId,
                ),
                icon: Badge(
                  isLabelVisible:
                      Get.find<ApplicantsController>().pending.isNotEmpty,
                  label: Text(
                    '${Get.find<ApplicantsController>().pending.length}',
                  ),
                  child: const Icon(Icons.person_add_alt_1_outlined),
                ),
              ),
              IconButton(
                tooltip: 'Configurar proyecto',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _openSettings(detail),
              ),
            ] else
              IconButton(
                tooltip: 'Compartir',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareProject(detail),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            ProjectDetailHeader(detail: detail),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSegmentedTabBar(
                    labels: _tabs,
                    selectedIndex: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  ),
                  _tabBody(detail),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProjectDetailActions(
              viewerRole: detail.viewerRole,
              onConfigure: () => _openSettings(detail),
              onCreatePost: () =>
                  _notifyPending('Crear publicación llegará en otra entrega.'),
              onApply: () => _apply(detail),
              onSave: () {
                controller.toggleSaved();
                _notifyPending(
                  controller.isSaved.value
                      ? 'Proyecto guardado.'
                      : 'Proyecto quitado de guardados.',
                );
              },
              onFollow: () {
                controller.toggleFollowing();
                _notifyPending(
                  controller.isFollowing.value
                      ? 'Ahora sigues este proyecto.'
                      : 'Dejaste de seguir este proyecto.',
                );
              },
              isSaved: controller.isSaved.value,
              isFollowing: controller.isFollowing.value,
              hasApplied: Get.find<ApplyController>().alreadyApplied.value,
              hasOpenRoles: detail.openRoles.isNotEmpty,
            ),
            AppBottomNavBar(
              currentIndex: 0,
              onDestinationSelected: _openDestination,
            ),
          ],
        ),
      );
    });
  }
}
