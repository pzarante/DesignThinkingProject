# Planeación del prototipo integrado

> Este entregable debe estar acompañado por un prototipo realizado en Figma.
> En esta etapa se espera un prototipo de baja o media fidelidad que integre los flujos aprobados en la semana 3 y permita una validación más amplia.

## Información del equipo

**Nombre del equipo:**

**Integrantes:**
* Natalia Carpintero - @Carpinteron
* Andrés Carrero - @AndresCarrero00
* Paula Núñez - @pzarante
* Andrés Serrano - @serranoaf23

---

## Flujos que vamos a integrar

Escriban los flujos aprobados en la semana 3 que harán parte de este prototipo.

1. **Flujo 1: Creación de proyecto / comunidad.** Publicación y estructuración de una propuesta mediante campos mínimos (problema, objetivo, etapa, roles requeridos y referencias).

2. **Flujo 2: Interacción y descubrimiento por intereses.** Exploración del feed, filtrado por afinidades, interacción (seguir, guardar, comentar) y postulación a proyectos.

3. 

4. 

---

## Objetivo del prototipo

¿Qué quieren mostrar o comprobar al integrar estos flujos en un solo prototipo?

Queremos comprobar la continuidad y la experiencia completa de punta a punta (*end-to-end*): desde el momento en que un usuario crea y publica una idea/comunidad de forma estructurada, hasta que otros usuarios la descubren en el feed por afinidad de intereses, interactúan con ella y completan el proceso de postulación para unirse al equipo.

---

## Alcance

¿Qué sí incluirá el prototipo?

1. **Creación estructurada (Flujo 1):** Wizard de creación paso a paso para proyectos y comunidades independientes o paraguas, incluyendo la pantalla de confirmación (*¡Proyecto creado!* / *¡Comunidad creada!*).

2. **Feed de descubrimiento e interacción (Flujo 2):** Navegación en el feed unificado (*Descubrir - Innovation Hub*), filtrado por chips de intereses (`#Sostenibilidad`, `#EdTech`), vistas detalladas de proyectos (`EcoCampus`, `MotionLab`) y perfiles de comunidad.

3. **Mecanismos de postulación:** Variantes de postulación mediante modal deslizable (*BottomSheet*) y formulario integrado (*inline*), junto con pantallas de confirmación de postulación enviada.

¿Qué no incluirá por ahora?

- Funcionalidad backend real o persistencia de datos activa (base de datos real).
- Sistema de mensajería o chat privado en tiempo real entre colaboradores.
- Gestión avanzada de perfiles (configuración de cuenta profunda, ajustes de privacidad o pasarela de notificaciones push).

---

## Pantallas, escenas o partes principales

Enumeren los elementos que van a construir y cómo se conectan entre sí.

1. **Pantalla de Inicio / Feed Principal (`Screen_1_Inicio`):** Muestra el feed de proyectos destacados, comunidades activas y accesos rápidos a la creación o búsqueda.

2. **Wizard de Creación (`Screen_2_Cre...` a `Screen_8_Wiz...`):** Formulario multinivel para ingresar problema, objetivos, etapa de desarrollo, roles necesarios y referencias visuales.

3. **Pantallas de Confirmación (`proyecto-cre...` / `comunidad-cr...`):** Mensajes de éxito que confirman la publicación y redirigen al feed o al perfil creado.

4. **Vista Detallada del Proyecto (`detalle-ecoca...` / `Screen_Detail...`):** Presentación completa de la idea, etapa actual (`Prototipo v1.0`), miembros del equipo, sección de feedback/comentarios y botón de postulación.

5. **Modal / Formulario de Postulación (`modal-postul...` / `postulacion-e...`):** Espacio donde el usuario responde preguntas personalizadas sobre su motivación, disponibilidad y roles de interés.

6. **Vistas de Perfil y Mis Proyectos (`Screen_Perfil` / `Screen_Mis_P...`):** Paneles de control del usuario para consultar sus proyectos guardados, comunidades seguidas y estado de sus publicaciones.

---

## Integración entre flujos

¿Cómo se conectan entre sí los flujos aprobados?

- **Conexión Creación -> Feed:** Una vez finalizado el formulario de creación (Flujo 1) y confirmada la publicación, el nuevo proyecto o comunidad se indexa automáticamente y aparece como disponible dentro del feed de descubrimiento (Flujo 2).

- **Conexión Feed -> Detalle de Proyecto:** Al hacer clic en cualquier tarjeta del feed filtrada por intereses (Flujo 2), el usuario transiciona hacia la vista detallada del proyecto.

- **Conexión Detalle -> Postulación:** Desde la vista detallada del proyecto, el usuario acciona el botón de postularse, lo que despliega el formulario/modal para unirse al equipo de trabajo.

---

## Herramienta de trabajo

¿Cómo construirán el prototipo integrado?

**Herramienta esperada:** Figma

Si usan algún apoyo adicional, indíquenlo aquí:

- Componentes y estilos basados en **Material 3 UI Kit**.
- Plugin de conectores de flujo / prototipado interactivo interno de Figma.

---

## Hipótesis a validar

¿Qué creen que sucederá cuando un usuario vea o use este prototipo?

- Creemos que los usuarios entenderán rápidamente la jerarquía entre una "Comunidad" (grupo paraguas) y un "Proyecto" (iniciativa concreta) al recorrer el feed y las vistas detalladas.

- Creemos que el proceso de postulación adaptativo (enfocado en intereses y disponibilidad en lugar de solo filtros técnicos) despertará mayor disposición a colaborar.

- Sabremos que vamos por buen camino si el usuario logra completar el recorrido desde la exploración hasta la postulación de forma fluida y sin dudar sobre qué información debe proporcionar en cada paso.

---

## Evidencia en Figma

Peguen aquí el enlace al archivo o prototipo de Figma:

**Enlace:** https://www.figma.com/design/TNSqcY87HO8JV2opLYShfy/Sin-t%C3%ADtulo?node-id=0-1&t=82vhRviTqGCXLvmB-1

¿Qué puede recorrer o ver una persona dentro de ese prototipo?

- El flujo completo de creación de una iniciativa desde el botón `+ Crear` hasta la pantalla de éxito.
- La exploración del feed interactivo filtrando por temas de interés y haciendo scroll por las tarjetas de proyectos (`EcoCampus`, `MotionLab`).
- Las dos alternativas de postulación (modal emergente sobrepuesto vs. formulario integrado en la vista detallada del proyecto).
