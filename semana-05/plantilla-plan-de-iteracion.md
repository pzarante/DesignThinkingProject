# Plan de iteración

## Información del equipo

**Nombre del equipo:**

**Integrantes:**
* Natalia Carpintero - @Carpinteron
* Andrés Carrero - @AndresCarrero00
* Paula Núñez - @pzarante
* Andrés Serrano - @serranoaf23


---

## Qué debemos cambiar

¿Qué aspectos del prototipo integrado necesitan ajuste inmediato después de esta nueva validación?

1. Reorganizar la jerarquía del Home.
La validación evidenció que la pantalla inicial presenta elementos cuya prioridad puede mejorarse. Se propone dar mayor relevancia a la sección “Recomendados para ti”, seguida de las comunidades que sigue el usuario. Además, el acceso a proyectos debería centrarse en los proyectos anclados y en los dos proyectos visitados más recientemente, reduciendo contenido que no aporte directamente a la navegación principal.

2. Completar el flujo de postulaciones de los proyectos.
Se identificó la ausencia de una vista que permita a los miembros de un proyecto consultar las personas que se han postulado, junto con la información necesaria para valorar su participación y establecer contacto. Este flujo debe incorporarse para completar la interacción entre proyectos y personas interesadas.

3. Mejorar la claridad visual y el acceso a acciones principales.
Se requiere aumentar el tamaño de algunos textos que actualmente tienen poca legibilidad, eliminar frases pequeñas que no aportan información relevante y mantener la acción de “Crear” visible mediante un comportamiento sticky. También debe revisarse el propósito y ubicación del buscador del Home debido a las dudas expresadas durante la validación sobre su utilidad.
---

## Prioridades

Clasifiquen los cambios propuestos.

### Cambios urgentes

- Incorporar la vista de postulantes de los proyectos, incluyendo la información necesaria para su revisión y contacto.
- Reorganizar el Home para priorizar “Recomendados para ti”, las comunidades seguidas y los proyectos de mayor relevancia.
- Corregir problemas de legibilidad y jerarquía visual en los elementos de la interfaz.

### Cambios importantes

- Definir una lógica clara para mostrar los proyectos anclados o los dos proyectos visitados más recientemente.
- Mantener la acción “Crear” disponible mediante un componente sticky.
- Revisar la utilidad, ubicación y función del buscador dentro del Home antes de decidir si debe mantenerse, modificarse o trasladarse.

- 

- 

### Ideas para más adelante

- Mejorar la visualización del progreso de los proyectos para facilitar su seguimiento.
- Continuar depurando textos secundarios y microcopias a partir de nuevas pruebas de usabilidad.
- Explorar futuras mejoras de personalización de las recomendaciones según el comportamiento y los intereses del usuario.

- 

- 

---

## Decisión del equipo

Después de validar, ¿qué decisión toman?

- Mantener la estructura general y mejorar detalles.
- [x] Ajustar algunos flujos importantes.
- Replantear parte de la integración entre flujos.
- Cambiar el enfoque del problema.

☑ **Ajustar algunos flujos importantes.**

La validación no evidencia la necesidad de replantear el problema ni la estructura general de la propuesta. Sin embargo, sí permitió identificar oportunidades de mejora en la organización del Home, la navegación hacia los proyectos y la gestión de postulantes. Además, se detectaron problemas de legibilidad y elementos cuya utilidad no está suficientemente justificada. Por ello, el equipo decide conservar la propuesta general y realizar una nueva iteración enfocada en mejorar estos aspectos antes de avanzar a la implementación.

---

## Próximo paso

¿Qué debería hacer el equipo en la siguiente iteración o etapa de desarrollo?

- Rediseñar la estructura del Home y validar nuevamente la jerarquía de contenidos, priorizando las recomendaciones, comunidades y proyectos relevantes.
- Diseñar e integrar el flujo de postulaciones, permitiendo a los miembros del proyecto consultar la información de las personas interesadas y establecer contacto.
- Realizar una nueva prueba de usabilidad centrada en navegación, legibilidad, comprensión de las acciones principales y utilidad del buscador.

- 

- 

---

## Nivel de preparación para implementación

Después de esta etapa, ¿cómo se encuentra el equipo?

- Listo para pasar a una implementación inicial.
- [x] Necesita una iteración más antes de implementar.
- Debe replantear una parte importante de la propuesta.


☑ Necesita una iteración más antes de implementar.

El prototipo cuenta con una estructura suficientemente definida para continuar su desarrollo, pero aún presenta ajustes funcionales y de experiencia de usuario que deben resolverse. En particular, el flujo de postulaciones está incompleto y existen decisiones de navegación y jerarquía visual que requieren validación adicional. Una iteración más permitirá consolidar estos aspectos y reducir modificaciones durante la implementación inicial.
