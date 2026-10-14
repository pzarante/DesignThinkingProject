/// El proyecto existe pero ya no se puede abrir: se borró (`deleted_at`).
///
/// Es distinto de que no exista un detalle guardado: eso es un `null` legítimo
/// y la pantalla arma uno con lo que traía el feed. Aquí no hay que armar
/// nada, porque lo que traía el feed es justo lo que ya no es válido.
///
/// `errorMessage` no la conoce y cae en su `toString()`, así que este texto
/// es el que acaba viendo la persona.
class ProjectUnavailableException implements Exception {
  const ProjectUnavailableException();

  @override
  String toString() => 'Este proyecto ya no está disponible.';
}
