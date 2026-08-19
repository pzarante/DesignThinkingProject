# Prototipos de baja resolución por flujo

> Este entregable debe estar acompañado por dos prototipos de baja resolución realizados en Figma por cada flujo priorizado.
> Los prototipos pueden ser independientes entre sí; no es necesario integrarlos todavía en una sola experiencia completa.

## Información del equipo

**Nombre del equipo:** Equipo de Diseño de Experiencia e Innovación

**Integrantes:**
* Natalia Carpintero - @Carpinteron
* Andrés Carrero - @AndresCarrero00
* Paula Núñez - @pzarante
* Andrés Serrano - @serranoaf23

---

## Instrucción general

Repitan esta estructura para cada flujo priorizado. Si el equipo trabaja solo 2 o 3 flujos, puede dejar vacío el último bloque.

---

## Flujo 1

**Nombre del flujo:** Creación de proyecto / comunidad

**¿Qué quiere lograr el usuario en este flujo?**

Publicar una idea de forma estructurada —ya sea como proyecto independiente, como proyecto dentro de una comunidad existente, o creando una comunidad nueva— completando los campos mínimos necesarios (problema, objetivo, alcance, etapa actual, habilidades o roles requeridos, referencias visuales) para que deje de ser una idea suelta e informal y se convierta en algo que otros puedan entender y a partir de lo cual puedan decidir sumarse.

### Versión A: paso a paso

1. El usuario entra al feed y toca el botón "+ Crear".
2. Elige qué quiere crear: un proyecto o una comunidad.
3. Completa un único formulario con scroll que reúne todos los campos requeridos según lo que eligió (proyecto: nombre, comunidad/independiente, problema, objetivo, alcance, etapa, roles, referencias; comunidad: nombre, descripción, imagen de portada).
4. Toca "Publicar" y llega a una pantalla de confirmación que lo lleva al perfil recién creado.

### Versión A: pantallas o momentos clave

1. Feed con botón "+ Crear"
2. Pantalla de decisión "¿Qué quieres crear?" (Proyecto / Comunidad)
3. Formulario único con scroll (proyecto o comunidad, según lo elegido)
4. Confirmación y perfil del proyecto o comunidad creado

### Versión B: paso a paso

1. El usuario entra al feed y toca el botón "+ Crear".
2. Elige qué quiere crear: un proyecto o una comunidad.
3. Avanza por una secuencia de pantallas cortas (wizard), completando un campo o grupo pequeño de campos por paso, con indicador de progreso visible.
4. Al llegar al último paso toca "Publicar" y llega a una pantalla de confirmación que lo lleva al perfil recién creado.

### Versión B: pantallas o momentos clave

1. Feed con botón "+ Crear"
2. Pantalla de decisión "¿Qué quieres crear?" (Proyecto / Comunidad)
3. Secuencia de pasos del wizard (6 pasos si es proyecto, 3 si es comunidad), cada uno con número de paso, barra de progreso y botón "Siguiente"
4. Confirmación y perfil del proyecto o comunidad creado

### Evidencia en Figma

**Enlace versión A:** https://twist-anime-74641097.figma.site/

**Enlace versión B:** https://magic-loom-82785747.figma.site/

### Resultado de la validación exploratoria

**¿Con quién se probó este flujo?**
Estudiantes universitarios con experiencia previa liderando iniciativas académicas y proyectos multidisciplinares.

**¿Qué reacción generó la versión A?**
- Los usuarios percibieron el formulario en scroll como una tarea pesada y algo abrumadora al ver tantos campos vacíos al mismo tiempo.
- Hubo dudas sobre si todos los campos eran obligatorios desde el primer momento.
- Se valoró positivamente tener una visión global de todo lo solicitado en una sola vista antes de empezar a escribir.

**¿Qué reacción generó la versión B?**
- La barra de progreso y la división por pasos redujo significativamente la fatiga visual y la sensación de esfuerzo cognitivo.
- Facilitó concentrarse en redactar bien cada aspecto (problema, objetivos, roles) de forma secuencial.
- Algunos usuarios sugirieron poder volver atrás fácilmente a editar un paso anterior sin perder lo completado.

### Versión seleccionada para la semana 4

**Versión elegida:** Versión B

**¿Por qué?**
- Reduce drásticamente la tasa de abandono durante la carga inicial de información al dosificar la complejidad mediante un *wizard*.
- Facilita estructurar la idea paso a paso con mayor claridad y detalle, alineándose con el objetivo de evitar publicaciones incompletas o poco aterrizadas.
- La retroalimentación visual de avance genera una sensación de progreso continuo que motiva al usuario a finalizar la publicación.

---

## Flujo 2

**Nombre del flujo:** Interacción y descubrimiento de proyectos por intereses

**¿Qué quiere lograr el usuario en este flujo?**

Descubrir iniciativas activas (proyectos independientes o comunidades) a partir de intereses y afinidades temáticas, interactuar con ellas (seguir comunidades, explorar subproyectos o detalles) y postularse como colaborador indicando su disponibilidad e información solicitada por el equipo.

### Versión A: paso a paso

1. El usuario navega en el Feed Principal filtrando mediante etiquetas de intereses (#Sostenibilidad, #EdTech, #Diseño) y selecciona un proyecto o una comunidad.
2. Si elige un proyecto, ingresa a la pantalla de detalle para revisar información, prototipos y roles requeridos, y pulsa el botón "Postularse".
3. Se despliega una ventana emergente (*modal* de postulación) donde diligencia sus datos y selecciona su disponibilidad (Full-time, Part-time, Voluntario) antes de presionar "Enviar postulación".
4. Llega a la pantalla de confirmación con opciones para "Volver al proyecto" o "Ir al feed". (Si elige una comunidad, entra a su perfil, puede seguirla y explorar sus proyectos activos en una vista dedicada).

### Versión A: pantallas o momentos clave

1. Feed Principal (con barra de tags temáticos y cards de proyectos/comunidades)
2. Detalle del Proyecto / Perfil de Comunidad (con botón "Seguir")
3. Modal de Postulación (con selector de disponibilidad horaria) / Listado de Proyectos de Comunidad
4. Pantalla de Confirmación de postulación

### Versión B: paso a paso

1. El usuario entra a un Hub de Categorías estructurado por temas (Diseño, Tecnología, Comunidad, Educación) con pestañas para alternar entre Comunidades, Proyectos y Guardados.
2. Si elige la ruta de Proyecto Independiente, ingresa a una vista donde el formulario de postulación está integrado de manera directa (*inline*) al final del detalle del proyecto.
3. Completa los campos en la misma pantalla y presiona el botón "Postularme ahora".
4. Llega a la pantalla de confirmación ("¡Solicitud recibida por el equipo!"). (Si elige la ruta de Comunidad Paraguas, entra al perfil general, sigue la comunidad, selecciona un subproyecto en convocatoria y pulsa "Aplicar al subproyecto").

### Versión B: pantallas o momentos clave

1. Hub de Categorías (vista modular por tarjetas temáticas y tabs de navegación)
2. Proyecto con Formulario Inline / Perfil de Comunidad Paraguas (con lista de convocatorias y subproyectos)
3. Pantalla de Confirmación / Vista de Detalle de Subproyecto (con roles requeridos y botón de aplicación)

### Evidencia en Figma

**Enlace versión A:** https://myrtle-read-21921139.figma.site/

**Enlace versión B:** https://fawn-mute-79794124.figma.site/

### Resultado de la validación exploratoria

**¿Con quién se probó este flujo?**
Estudiantes universitarios interesados en participar como colaboradores en proyectos y colectivos afines a sus intereses personales.

**¿Qué reacción generó la versión A?**
- Los usuarios destacaron la inmediatez del feed para explorar libremente sin sentirse encasillados en carpetas rígidas.
- La postulación mediante modal se sintió ligera y no interrumpió la navegación contextual en el perfil del proyecto.
- Los tags temáticos (#EdTech, #Sostenibilidad) fueron intuitivos para filtrar afinidades rápidamente.

**¿Qué reacción generó la versión B?**
- El hub por categorías aportó mucho orden para entender qué tipos de iniciativas existen en la plataforma.
- Sin embargo, el formulario *inline* en la misma pantalla del proyecto alargó demasiado el scroll y mezcló la lectura de información con la acción de postularse.
- Algunos usuarios encontraron redundante navegar tantos niveles (Hub > Comunidad > Subproyecto) para llegar a la convocatoria.

### Versión seleccionada para la semana 4

**Versión elegida:** Versión A

**¿Por qué?**
- Ofrece una experiencia de descubrimiento orgánico y espontáneo mediante tags temáticos, respetando el insight de exploración por afinidad.
- El uso de un modal para la postulación mantiene la pantalla principal despejada y enfoca al usuario únicamente en completar su disponibilidad y datos requeridos.
- Reduce el número de clics y pantallas intermedias necesarias para conectarse o postularse a una iniciativa.

---

## Flujo 3

**Nombre del flujo:**

**¿Qué quiere lograr el usuario en este flujo?**

### Versión A: paso a paso

1. El usuario...
2. Luego...
3. Después...
4. Finalmente...

### Versión A: pantallas o momentos clave

1.
2.
3.
4.

### Versión B: paso a paso

1. El usuario...
2. Luego...
3. Después...
4. Finalmente...

### Versión B: pantallas o momentos clave

1.
2.
3.
4.

### Evidencia en Figma

**Enlace versión A:**

**Enlace versión B:**

### Resultado de la validación exploratoria

**¿Con quién se probó este flujo?**

**¿Qué reacción generó la versión A?**

- 
- 
- 

**¿Qué reacción generó la versión B?**

- 
- 
- 

### Versión seleccionada para la semana 4

**Versión elegida:**

**¿Por qué?**

- 
- 
- 

---

## Flujo 4

**Nombre del flujo:**

**¿Qué quiere lograr el usuario en este flujo?**

### Versión A: paso a paso

1. El usuario...
2. Luego...
3. Después...
4. Finalmente...

### Versión A: pantallas o momentos clave

1.
2.
3.
4.

### Versión B: paso a paso

1. El usuario...
2. Luego...
3. Después...
4. Finalmente...

### Versión B: pantallas o momentos clave

1.
2.
3.
4.

### Evidencia en Figma

**Enlace versión A:**

**Enlace versión B:**

### Resultado de la validación exploratoria

**¿Con quién se probó este flujo?**

**¿Qué reacción generó la versión A?**

- 
- 
- 

**¿Qué reacción generó la versión B?**

- 
- 
- 

### Versión seleccionada para la semana 4

**Versión elegida:**

**¿Por qué?**

- 
- 
-
