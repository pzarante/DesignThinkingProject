import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/widgets/app_success_view.dart';
import '../../../home/domain/models/community.dart';

/// Confirmación de creación de comunidad. Recibe la [Community] por
/// argumentos.
class CommunityCreatedPage extends StatelessWidget {
  const CommunityCreatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final community = Get.arguments as Community;

    return Scaffold(
      body: Container(
        child: AppSuccessView(
          title: '¡Comunidad creada!',
          message:
              'Tu comunidad ${community.name} está lista. Invita a otros '
              'miembros a unirse y empezar a colaborar.',
          primaryLabel: 'Ver comunidad',
          // El detalle de comunidad todavía no existe como pantalla.
          onPrimary: () => Get.snackbar(
            'Sección aún no disponible',
            'El detalle de la comunidad llegará en una próxima entrega.',
          ),
          secondaryActions: [
            TextButton(
              onPressed: () => Get.offAllNamed(AppRoutes.home),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
