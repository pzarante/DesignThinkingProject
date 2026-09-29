import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/widgets/app_success_view.dart';

/// Confirmación del registro.
///
/// Recibe por [Get.arguments] el nombre de usuario recién creado, para poder
/// enseñarlo tal como lo van a ver los demás.
class SignUpSuccessPage extends StatelessWidget {
  const SignUpSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = Get.arguments as String?;

    return Scaffold(
      body: AppSuccessView(
        title: '¡Tu cuenta está lista!',
        message: userName == null || userName.isEmpty
            ? 'Ya puedes crear proyectos, formar equipo y participar en '
                  'comunidades.'
            : 'Los demás te verán como @$userName. Ya puedes crear proyectos, '
                  'formar equipo y participar en comunidades.',
        primaryLabel: 'Ver mi perfil',
        onPrimary: () => Get.offAllNamed(AppRoutes.profile),
        secondaryActions: [
          TextButton(
            onPressed: () => Get.offAllNamed(AppRoutes.home),
            child: const Text('Ir al inicio'),
          ),
        ],
      ),
    );
  }
}
