import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../auth/ui/viewmodels/authentication_controller.dart';
import '../../domain/models/profile_project.dart';
import '../../domain/models/user_profile.dart';
import '../viewmodels/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_project_card.dart';
import '../widgets/profile_stats_row.dart';

/// Perfil de una persona: el propio cuando se entra por la barra inferior, o
/// el de otra cuando se llega desde la búsqueda de Explorar.
///
/// Recibe por [Get.arguments] el `users.user_id` a mostrar; sin argumento se
/// entiende "el mío".
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController controller = Get.find();

  @override
  void initState() {
    super.initState();
    controller.load(userId: Get.arguments as String?);
  }

  Future<void> _openLogin() async {
    await Get.toNamed(AppRoutes.login);
    await controller.load();
  }

  Future<void> _openSignUp() async {
    await Get.toNamed(AppRoutes.signup);
    await controller.load();
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Podrás seguir viendo proyectos, pero no crear ni comentar con tu '
          'cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;

    await Get.find<AuthenticationController>().logOut();
    await controller.load();
  }

  void _openDestination(int index) {
    final route = AppRoutes.mainDestinations[index];
    if (route == AppRoutes.profile) {
      // Estando en el perfil de otra persona, "Perfil" vuelve al propio en
      // vez de no hacer nada.
      if (!controller.isOwnProfile.value) controller.load();
      return;
    }
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final profile = controller.profile.value;

        return RefreshIndicator(
          onRefresh: controller.refreshProfile,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(
                  controller.isOwnProfile.value ? 'Mi perfil' : 'Perfil',
                ),
                actions: [
                  if (controller.isOwnProfile.value && profile != null)
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      icon: const Icon(Icons.logout),
                      onPressed: _logOut,
                    ),
                ],
              ),
              SliverToBoxAdapter(child: _body(profile)),
            ],
          ),
        );
      }),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onDestinationSelected: _openDestination,
      ),
    );
  }

  Widget _body(UserProfile? profile) {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.needsAccount.value) return _guestState();

    if (profile == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppEmptyState(
          icon: Icons.person_off_outlined,
          title: 'No se pudo abrir el perfil',
          message: controller.errorMessage.value,
          action: FilledButton.icon(
            onPressed: controller.refreshProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      );
    }

    final created = controller.createdProjects;
    final joined = controller.joinedProjects;
    final owner = controller.isOwnProfile.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileHeader(profile: profile),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.scrollBottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileStatsRow(stats: profile.stats),
              _aboutCard(profile),
              AppSectionHeader(
                title: owner ? 'Mis proyectos' : 'Proyectos que creó',
              ),
              if (created.isEmpty)
                _emptyLine(
                  owner
                      ? 'Todavía no has publicado ningún proyecto.'
                      : 'Todavía no ha publicado ningún proyecto.',
                )
              else
                ..._cards(created),
              if (joined.isNotEmpty) ...[
                AppSectionHeader(
                  title: owner ? 'También participo en' : 'También participa en',
                ),
                ..._cards(joined),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _cards(List<ProfileProject> projects) => [
    for (final project in projects)
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ProfileProjectCard(project: project),
      ),
  ];

  Widget _emptyLine(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Datos de contacto y antigüedad. El correo solo en el perfil propio: la
  /// tabla `users` es legible para cualquiera, pero enseñarlo en el perfil de
  /// otra persona es otra cosa.
  Widget _aboutCard(UserProfile profile) {
    final rows = <Widget>[
      if (controller.isOwnProfile.value && profile.email != null)
        _InfoRow(icon: Icons.mail_outline, text: profile.email!),
      if (profile.joinedAt != null)
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          text: 'En Innovation Hub desde ${_monthYear(profile.joinedAt!)}',
        ),
    ];
    if (rows.isEmpty) return const SizedBox(height: AppSpacing.sm);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ),
    );
  }

  Widget _guestState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.scrollBottomInset,
      ),
      child: AppEmptyState(
        icon: Icons.account_circle_outlined,
        title: 'Aquí va tu perfil',
        message:
            'Estás viendo Innovation Hub como invitado. Con una cuenta puedes '
            'crear proyectos, formar equipo y que otros te encuentren por tu '
            'nombre de usuario.',
        action: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _openSignUp,
                child: const Text('Crear cuenta'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openLogin,
                child: const Text('Ya tengo cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// "marzo de 2025". A mano porque el proyecto no usa `intl` y añadirlo solo
  /// para una línea no se justifica.
  String _monthYear(DateTime date) => '${_months[date.month - 1]} de ${date.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
