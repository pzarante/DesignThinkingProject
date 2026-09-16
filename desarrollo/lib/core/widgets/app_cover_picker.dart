import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Caja de subida de portada con borde punteado.
///
/// Mientras no haya backend ni selector de archivos, quien llama decide qué
/// hacer en [onTap]; este widget solo dibuja el estado vacío y la vista
/// previa cuando ya hay una imagen.
class AppCoverPicker extends StatelessWidget {
  const AppCoverPicker({
    super.key,
    required this.onTap,
    this.imageUrl,
    this.fileName,
    this.label = 'Haz click para subir o arrastra una imagen aquí',
    this.onRemove,
  });

  final VoidCallback onTap;
  final String? imageUrl;
  final String? fileName;
  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(imageUrl!, fit: BoxFit.cover),
            ),
          ),
          if (fileName != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(fileName!, style: theme.textTheme.bodySmall),
                  ),
                  if (onRemove != null)
                    TextButton(onPressed: onRemove, child: const Text('Quitar')),
                ],
              ),
            ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: theme.colorScheme.outline),
        child: SizedBox(
          height: 128,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.file_upload_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Borde punteado redondeado; evita añadir una dependencia solo para esto.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppSpacing.sm),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
