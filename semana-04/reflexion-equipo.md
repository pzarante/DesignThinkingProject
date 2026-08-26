# Reflexión del equipo

## Información del equipo

**Nombre del equipo:**

**Integrantes:**
* Natalia Carpintero - @Carpinteron
* Andrés Carrero - @AndresCarrero00
* Paula Núñez - @pzarante
* Andrés Serrano - @serranoaf23

---

## Decisiones tomadas

¿Qué decisiones importantes tomaron al construir el prototipo?

- **Organización modular por secciones de tablero:** Se estructuró el lienzo en módulos funcionales claros (*Crear - Innovation Hub*, *Descubrir - Innovation Hub*, *Mis Proyectos*, *Perfil de Usuario* y *Project Selector States*) para organizar visualmente los flujos principales sin perder el hilo de navegación.

- **Diseño de estados y variantes para postulación:** Se representaron diferentes variaciones de pantalla para un mismo flujo (por ejemplo, el detalle de proyecto con formulario modal vs. formulario embebido, y los estados de confirmación como *¡Postulación enviada!* o *¡Comunidad creada!*).

- **Estandarización de componentes móviles:** Se adoptó un kit de diseño consistente (Material 3 con tonalidades violeta), utilizando tarjetas de proyectos (`EcoCampus`, `MotionLab`), pills para etiquetas de rol/interés y navegación inferior unificada (*Feed, Explorar, Crear, Proyectos, Perfil*).

---

## Lo más difícil de representar

¿Qué parte de la idea fue más difícil convertir en prototipo?

Lo más complejo fue diseñar los estados del **Project Selector** y la transición entre crear una entidad independiente vs. una asociada a un grupo paraguas, asegurando que la interfaz reflejara con claridad la jerarquía entre la "Comunidad" y los "Proyectos derivados" dentro de la plataforma.

---

## Lo que todavía no sabemos

¿Qué dudas esperan resolver en la prueba con usuarios?

- ¿Resulta más intuitivo postularse a un proyecto mediante el modal emergente overlay o directamente leyendo la información en la vista expandida del proyecto?

- ¿Los usuarios identifican fácilmente la diferencia entre seguir a una comunidad completa y postularse a un proyecto específico dentro de ella?

- ¿La estructura de la pantalla de exploración facilita encontrar colaboradores por afinidad de intereses frente al filtrado tradicional?

---

## Riesgos del prototipo actual

¿Qué podría hacer que los resultados de la prueba sean confusos o poco útiles?

- **Alto detalle visual que distraiga del flujo:** Dado que el prototipo tiene un acabado visual casi final (alta fidelidad), los usuarios podrían enfocarse en evaluar la estética (colores, sombras, fotos) en lugar de evaluar la arquitectura de la navegación y la usabilidad.

- **Múltiples pantallas verticales:** Al haber tantos estados intermedios y formularios (*Screen_1* a *Screen_8*), el usuario evaluador podría desorientarse si no realiza la prueba con un recorrido interactivo estricto.

---

## Conclusión del equipo

Escriban un párrafo corto explicando si sienten que el prototipo es suficiente para aprender algo valioso de los usuarios.

El prototipo construido supera con creces la baja fidelidad esperada, ofreciendo una representación fiel e integral de la plataforma. Gracias a la amplitud de pantallas, estados de confirmación y variantes de interacción diseñadas tanto para *Crear* como para *Descubrir*, el recurso es sumamente valioso para realizar pruebas de usabilidad reales, observar cómo navegan los usuarios entre proyectos y comunidades, y validar si nuestro modelo de postulación por afinidad resuelve la problemática planteada.
