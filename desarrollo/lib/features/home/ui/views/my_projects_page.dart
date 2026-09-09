import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../app_routes.dart';
import '../../domain/models/project.dart';
import '../viewmodels/home_controller.dart';

/// My Projects screen — shows the complete list of the user's projects with
/// the ability to pin / unpin each one. Pinned projects appear at the top.
class MyProjectsPage extends StatelessWidget {
  const MyProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController ctrl = Get.find();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis Proyectos'),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final query = ctrl.searchQuery.value.trim().toLowerCase();
        final projects = ctrl.feed.myProjects.where((p) {
          return query.isEmpty || p.name.toLowerCase().contains(query);
        }).toList()
          ..sort((a, b) {
            if (a.isPinned == b.isPinned) return 0;
            return a.isPinned ? -1 : 1;
          });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: AppSearchBar(
                hintText: 'Buscar mis proyectos...',
                onChanged: ctrl.setSearchQuery,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: projects.isEmpty
                  ? const Center(child: Text('No tienes proyectos aún.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.scrollBottomInset,
                      ),
                      itemCount: projects.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) =>
                          _ProjectListTile(project: projects[index], ctrl: ctrl),
                    ),
            ),
          ],
        );
      }),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onDestinationSelected: (index) => _openDestination(index),
      ),
    );
  }

  void _openDestination(int index) {
    const destinations = ['/home', '/explore', '/my-projects', '/profile'];
    final route = destinations[index];
    if (route == '/my-projects') return;
    Get.offAllNamed(route);
  }
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({required this.project, required this.ctrl});

  final Project project;
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: project.imageUrl != null
              ? Image.network(
                  project.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(colors),
                )
              : _placeholder(colors),
        ),
        title: Text(project.name, style: theme.textTheme.titleMedium),
        subtitle: Wrap(
          spacing: AppSpacing.xs,
          children: [
            if (project.stage != null) AppTagChip(label: project.stage!),
            Text(
              '${project.memberCount} integrante${project.memberCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: project.isPinned ? 'Desanclar' : 'Anclar',
          icon: Icon(
            project.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: project.isPinned ? colors.primary : colors.onSurfaceVariant,
          ),
          onPressed: () => ctrl.togglePin(project.id),
        ),
        onTap: () => Get.toNamed(
          AppRoutes.projectDetail,
          arguments: project,
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colors) => Container(
        width: 56,
        height: 56,
        color: colors.surfaceContainerHighest,
        child: Icon(Icons.image_outlined, color: colors.onSurfaceVariant),
      );
}
