import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/app_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_segmented_tab_bar.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../app_routes.dart';
import '../../../../core/widgets/app_choice_chip_row.dart';
import '../../../notifications/ui/widgets/notifications_action.dart';
import '../../domain/models/project.dart';
import '../viewmodels/home_controller.dart';

/// My Projects screen — shows the complete list of the user's projects with
/// the ability to pin / unpin each one. Pinned projects appear at the top.
class MyProjectsPage extends StatefulWidget {
  const MyProjectsPage({super.key});

  @override
  State<MyProjectsPage> createState() => _MyProjectsPageState();
}

/// Secciones de "Mis Proyectos" según la relación con cada proyecto.
enum _Section {
  all('Todos', Icons.folder_open_outlined),
  created('Creados por mi cuenta', Icons.edit_note_outlined),
  joined('Creados por alguien más de los que hago parte', Icons.groups_outlined),
  pending('Postulaciones pendientes', Icons.hourglass_empty_outlined);

  const _Section(this.label, this.icon);
  final String label;

  /// Ícono del estado vacío de la sección.
  final IconData icon;

  bool matches(Project project) {
    // Null = datos en memoria, donde todo lo propio es creado por el usuario.
    final relation = project.myRelation ?? MyProjectRelation.creator;
    return switch (this) {
      _Section.all => true,
      _Section.created => relation == MyProjectRelation.creator,
      _Section.joined => relation == MyProjectRelation.member,
      _Section.pending => relation == MyProjectRelation.pendingApplication,
    };
  }

  String get emptyTitle => switch (this) {
    _Section.all => 'No tienes proyectos aún',
    _Section.created => 'Aún no has creado ningún proyecto',
    _Section.joined => 'Todavía no haces parte de otro equipo',
    _Section.pending => 'No tienes postulaciones pendientes',
  };

  String get emptyMessage => switch (this) {
    _Section.all =>
      'Crea un proyecto o postúlate a una vacante para verlo aquí.',
    _Section.created => 'Los proyectos que crees aparecerán aquí.',
    _Section.joined => 'Cuando acepten una postulación tuya, aparecerá aquí.',
    _Section.pending => 'Explora proyectos y postúlate a una vacante.',
  };
}

class _MyProjectsPageState extends State<MyProjectsPage> {
  final HomeController ctrl = Get.find();
  _Section _section = _Section.all;
  String _selectedStage = 'Todos';

  static const int _mineTab = 0;
  static const List<String> _tabs = ['Míos', 'Guardados'];

  /// Qué lista se está viendo: los proyectos propios o los que se guardaron
  /// desde el detalle de un proyecto ajeno.
  int _tab = _mineTab;

  @override
  void initState() {
    super.initState();
    // Postularse, ser aceptado o salir de un equipo pasa en otras pantallas
    // (o en otros dispositivos): se relee al entrar. Después del primer
    // frame: `getFeed` cambia `isLoading` al instante, y hacerlo en pleno
    // build marca como sucio el `Obx` del inicio, que sigue montado debajo.
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.getFeed());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: AppKeys.myProjectsPage,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis Proyectos'),
        actions: const [NotificationsAction()],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    ctrl.errorMessage.value!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: ctrl.getFeed,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final query = ctrl.searchQuery.value.trim().toLowerCase();
        final source = _tab == _mineTab
            ? ctrl.feed.myProjects
            : ctrl.feed.savedProjects;
        final projects = source.where((p) {
          final matchesQuery =
              query.isEmpty || p.name.toLowerCase().contains(query);
          final matchesStage =
              _selectedStage == 'Todos' || p.stage == _selectedStage;
          // Las secciones son de los propios; los guardados no tienen relación.
          final matchesSection = _tab != _mineTab || _section.matches(p);
          return matchesQuery && matchesStage && matchesSection;
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
              child: Column(
                children: [
                  AppSegmentedTabBar(
                    labels: _tabs,
                    selectedIndex: _tab,
                    onSelected: (index) => setState(() => _tab = index),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSearchBar(
                    hintText: _tab == _mineTab
                        ? 'Buscar mis proyectos...'
                        : 'Buscar en guardados...',
                    onChanged: ctrl.setSearchQuery,
                  ),
                ],
              ),
            ),
            if (_tab == _mineTab)
              Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: AppChoiceChipRow<_Section>(
                options: _Section.values,
                labelBuilder: (section) => section.label,
                selected: _section,
                onSelected: (section) => setState(() => _section = section),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: AppChoiceChipRow<String>(
                options: const ['Todos', 'Investigación', 'Equipo', 'Prototipo'],
                labelBuilder: (stage) => stage,
                selected: _selectedStage,
                onSelected: (stage) =>
                    setState(() => _selectedStage = stage),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: projects.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: _tab == _mineTab &&
                              !source.any(_section.matches)
                          // Vacío propio de la sección, no de la búsqueda.
                          ? AppEmptyState(
                              icon: _section.icon,
                              title: _section.emptyTitle,
                              message: _section.emptyMessage,
                            )
                          : Center(
                              child: Text(
                                source.isEmpty
                                    ? 'Todavía no has guardado ningún '
                                          'proyecto. Abre uno que te interese '
                                          'y toca Guardar.'
                                    : 'No hay proyectos con este filtro.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.scrollBottomInset,
                      ),
                      itemCount: projects.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) =>
                          _ProjectListTile(project: projects[index], ctrl: ctrl),
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.create),
        icon: const Icon(Icons.add),
        label: const Text('Crear'),
      ),
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
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        tileColor: Colors.transparent,
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
                  errorBuilder: (_, _, _) => _placeholder(colors),
                )
              : _placeholder(colors),
        ),
        title: Text(project.name, style: theme.textTheme.titleMedium),
        subtitle: Wrap(
          spacing: AppSpacing.xs,
          children: [
            if (project.myRelation == MyProjectRelation.pendingApplication)
              const AppTagChip(label: 'Postulación pendiente'),
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
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Get.toNamed(AppRoutes.projectDetail, arguments: project);
        },
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
