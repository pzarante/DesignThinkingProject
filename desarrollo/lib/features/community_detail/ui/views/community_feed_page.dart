import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../home/domain/models/community.dart';
import '../../../notifications/ui/widgets/notifications_action.dart';
import '../../domain/models/community_detail.dart';
import '../viewmodels/community_detail_controller.dart';
import '../widgets/community_header.dart';
import '../widgets/community_project_card.dart';

/// Feed de una comunidad: quién es y qué proyectos la acompañan.
///
/// Recibe por [Get.arguments] el id de la comunidad, o la [Community] del
/// feed de inicio (de la que se toma el id).
class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  final CommunityDetailController controller = Get.find();

  @override
  void initState() {
    super.initState();
    final id = _communityId(Get.arguments);
    if (id != null) controller.load(id);
  }

  String? _communityId(Object? arguments) => switch (arguments) {
    String id => id,
    Community community => community.id,
    _ => null,
  };

  Future<void> _toggleMembership() async {
    await controller.toggleMembership();
    final error = controller.actionError.value;
    if (error.isEmpty) return;
    controller.actionError.value = '';
    showErrorSnack('No se pudo actualizar', message: error);
  }

  void _openSettings(CommunityDetail detail) {
    Get.toNamed(
      AppRoutes.communitySettings,
      arguments: Community(
        id: detail.id,
        name: detail.name,
        description: detail.description,
        coverUrl: detail.coverUrl,
        projectIds: [for (final project in detail.projects) project.id],
      ),
    )?.then((_) => controller.refreshCommunity());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final detail = controller.community.value;

        return RefreshIndicator(
          onRefresh: controller.refreshCommunity,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                title: const Text('Comunidad'),
                actions: [
                  const NotificationsAction(),
                  if (detail != null && detail.isOwner)
                    IconButton(
                      tooltip: 'Configurar comunidad',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => _openSettings(detail),
                    ),
                ],
              ),
              if (controller.isLoading.value || detail == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: _shortState()),
                )
              else
                SliverToBoxAdapter(child: _body(detail)),
            ],
          ),
        );
      }),
    );
  }

  Widget _shortState() {
    if (controller.isLoading.value) return const CircularProgressIndicator();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: AppEmptyState(
        icon: Icons.groups_outlined,
        title: 'No se pudo abrir la comunidad',
        message: controller.errorMessage.value,
        action: FilledButton.icon(
          onPressed: controller.refreshCommunity,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
    );
  }

  Widget _body(CommunityDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityHeader(
          community: detail,
          onToggleMembership: _toggleMembership,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: detail.projects.isEmpty
              ? const AppEmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'Todavía no hay proyectos aquí',
                  message:
                      'Cuando se vincule un proyecto a esta comunidad, '
                      'aparecerá en este feed.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.projects.length == 1
                          ? '1 proyecto en la comunidad'
                          : '${detail.projects.length} proyectos en la '
                                'comunidad',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final project in detail.projects)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CommunityProjectCard(project: project),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
