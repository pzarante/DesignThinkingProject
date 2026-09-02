# Reflexión final de la primera etapa

## Información del equipo

**Nombre del equipo:**

**Integrantes:**
* Natalia Carpintero - @Carpinteron
* Andrés Carrero - @AndresCarrero00
* Paula Núñez - @pzarante
* Andrés Serrano - @serranoaf23


---

## Lo que aprendimos del problema

¿Cómo cambió su comprensión del problema desde la semana 1 hasta la semana 5?

En conjunto, pasamos de creer que el problema era "falta de personas interesadas" (semana 1), a entenderlo como "incertidumbre antes de colaborar" (semana 2), a traducirlo en necesidades concretas de estructuración y descubrimiento (semana 3), a descubrir que esa incertidumbre también vive en las transiciones entre flujos (semana 4), y finalmente a confirmar que es una tensión que se debe seguir gestionando activamente incluso después de haber validado los flujos por separado (semana 5).

---

## Lo que aprendimos de la solución

¿Qué descubrieron sobre los flujos y la solución integrada que decidieron prototipar?

Descubrimos que estructurar una idea y descubrirla por afinidad funcionan mejor cuando se dosifica la información en lugar de presentarla toda de una vez. El wizard por pasos para creación redujo la sobrecarga que sí generaba un formulario único con scroll, y el feed con tags temáticos y postulación mediante modal facilitó una exploración más orgánica que un hub de categorías rígidas o un formulario integrado en la misma pantalla del proyecto. Esta preferencia se confirmó dos veces con las mismas personas: primero en la validación exploratoria de la semana 3, y de nuevo en la prueba más amplia de la semana 4, donde Juan David valoró que pedir referencias visuales y etapa actual "evita vender humo", y Mariana reafirmó su preferencia por el modal porque "se siente más como una aplicación directa" sin perder la vista del contenido.

Al construir el prototipo integrado en la semana 4 también aprendimos algo que no esperábamos: nuestro propio prototipo terminó teniendo un acabado casi de alta fidelidad, lo que representaba un riesgo real de que los usuarios evaluaran la estética en lugar de la navegación. Y en la validación de la semana 5, integrar los flujos ya validados por separado sacó a la luz fricciones nuevas que no eran visibles antes: reorganizar la jerarquía del Home mejoró la percepción de relevancia, pero redujo la encontrabilidad de proyectos antiguos; resolver el vacío del flujo de postulaciones con una vista de postulantes solucionó un problema, pero generó otro, la falta de un camino claro de regreso al detalle del proyecto. Esto nos enseñó que integrar flujos que funcionan bien de forma aislada no garantiza que funcionen bien juntos, y que cada mejora puede traer consigo una fricción nueva que solo se detecta probando la experiencia completa.

---

## Valor de la validación

¿Qué aportó validar primero versiones exploratorias y luego un prototipo más integrado antes de desarrollar una versión más completa?

Validar en varias rondas, con las mismas tres personas (Juan David, Mariana y Daniela) representando perfiles distintos, nos permitió construir evidencia acumulada en lugar de opiniones aisladas. En la semana 3, las versiones exploratorias de baja resolución nos dejaron tomar decisiones de fondo (wizard sobre formulario único, feed con modal sobre hub de categorías) sin haber invertido tiempo en una experiencia completa. En la semana 4, probar el prototipo integrado con un guion de prueba más estructurado confirmó esas decisiones con los mismos usuarios y, además, dejó ver preguntas nuevas, como si la jerarquía visual del Project Selector realmente comunicaba bien la diferencia entre comunidad y proyecto.

Pasar a un prototipo aún más integrado en la semana 5 permitió detectar problemas que solo aparecen cuando los flujos conviven en una sola experiencia, como la jerarquía de información en el Home o la desconexión de navegación en la vista de postulantes. La comparación explícita entre la semana 4 y la semana 5 nos dio evidencia concreta de qué cambios sí funcionaron y cuáles seguían pendientes, algo que no hubiéramos logrado si hubiéramos ido directo de la investigación inicial a una implementación de mayor fuerza. En conjunto, este proceso escalonado de validación nos permitió llegar a la semana 5 con decisiones basadas en lo que usuarios reales mostraron, y no en lo que como equipo asumíamos desde la semana 1.

---

## Principal decisión

¿Cuál es la decisión más importante que toma el equipo después de esta etapa?

La decisión más importante es no avanzar todavía a una implementación de mayor fuerza y realizar una iteración adicional de diseño antes de ese paso. La validación de la semana 5 mostró que tanto el problema definido desde la semana 2 (reducir la incertidumbre antes y durante la formación de un equipo) como la propuesta general de solución siguen siendo válidos, por lo que no es necesario replantearlos desde cero. Sin embargo, sí existen ajustes funcionales y de experiencia, como la navegación de la vista de postulantes, la lógica de "Mis Proyectos" y la utilidad real del buscador del Home, que de no resolverse antes generarían fricciones evitables una vez comience el desarrollo. Priorizar esta última iteración de diseño es, en este momento, más valioso que adelantar tiempo de implementación.

---

## Conclusión final

Escriban un párrafo de 8 a 12 líneas respondiendo esta pregunta:

`¿Qué aprendió el equipo sobre diseñar una solución real antes de empezar a implementarla con más fuerza?`

Como equipo aprendimos que diseñar una solución real exige estar dispuestos a que los supuestos iniciales cambien: llegamos pensando que el problema era "falta de personas interesadas" y terminamos entendiendo que era "falta de estructura para comunicar una idea" y "falta de mecanismos para reducir la incertidumbre antes de comprometerse", algo que solo se hizo visible al escuchar directamente a Daniela, Mariana y Juan David desde la semana 1. También aprendimos que cada decisión que resuelve un problema puede abrir uno nuevo, como vimos al integrar el flujo de postulaciones o al reorganizar el Home en la semana 5, y que esto solo se descubre probando con usuarios reales en distintos niveles de fidelidad, no asumiendo que una buena idea de diseño funcionará igual de bien una vez integrada al resto de la experiencia. Validar en varias rondas, con los mismos perfiles de usuario y comparando explícitamente qué mejoró y qué sigue pendiente frente a la iteración anterior, nos dio la disciplina de tomar decisiones basadas en evidencia y no en la intuición o comodidad del equipo. Finalmente, comprendimos que reconocer que "aún no estamos listos para implementar" no es un retraso, sino una decisión responsable: el tiempo invertido en esta última iteración de diseño se traducirá en menos retrabajo y en una solución más alineada con lo que realmente necesitan las personas que buscan estructurar ideas y formar equipos compatibles.

