# Metodología de investigación y de desarrollo del artefacto

**Versión para revisión del director.** Distingue cuatro capas que el plan original mezclaba: (1) tipo de investigación, (2) ciclo de desarrollo de software, (3) verificación y validación numéricas, (4) evaluación educativa.

---

## A. Enfoque y tipo de investigación

El trabajo es **investigación aplicada con desarrollo de un artefacto de software científico**: el producto principal no es un teorema nuevo de Riemann, sino un sistema ejecutable, documentado y reproducible cuya calidad se juzga por (a) corrección numérica respecto de referencias acordadas y (b) modularidad y transparencia algorítmica (objetivos del plan).

No se etiqueta el estudio como «experimental» en el sentido de ensayo clínico ni como «métodos mixtos»: no hay encuesta ni medición de aprendizaje **hasta que el director las apruebe**. Tampoco se declara Design Science Research en sentido estricto (ciclo Hevner completo, evaluación en organización): solo se toma de esa familia la idea de **artefacto + criterios de evaluación explícitos**. Si el Comité exige otro nombre, el contenido de las fases no cambia.

**Unidad de análisis:** el *framework* (núcleo C++ +, en el prototipo, el laboratorio Python), no el usuario final.

**Evidencia de cumplimiento de objetivos:**

| Objetivo | Evidencia (no promocional) |
|---|---|
| OE1 | Diagramas e interfaces; un componente nuevo (p. ej. un limitador) no exige reescribir el operador FV |
| OE2 | Código y binario; 1D ya existe; 2D solo si entra en alcance aprobado |
| OE3 | Tablas L1/L2 y/o perfiles vs Riemann exacto en 1D; 2D vs literatura **si** hay caso 2D |
| OE4 | Manuales y repositorio con el que un tercero reproduce un caso documentado |

**Limitaciones del diseño:** un solo equipo, un semestre lectivo de TG, Euler invíscido, malla cartesiana. No hay validación experimental de túnel de viento. El laboratorio gráfico es prototipo.

---

## B. Ciclo de desarrollo (iterativo, con trazabilidad)

El ciclo es **incremental y verificado**: cada módulo se prueba antes de integrarse. Las iteraciones no autorizan cambiar la fórmula de HLLC «porque la GUI lo pide».

Las fases siguientes **ajustan** las cuatro etapas del plan a lo que el repositorio ya contiene.

### Fase 0 — Inventario y alcance (entrada real)

- **Objetivo:** fijar qué está IMPLEMENTED / PROPOSED.  
- **Actividades:** auditoría de código (este expediente).  
- **Entrada:** repositorio C++, Fortran de referencia, plan.  
- **Criterio:** lista firmada por los autores (y, si es posible, el director).  
- **OE:** todos (precondición).

### Fase 1 — Revisión de literatura y requisitos

- **Objetivo:** estado del arte crítico y lista de requisitos.  
- **No** se llama sistemática salvo que se publique el protocolo.  
- **Técnicas:** lectura de Toro (2009), LeVeque (2002), Oberkampf y Roy (2010), Mandli et al. (2016), documentación Clawpack.  
- **Entregable:** capítulo de estado del arte + matriz de requisitos.  
- **OE1, OE4.**

### Fase 2 — Arquitectura

- **Objetivo:** contratos `Mesh`, `Reconstruction`, `RiemannSolver`, `TimeIntegrator`, E/S.  
- **Hecho parcial:** el 1D C++ ya separa esos roles.  
- **Criterio:** un diagrama que coincida con los directorios `include/euler1d/`.  
- **OE1.**

### Fase 3 — Núcleo numérico

- **Objetivo:** algoritmos fieles al Fortran/Toro según invariantes del proyecto.  
- **1D:** IMPLEMENTED; esta fase es **mantenimiento, extensión controlada y documentación**, no reescritura.  
- **2D, WENO, HLLE:** PROPOSED; no se dan por hechas.  
- **Herramientas:** C++20, CMake, tests existentes.  
- **Criterio:** la suite de regresión del 1D sigue en verde si se toca el núcleo.  
- **OE2.**

### Fase 4 — Configuración, interfaz y visualización

- **Objetivo:** experimentación sin recompilar el núcleo.  
- **Contrato actual:** namelist `&euler` + `.xl` + proceso `xEuler1D`. JSON/YAML es PROPOSED.  
- **GUI:** prototipo Tkinter; no contiene flujos de Riemann.  
- **Criterio:** un caso Toro 1 se lanza desde GUI o CLI y produce las mismas curvas.  
- **OE2, OE4.**

### Fase 5 — Verificación, regresión y análisis de referencia

Véase sección E. **OE3.**

### Fase 6 — Evaluación educativa (si el alcance lo incluye)

Véase sección F. **OE4.**

### Fase 7 — Documentación, análisis e informe

Manual técnico, manual de usuario, memoria. Prueba de reproducibilidad: instalar y correr **solo** con el README. **OE4.**

**Dependencias:** 0→1→2; 3 puede solaparse con 2 en el 1D ya escrito; 4 depende de 3; 5 depende de 3–4; 6 de 4–5; 7 al final con solape.

---

## C. Ingeniería de requisitos

**Elicitación:** documentos del director, Fortran de referencia, objetivos del plan, inspección del código.  
**Prioridad (MoSCoW provisional, sujeta a aprobación):**

| ID | Requisito | Tipo | Prioridad | Estado |
|---|---|---|---|---|
| RN-01 | Euler 1D FVM Godunov | numérico | Must | IMPLEMENTED |
| RN-02 | MUSCL y limitadores | numérico | Must | IMPLEMENTED |
| RN-03 | HLL y HLLC seleccionables | numérico / config | Must | IMPLEMENTED |
| RN-04 | HLLE | numérico | Should / Could | PROPOSED |
| RN-05 | WENO | numérico | Could | PROPOSED |
| RN-06 | SSP-RK2 y CFL | numérico | Must | IMPLEMENTED |
| RN-07 | Riemann exacto como referencia 1D | verificación | Must | IMPLEMENTED |
| RN-08 | Namelist o equivalente sin recompilar | config | Must | IMPLEMENTED (namelist) |
| RN-09 | JSON/YAML | config | Could | PROPOSED |
| RN-10 | GUI laboratorio | usabilidad | Should (prototipo) | PARTIAL |
| RN-11 | Trazar método → archivo fuente | transparencia | Should | PARTIAL (catálogo Python) |
| RN-12 | Tests automáticos | testabilidad | Must | IMPLEMENTED (1D) |
| RN-13 | Documentación de instalación | documentación | Must | PARTIAL |
| RN-14 | Euler 2D | numérico | Should | PROPOSED |
| RN-15 | Paralelismo / GPU | rendimiento | Won't (TG) | fuera |

Umbrales numéricos (L1 máximo, orden observado) se etiquetan **provisionales** hasta que el director fije los casos y las mallas. Candidato: en Toro 1, N=400, HLLC+vl, el perfil debe coincidir con la regresión ya aceptada frente a Fortran; no se inventa un ε nuevo aquí.

---

## D. Arquitectura (según el código, no un libro de patrones)

Separación observada en el núcleo 1D:

- física y estado (`IdealGas`, primitivas/conservadas);
- malla y fantasmas;
- reconstrucción MUSCL (limitadores como tipos-política);
- Riemann HLL/HLLC (clases, despacho por barrido);
- operador FV, CFL, RK2;
- fronteras y fuentes;
- Riemann exacto **fuera** del operador;
- E/S `.xl` y CLI;
- GUI Python **fuera** del bucle numérico.

Eso permite probar `hllcFlux` sin Tkinter y pintar sin reimplementar HLLC. La GUI no debe duplicar el solver: requisito de integridad científica.

---

## E. Verificación y validación numéricas

Definiciones (Oberkampf y Roy, 2010):

| Término | Pregunta | En este TG |
|---|---|---|
| Verificación de código | ¿El programa hace el algoritmo declarado? | Tests unitarios, comparación con Fortran, Riemann exacto 1D |
| Verificación de solución | ¿Cómo depende el error de $\Delta x$? | Refino de malla en onda suave (test de entropía); en choques el orden global cae |
| Validación | ¿El modelo Euler representa un experimento? | **No prevista** (sin datos de laboratorio) |
| Regresión | ¿Un cambio rompió un caso ya aceptado? | Suite existente; no alterar expectativas sin justificación |
| Prueba de software | ¿CLI/GUI/config rechazan lo inválido? | Namelist estricto; tests del laboratorio |

**No** se llama validación física al tubo de Sod.

Plan de pruebas (solo casos aplicables):

| ID | Prueba | Propósito | Método | Criterio (provisional) | Estado |
|---|---|---|---|---|---|
| T-U1 | Limitador / HLL / HLLC unitario | Verificar código | Valores analíticos puntuales | Igualdad bit-a-bit o tol. ya usada en `tests/` | IMPLEMENTED |
| T-I1 | Toro 1–5 vs exacto | Verificar solución 1D | L1/L2, perfiles | Dentro de la banda de la regresión Fortran | IMPLEMENTED |
| T-I2 | Test 123 (vacío) | Positividad | $\rho,p>0$ | Sin NaN; pisos instrumentados | IMPLEMENTED |
| T-C | Entropía suave, refino | Orden | $p_{obs}$ | Cercano a 2 en zona suave con MUSCL; no exigir 2 en el choque | parcial / a reportar |
| T-R | Regresión `.xl` | No regresiones | diff vs `tests/reference` | Identidad de formato acordado | IMPLEMENTED |
| T-G | GUI → mismo namelist | Integración | Toro 1 desde laboratorio | Cód. retorno 0; curvas leídas | PARTIAL |
| T-2D | Lax–Liu / Mach | Verificación 2D | vs literatura | Solo si hay núcleo 2D | PROPOSED |
| T-F | Config inválida | Robustez | clave namelist desconocida | Abortar, no silenciar | IMPLEMENTED |

Sutilezas: contactos (HLL vs HLLC), pisos de densidad/presión, geometría radial (divergencia conservativa, no $-(α/r)F$), fronteras. El exacto no aplica con gravedad ni Sedov.

---

## F. Objetivos educativos y de software

Dimensiones (si OE4 se mantiene): localizar la ficha de un método; ver el `.hpp` real; configurar y ejecutar; leer ρ, u, p y el error; repetir un caso del README.

**Método proporcionado a un TG:** inspección por lista de comprobación (autores + director), no una encuesta ficticia. Un estudio de usuarios queda como **Could**, requiere ética y muestra; **no se reportan resultados inventados**.

Si no hay usuarios: la limitación se declara y la evidencia es el cumplimiento de RN-10–RN-13.

---

## G. Riesgos, límites y ética

| Riesgo | Mitigación |
|---|---|
| Alcance (WENO/2D/HLLE) mayor que el calendario | Decisión explícita del director; recortar a Must |
| GUI que no lanza el mismo núcleo | Un solo ejecutable; prohibido reimplementar HLLC en Python |
| Afirmar validación física | Vocabulario de Oberkampf y Roy (2010) |
| Reproducibilidad | Git, namelist, tests, README |
| Dependencia MSYS2 en Windows | Documentar PATH UCRT |
| Datos personales | No hay; software de investigación; licencia a declarar |

**Ética:** no hay sujetos humanos en el diseño actual. El código de terceros (matplotlib, compilador) se usa según sus licencias.

**Trabajo futuro (no se finge hecho):** 2D completo, WENO, HLLE, JSON, MPI/GPU, estudio de aula.
