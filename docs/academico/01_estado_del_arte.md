# Estado del arte

**Versión para revisión del director.** Estilo APA 7. Las citas usan las claves del `referencias.bib` del plan de grado (`Degree Proyect.zip`), salvo que se indique lo contrario.  
**Alcance de la búsqueda:** no se declara una revisión sistemática protocolizada (criterios PRISMA, doble cribado, etc.). Se apoya en monografías de referencia, artículos de comparación y documentación oficial de códigos citados por el propio plan.

---

## 1. Propósito de este capítulo

El capítulo no sustituye un curso de dinámica de gases. Sitúa el proyecto —un *framework* compacto para las ecuaciones de Euler por volúmenes finitos— frente a (a) los métodos numéricos que el artefacto debe implementar o comparar, (b) el software científico ya existente y (c) las prácticas de ingeniería de software científico. El cierre formula un **hueco acotado**, no un vacío absoluto en la literatura.

La pregunta de investigación del plan exige intercambiabilidad de reconstrucción, solver de Riemann e integrador, y cuantificación del error. Ese requisito define los criterios de comparación: no el número de modelos físicos ni el rendimiento en clúster.

---

## 2. Fundamentos numéricos pertinentes

### 2.1 Leyes de conservación hiperbólicas y Euler

Las ecuaciones de Euler para un gas ideal no viscoso y sin conducción de calor son el prototipo de sistema hiperbólico conservativo sobre el que se diseñan esquemas de captura de choques (Toro, 2009; LeVeque, 2002; Hirsch, 2007). En forma conservativa, el vector de estado $U=(\rho,\rho\mathbf{v},E)$ y el flujo físico $F(U)$ garantizan que la discretización pueda conservar masa, momento y energía celda a celda, condición necesaria para localizar discontinuidades (Toro, 2009).

Las soluciones pueden desarrollar choques, rarefacciones y discontinuidades de contacto. El contacto —salto de densidad con presión y velocidad continuas— es el criterio clásico que distingue esquemas de dos ondas (familia HLL) de esquemas que restauran la onda intermedia (HLLC), tal como se expone en Toro (2009). Esa distinción es el núcleo **numérico** del banco de pruebas del proyecto, no un detalle de implementación.

### 2.2 Volúmenes finitos y problema de Riemann local

El método de volúmenes finitos parte de la forma integral y aproxima el flujo en cada cara mediante un problema de Riemann entre estados izquierdo y derecho (LeVeque, 2002). La semidiscretización unidimensional en malla uniforme es

$$
\frac{\mathrm{d}U_i}{\mathrm{d}t}=-\frac{1}{\Delta x}\bigl(\hat F_{i+1/2}-\hat F_{i-1/2}\bigr),
$$

con $\hat F$ el flujo numérico. Un esquema de primer orden toma estados constantes por celda; MUSCL eleva el orden en zonas suaves mediante una reconstrucción lineal limitada (Toro, 2009). El paso de tiempo explícito queda acotado por una condición CFL (Hirsch, 2007; Toro, 2009).

El solver de Riemann **exacto** existe para Euler y se usa como **referencia de verificación de código y de solución**, no como modelo físico experimental (Toro, 2009; Oberkampf y Roy, 2010). Es iterativo y costoso si se llamara en cada cara y cada paso; por eso los esquemas de producción usan aproximaciones. En el núcleo C++ del proyecto esa separación está implementada: el exacto no participa en el avance (inspección del repositorio).

### 2.3 HLL, HLLE y HLLC (según Toro, 2009)

Toro (2009) documenta la familia HLL: dos velocidades de onda $S_L$, $S_R$ y un estado intermedio promedio, lo que **difumina el contacto**. HLLC introduce $S^*$ y dos estados estrella, restaurando la onda de contacto a coste moderado. HLLE, en la misma monografía, se distingue por la **estimación de velocidades** (Einfeldt), no por una estructura de tres ondas.

**Implicación para el repositorio (IMPLEMENTED vs PROPOSED):** el código C++ 1D implementa HLL con estimaciones tipo Davis y HLLC, no HLLE. Afirmar que el entregable actual «compara HLLE y HLLC» sería falso. Comparar **HLL y HLLC** en el mismo problema (p. ej. el test de contacto casi estacionario de Toro) sí está al alcance del prototipo. Incluir HLLE es una **extensión** sujeta a decisión del director.

Liska y Wendroff (2003) muestran que, en baterías 1D y 2D de Euler, distintos esquemas se ordenan de forma distinta según el caso: no hay un único «mejor» solver. Eso justifica un banco de pruebas controlado, no un ranking universal.

### 2.4 Límites de la solución exacta

El Riemann exacto 1D no cubre fuentes, geometría radial, ni la mayoría de configuraciones 2D. Esos casos exigen referencias de alta resolución publicadas o *manufactured solutions* (Oberkampf y Roy, 2010). Llamar «validación física» a un tubo de choque contra el exacto es un error de nomenclatura: es **verificación**.

---

## 3. Software existente (evidencia, no caricatura)

Los criterios se derivan de los objetivos: intercambiar un componente, reproducir un experimento, y (si el TG lo incluye) ver el método en el código. No se evalúa «quién simula un avión».

### 3.1 Implementaciones en el estado del arte

Una pregunta práctica al resolver las ecuaciones de Euler por volúmenes finitos es cómo cambiar el solver de Riemann sin reescribir el resto del código. En *Clawpack: Building an Open Source Ecosystem for Solving Hyperbolic PDEs*, Mandli et al. (2016) describen Clawpack como un paquete de volúmenes finitos de alta resolución basado en solvers de Riemann y limitadores, organizado de modo que esos solvers se concentran en un repositorio común y comparten una interfaz. Así, Classic, AMRClaw, GeoClaw y PyClaw pueden emplear el mismo núcleo de ondas y velocidades de onda. En los paquetes Fortran la selección se hace al compilar, mediante el *Makefile* del problema; en PyClaw se elige en tiempo de ejecución. La documentación oficial del paquete de Riemann lista, para Euler unidimensional, las aproximaciones HLL, HLLC y Roe. Ese diseño no inventa HLL ni HLLC: muestra que la intercambiabilidad del flujo numérico ya está realizada en software científico maduro. Para este trabajo, el antecedente es directo: un *framework* modular que permite comparar reconstrucción y flujo sobre Euler cartesiano se apoya en una práctica ya documentada, y no en la pretensión de ser el primer código en el que se pueda sustituir HLLC.

Por otro lado, una vez que varios esquemas pueden ejecutarse, hace falta compararlos sobre los mismos problemas. En *Comparison of Several Difference Schemes on 1D and 2D Test Problems for the Euler Equations*, Liska y Wendroff (2003) implementan ocho métodos explícitos de al menos segundo orden —centrales y *upwind*, con y sin descomposición de ondas, entre ellos Clawpack con Roe y un esquema WAF con HLLC— y los aplican a una batería común: problemas de Riemann unidimensionales con solución exacta (incluidos casos de Toro), la onda de explosión de Woodward–Colella y pruebas bidimensionales. En una dimensión reportan errores relativos en norma $L^1$ frente a la solución exacta y muestran que el ordenamiento cambia con el caso; algunos esquemas fallan en pruebas concretas. En dos dimensiones, salvo excepciones, no hay solución exacta, y los autores advierten que entonces el juicio es en buena parte subjetivo. El estudio no declara un método universalmente superior. Aporta, en cambio, evidencia de que la calidad depende de la combinación método–problema y de que la comparación exige mallas, normas y casos fijos. Eso respalda el banco de pruebas de este proyecto: variar de a un componente (por ejemplo, HLL frente a HLLC, o el limitador MUSCL) sobre los mismos tests unidimensionales, con el solver exacto de Riemann como referencia de *verificación*, sin inferir un ranking general a partir de una demostración aislada.

### 3.2 OpenFOAM

Weller et al. (1998) describen el enfoque tensorial orientado a objetos de lo que originó OpenFOAM. Jasak (2009) lo sitúa en investigación e industria: mallas no estructuradas, muchos modelos, código abierto. **No** se afirma aquí que sea imposible cambiar un flujo numérico: el código es accesible. Lo que sí es defendible, como **interpretación** (no como hallazgo experimental propio), es que la curva de aprendizaje y el tamaño del árbol de fuentes no están orientados a un estudiante que deba aislar HLL frente a HLLC en un dominio 1D cartesiano en pocas semanas (coherente con la justificación del plan).

### 3.3 SU2

Economon et al. (2016) presentan SU2 como suite abierta de simulación y diseño, con volúmenes finitos y énfasis en aerodinámica y optimización. Es un código de **producción/investigación de ingeniería**, no un laboratorio pedagógico de Riemann.

### 3.4 Clawpack / PyClaw

Mandli et al. (2016) y la documentación de Clawpack (repositorio `clawpack/riemann`, docs oficiales) establecen que:

- los solvers de Riemann usan una interfaz común;
- en los paquetes Fortran la elección es típicamente en **compilación**;
- en **PyClaw** la elección puede ser en **tiempo de ejecución**;
- existen solvers Python de Euler HLL y HLLC.

Por tanto Clawpack **sí** cubre intercambiabilidad de Riemann y es el contraejemplo más fuerte a un hueco ingenuo. Lo que no cubre, para los fines de este TG, es un núcleo C++ pequeño alineado con un curso de Ingeniería de Sistemas en español, con manual que apunte al `.hpp` ejecutado y una GUI de demostración propia. Esa es una **oportunidad de diseño**, no la inexistencia de Clawpack.

### 3.5 Athena++

Stone et al. (2020) describen Athena++ como marco AMR con solvers MHD. Es software astrofísico de alto rendimiento, no un banco didáctico de Euler 1D.

### 3.6 ANSYS Fluent

Se menciona en el plan como referente industrial. No se inspeccionó su código (es cerrado). Solo se puede afirmar, con Mesnard y Barba (2017) en sentido general sobre CFD, que la reproducibilidad y la auditoría de algoritmos no son el objetivo de un paquete comercial.

### 3.7 Tabla comparativa (criterios del TG)

Leyenda: **S** = sí, con evidencia de literatura o documentación; **P** = parcial o a costa de una curva alta; **N** = no es el objetivo del producto; **—** = no verificado en esta auditoría.

| Criterio (derivado de OE) | OpenFOAM | SU2 | Clawpack/PyClaw | Athena++ | Prototipo de este TG (1D C++) |
|---|---|---|---|---|---|
| Euler compresible FVM | S | S | S | S (y MHD) | S (1D) |
| Intercambiar Riemann sin reescribir el núcleo | P (código grande) | P | S (PyClaw en runtime; Fortran en compile) | P (código experto) | S (namelist `solver`) |
| Laboratorio compacto, pocos archivos | N | N | P (ecosistema amplio) | N | S (objetivo de diseño) |
| Trazar ecuación → archivo fuente en la UI | N | N | P (docs excelentes, no GUI propia UIS) | N | P (prototipo Python) |
| Verificación con Riemann exacto 1D | posible, no el foco | posible | S (hay exacto en riemann Python) | — | S |
| 2D/AMR/industrias | S | S | S | S | PROPOSED / fuera del prototipo |
| Documentación en español para Sistemas UIS | N | N | N | N | PROPOSED (OE4) |

La última columna no implica superioridad: implica **encaje con el TG**.

---

## 4. Ingeniería de software científico

Wilson et al. (2014) recomiendan control de versiones, pruebas, automatización y evitar el «script de un solo uso». Ramakrishnan y Gunter (2017) insisten en usabilidad del software científico. Mesnard y Barba (2017) documentan que, incluso con código y datos públicos, reproducir CFD es difícil: hace falta el *stack*, las opciones y la disciplina de registro.

Oberkampf y Roy (2010) separan **verificación** (¿se resuelven bien las ecuaciones discretas?) de **validación** (¿el modelo representa la física de interés?). Un TG de software numérico puede completar verificación 1D con exacto; la validación experimental de Euler invíscido frente a laboratorio está **fuera** del alcance típico y no debe prometerse.

El patrón Strategy (familia de algoritmos intercambiables) es el mecanismo clásico para solvers (Gamma et al., 1994, citado en el plan). En el núcleo 1D la indirección es por **barrido**, no por celda, decisión de rendimiento ya documentada en el código. No es necesario imponer Factorías JSON si el namelist ya instancia HLL/HLLC.

---

## 5. Síntesis y hueco de investigación

1. Los métodos (FVM, MUSCL, HLL/HLLC, CFL, RK2) están maduros (Toro, 2009; LeVeque, 2002).  
2. El software maduro existe y, en Clawpack, **ya** permite cambiar Riemann.  
3. La reproducibilidad y la ingeniería del código científico siguen siendo problemas abiertos en la práctica (Mesnard y Barba, 2017; Wilson et al., 2014).  
4. **Hueco que el proyecto propone explorar:** un artefacto **compacto**, en C++, para Euler en malla cartesiana, con configuración explícita, pruebas de regresión y —si se mantiene el prototipo de laboratorio— un recorre ecuación–algoritmo–implementación–gráfica, dirigido a formación en Ingeniería de Sistemas, **sin** pretender reemplazar OpenFOAM, SU2 ni Clawpack.

La contribución se formula así: *diseñar, implementar (1D verificado; 2D y WENO/HLLE solo si el director lo confirma) y documentar un marco modular que haga observable el efecto de combinar reconstrucción y flujo numérico sobre problemas de Riemann estándar*. No: *crear el primer código en el que se pueda cambiar HLLC*.

---

## Referencias de este capítulo (claves biblatex)

`leveque2002`, `toro2009`, `hirsch2007`, `liska2003`, `weller1998`, `jasak2009`, `economon2016`, `mandli2016`, `stone2020`, `wilson2014`, `ramakrishnan2017`, `mesnard2017`, `oberkampf2010`.

Documentación Clawpack (no artículo): <https://www.clawpack.org/riemann.html> y <https://www.clawpack.org/dev/pyclaw/rp.html> (consultadas en la auditoría).
