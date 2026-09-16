import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_segmented_tab_bar.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../home/domain/models/project.dart';
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
    controller.load(Get.arguments as Project);
  }

  void _notifyPending(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Postularse usa el flujo que ya existe en la feature home; aquí solo se
  /// abre desde la pantalla nueva.
  Future<void> _apply(ProjectDetail detail) async {
    final applicant = controller.currentUser.value;

    final submitted = await showApplicationForm(
      context,
      projectId: detail.projectId,
      applicantName: applicant?.name ?? 'Sin nombre',
      applicantEmail: applicant?.email ?? '',
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

      if (controller.isLoading.value || detail == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const AppTagChip(label: 'Proyecto'),
          actions: [
            if (detail.viewerRole.canConfigure)
              IconButton(
                tooltip: 'Configurar proyecto',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _openSettings(detail),
              )
            else
              IconButton(
                tooltip: 'Compartir',
                icon: const Icon(Icons.share_outlined),
                onPressed: () =>
                    _notifyPending('Compartir llegará en otra entrega.'),
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
                    onSelected: (index) =>
                        setState(() => _selectedTab = index),
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
              onSave: () => _notifyPending('Guardar llegará en otra entrega.'),
              onFollow: () => _notifyPending('Seguir llegará en otra entrega.'),
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
