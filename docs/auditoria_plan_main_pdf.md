# Auditoría del plan de tesis (PDF)

**Documento auditado:** `C:\Users\USER\Downloads\main.pdf` (37 páginas).  
**Fecha de lectura:** 9 de octubre de 2026.  
**Alcance de lectura:** texto completo extraído (portada, contenido, justificación/problema, objetivos, marco teórico, metodología, estado del arte, cronograma, presupuesto, bibliografía).  
**Pendiente visual:** figura 3.1 (p. 12); barras pintadas del Gantt (pp. 30–33). Las fórmulas se interpretaron a partir del texto extraído (algunas aparecen mal tipografiadas).  
**Código contrastado:** `Euler1D_Cpp` (inspección de cabeceras, CMake, tests, GUI). **No se ejecutó CTest en esta sesión.** Fortran 1D en este repositorio. Documentos `docs/academico/*`.  
**No se modificó** el PDF, el C++, la GUI ni los datos numéricos.

Claves: **Hecho** = observado en PDF o código. **Interpretación**. **Recomendación** (no aprobada).

---

## 1. Resumen ejecutivo

El plan es un **borrador de radicación maduro en estructura formal** (portada UIS, justificación, objetivos, marco, metodología, SOTA, Gantt 16 semanas, presupuesto, bibliografía APA) y **frágil en coherencia interna**. El planteamiento pedagógico y de ingeniería de software es defendible; el marco funciona más como **manual de métodos** que como estado del arte; la pregunta de investigación y el cronograma **sobrepasan** los objetivos específicos recortados y el software que ya existe.

Nivel de madurez: **plan presentable con correcciones sustanciales de alineación** (pregunta ↔ OE ↔ Gantt ↔ código), no un texto listo para defenderse como tesis terminada. El valor real del proyecto (núcleo 1D verificado + laboratorio Python) está **subutilizado** en la metodología, que aún narra el 1D como trabajo futuro.

No se afirma que el plan sea inválido como TG de Ingeniería de Sistemas. Sí se afirma que, sin recortar alcance o sin implementar 2D/WENO/HLLE/JSON, el documento promete más de lo que el repositorio y los OE pueden sostener.

---

## 2. Síntesis fiel del plan (según el PDF)

| Campo | Texto / contenido real del PDF |
|---|---|
| Título | Framework computacional para la simulación de la dinámica de fluidos mediante el método de volúmenes finitos y esquemas de alta resolución para la captura de choques |
| Problema | Euler como sistema hiperbólico de captura de choques; calidad = combinación reconstrucción–solver–integrador; códigos existentes grandes; reproducibilidad difícil; hace falta framework compacto C++ 1D/2D cartesiano con componentes intercambiables por configuración y verificación integrada |
| Pregunta (p. 5) | Framework C++ Euler 1D y 2D; reconstrucciones constante, MUSCL, WENO; solvers HLLE, HLLC; RK SSP intercambiables por configuración; cuantificar efecto con normas y orden de convergencia; resultados reproducibles |
| Justificación | Banco numérico (HLLC vs HLLE y orden de reconstrucción); didáctica; SOLID/Strategy/Factory, Git, pruebas; extensión futura a otros sistemas o paralelización |
| OG | Diseñar e implementar framework modular con FVM y alta resolución, banco de pruebas y validación, reproducibilidad |
| OE | (1) arquitectura modular; (2) núcleo C++ Euler FVM 1D y 2D con varios reconstructores, Riemann e integradores; (3) validar precisión en casos 1D y 2D; (4) documentación técnica y pedagógica |
| Alcance | 1D+2D, WENO, HLLE, JSON/YAML, GTest o Catch2, VTK, Lax–Liu, Mach; 16 semanas; 780 h/autor |
| Metodología | Investigación aplicada + software; 4 etapas incrementales + prueba de reproducibilidad desde cero |
| Contribución | Artefacto compacto, banco de pruebas y recurso didáctico, no un solver industrial |

---

## 3. Fortalezas (conservar)

1. Distingue necesidad numérica, pedagógica y de software (pp. 4–5), sin vender un método CFD inédito.
2. Reconoce códigos maduros (OpenFOAM, SU2, Clawpack, Athena++, Fluent) y el costo de entrada.
3. Cita Liska y Wendroff (2003) para comparar bajo condiciones idénticas, y Oberkampf y Roy (2010) aunque luego use mal «validación».
4. Página 6 documenta el núcleo 1D ya existente: evita fingir tabula rasa en el planteamiento.
5. OE1–OE4 son típicos de un TG de software científico y se mapean a etapas y al Gantt.
6. El repositorio C++ ya materializa Strategy, namelist estricto, exacto fuera del operador y GUI que no duplica Riemann: más sólido que el marco teórico.

---

## 4. Problemas críticos

### 4.1 Desalineación pregunta / OE / Gantt / código

**Por qué importa:** un evaluador puede exigir WENO, HLLE y 2D porque están en la pregunta y en las semanas 1–10, o rechazar los OE por vagos. El código actual **no** implementa esos tres ítems.

**Corrección posible:** (a) el director recorta la pregunta a HLL/HLLC, MUSCL y 1D (+ 2D opcional), o (b) el equipo compromete un 2D mínimo y deja WENO/HLLE como futuro explícito.

### 4.2 Verificación vs validación

El plan cita Oberkampf y Roy y luego llama «validación» al tubo de Sod contra el exacto (OE3, etapa 3, pilar 6). **Hecho conceptual:** eso es verificación de código/solución. Validación 2D contra literatura es comparación de referencia, no ensayo físico.

**Corrección:** reservar «validación» o aclarar «verificación numérica»; no prometer validación experimental.

### 4.3 El marco afirma implementaciones inexistentes

WENO, HLLE, JSON/YAML, Google Test/Catch2, VTK, «tres solvers implementados» (cuadro 3.1). **Hecho de código:** HLL-Davis, HLLC, namelist, tests caseros, `.xl`.

**Corrección:** tiempo verbal de *propuesta* vs *implementado*; alinear cuadro 3.1 con HLL vs HLLC o marcar HLLE como futuro.

### 4.4 Hueco de investigación sobredeclarado

Pilar 5: Fluent es caja negra (apoyado en Raman 2018, fuente débil); OpenFOAM/SU2 «arquitectura monolítica» y «ninguno concebido como banco de pruebas». **Hecho:** Clawpack/PyClaw sí intercambia Riemann en tiempo de ejecución (Mandli et al., 2016). El SOTA de una página no discute eso.

**Corrección:** hueco = laboratorio compacto, trazable y pedagógico en C++/español para Sistemas, no «no existe software intercambiable».

### 4.5 Viabilidad del Gantt 16 semanas si se toma al pie de la letra

WENO, HLLE, malla 2D, Lax–Liu (hasta 19 configuraciones), Mach, ParaView, documentación y reproducibilidad desde cero, con 1D ya hecho pero etapa 2 reescrita desde malla. 780 h/autor ≈ 49 h/semana. **Interpretación:** o el Gantt es aspiracional o el 1D no está restado.

### 4.6 Fórmulas y ramos de HLLC

Extracción de (3.2): `dt/dU_i` en lugar de `dU_i/dt`. Último ramo de (3.6): `F_R` si `0 ≥ S_L` (debería ser `0 ≥ S_R` en la forma estándar de Toro). `p_obs` (3.10) con paréntesis incompleto en el extracto.

**Por qué importa:** el marco es el capítulo que un jurado de CFD mirará primero.

---

## 5. Mejoras importantes (prioridad)

1. **P1.** Sesión con el director: lista `docs/academico/08_decisiones_director.md`.
2. **P1.** Reescribir pregunta y etapa 2 para partir del 1D existente.
3. **P2.** Convertir el «marco» en fundamentos *más* un estado del arte crítico (el PDF invierte el peso: 15 pp. de manual, 1 p. de SOTA).
4. **P2.** Criterios de aceptación: mallas, normas, umbrales, qué caso 2D es obligatorio.
5. **P2.** Completar bibliografía de autores citados en el texto y no listados.
6. **P3.** Decidir si la GUI es evidencia de OE4; si sí, nombrarla en metodología.
7. **P3.** Unificar C++17/C++20; JSON vs namelist; GTest vs tests actuales.
8. **P3.** No exigir evaluación de usabilidad sin protocolo ético/muestra.
9. **P4.** Limpieza APA (duplicados Jasak, Oberkampf, Ramakrishnan, Toro 2009/2013).
10. **P4.** Plantilla EISI vs `book` (ya señalado al director).

---

## 6. Revisión por secciones (páginas del PDF)

| Sección | pp. | Observación |
|---|---|---|
| Portada / título | 1 | El título cubre FVM y captura de choques; no nombra pedagogía ni modularidad, que son el valor del TG. Aceptable; no obliga a cambiarlo. |
| Contenido | 2–3 | «Marco teorico» sin tilde; «Computación Científicas». |
| Planteamiento | 4–5 | Sólido. Pregunta más específica que los OE (WENO, HLLE). |
| Justificación | 5 | Extensión a paralelización es *futuro*, no OE. |
| Antecedentes 1D | 6 | Conservar. Contradice el tono de la etapa 2. |
| OG | 7 | Redacción defectuosa («alta resolución *de simulaciones*»). Mezcla diseño, banco y validación. |
| OE | 8 | OE2 sobrecargado (1D+2D+varios esquemas). OE3 «validar». Verbos alcanzables si el alcance se recorta. |
| Marco §1 | 9–11 | CFD general (Raman 2018) poco necesario. Euler y Riemann pertinentes. Cita Toro 2013. |
| Marco §2 | 11–14 | FVM pertinente. Fig. 3.1 no inspeccionada visualmente. Afirma que el framework implementa constante/MUSCL/WENO y RK «orden 2 o superior». Código: MUSCL+fo y SSP-RK2 (+ ForwardEuler). |
| Marco §3 | 14–16 | HLL/HLLC bien motivados. HLLE ≠ tercera estructura de ondas. Cuadro 3.1 trata HLLE como implementado. Rama HLLC sospechosa. |
| Marco §4 | 16–19 | SOLID/Strategy coherentes con el código. Factory JSON no existe. C++17 vs C++20. Rendimiento vs Python sin medición propia. |
| Marco §5 | 19–21 | Ecosistema: no menciona que Clawpack ya intercambia solvers. GTest/Catch2, VTK, JSON: no hallados. |
| Marco §6 | 21–23 | Casos 1D pertinentes (el código usa Toro 1–5, no los nombres Lax/123 del texto). 2D propuesto. Normas L1/L2 sí hay clase; convergencia sistemática **no** verificada como producto del plan. |
| Metodología | 24–27 | Tipo de trabajo adecuado. «Revisión sistemática» sin protocolo. Etapa 2 ignora el 1D hecho. Humo Sod: razonable. Reproducibilidad desde cero: buen cierre, ambicioso. No evalúa la GUI. |
| Estado del arte | 28 | Una página; debería ser el capítulo crítico. Wilson, Jasak, Economon, Mandli, Gamma, Mesnard: pertinentes pero insuficientes. |
| Cronograma | 29–34 | Actividades leídas; **sombreado semanal no verificado visualmente**. Etapa 5 de cierre no está en el capítulo de metodología. |
| Presupuesto | 35 | Formal. Horas de autores altas respecto a 16 semanas. |
| Bibliografía | 36–37 | Duplicados; citas huérfanas (Van Leer, WENO, Einfeldt, Lax–Liu, Woodward–Colella, HLL 1983). Raman y Ramachandrappa débiles. |

---

## 7. Matriz de trazabilidad

| Problema / pregunta | OE | Metodología PDF | Componente software | Evidencia de evaluación |
|---|---|---|---|---|
| Intercambiabilidad | OE1 | Etapa 1 interfaces | `RiemannSolver`, `Reconstruction`, `TimeIntegrator` | Diagrama + un solver nuevo sin reescribir el FV. **Parcialmente hecho** |
| Núcleo Euler FVM | OE2 | Etapa 2 | `euler1d_core`, `xEuler1D` | Compilación + casos. **1D sí; 2D/WENO/HLLE no** |
| Cuantificar combinaciones | OE3 | Etapa 3 normas | `error_analyzer`, exacto, tests Toro | L1/L2 vs exacto 1D. **Verificación, no validación física.** 2D sin código |
| Reproducibilidad / enseñanza | OE4 | Etapa 4–5, GUI no nombrada | README, namelist, `fvlab_lab` | Repro desde docs; GUI prototipo. **Sin estudio de usuarios** |
| HLLE vs HLLC (pregunta) | no está en OE | Gantt HLLE | solo HLL-Davis y HLLC | Comparar HLL vs HLLC **sí posible**; HLLE **no** |

---

## 8. Contraste con la implementación

| Elemento del plan | Evidencia en repositorio | Estado | Consecuencia o recomendación |
|---|---|---|---|
| Euler 1D FVM | `finite_volume_operator.hpp`, `euler1d.f90` | Implementado, pendiente de re-ejecutar tests en esta sesión | Conservar; no reescribir |
| MUSCL + limitadores fo/mm/vl/mc/sb | `reconstruction.hpp`, `slope_limiter.hpp` | Implementado | El plan nombra minmod, Van Leer, superbee; falta decir `mc` |
| Reconstrucción WENO | No hay cabecera/clase | No encontrado | Marcar PROPOSED o recortar pregunta |
| HLL | `hll.hpp` Davis | Implementado | No llamarlo HLLE |
| HLLE (Einfeldt) | No hay | No encontrado | Decisión del director |
| HLLC | `hllc.hpp` | Implementado | |
| SSP-RK2 / CFL | `time_integrator.hpp`, `cfl_controller.hpp` | Implementado | ForwardEuler extra, no en el plan |
| BC trans/per/refl | `boundary_condition.hpp` | Implementado | |
| Fuentes g / geometría | `source_term.hpp` | Implementado | El plan apenas las usa como contribución |
| Riemann exacto | `exact_riemann_solver.hpp` | Implementado | Fuera del loop; verificación |
| Namelist sin recompilar | `readConfigFile`, GUI | Implementado | JSON/YAML no es el contrato actual |
| JSON/YAML + Factory | — | No encontrado | No afirmarlo en presente |
| CMake / C++ | C++20, CMake 3.20 | Implementado | Corregir «C++17» del marco |
| GTest/Catch2 | tests propios CTest | No encontrado (equivalente funcional sí) | Decir «suite CTest sin dependencia externa» |
| Casos Toro / Sod | tests 1–5, GUI | Implementado | Mapear nombres Lax/123 a Toro |
| Convergencia p_obs | test 6 entropía en Fortran/C++ | Parcial | No hay matriz reconstructor×solver del plan |
| 2D Lax–Liu / Mach | no en `Euler1D_Cpp` | No encontrado | Alcance a aprobar |
| VTK / ParaView | salida `.xl` | No encontrado | matplotlib en GUI 1D |
| Laboratorio educativo | `tools/fvlab_lab/` | Parcial | Incluir en OE4 o dejarlo como extra |
| OpenMP | flag CMake OFF | Parcial / futuro | No es OE |
| Validación física experimental | — | No encontrado | No prometerla |

---

## 9. Referencias y afirmaciones por verificar

- Citas en el texto **sin** entrada bibliográfica: Van Leer (1979); Liu, Osher y Chan (1994); Harten, Lax y Van Leer (1983); Einfeldt (1988); Toro, Spruce y Speares (1994); Lax y Liu (1998); Woodward y Colella (1984).
- Duplicados: Jasak 2009a/b; Oberkampf 2010 dos veces; Ramakrishnan 2017a/b; Toro 2009 y 2013.
- Mesnard: cuerpo p. 21 dice 2016; biblio 2017.
- Raman et al. (2018), *International Journal of LNCT*: **fuente dudosa** para Fluent y para el alcance de la CFD.
- Ramachandrappa (2024) como apoyo de TDD: **pendiente / débil**.
- «HLLC es el solver de referencia en la mayoría de códigos modernos» (Toro, 2013): formulación demasiado absoluta; **interpretación**.
- OpenFOAM/SU2 «monolíticos» y meses de curva de aprendizaje: **no medido** por este TG.
- Clawpack: afirmaciones de intercambiabilidad **verificadas** en Mandli (2016) y docs Clawpack (auditoría académica previa).
- Wendroff: nombre de pila en `.bib` del ZIP («Barry») vs Burton en SIAM.

---

## 10. Plan de acción priorizado

**Primero (bloquea el TG):** alinear pregunta, OE, cronograma y código con el director; dejar por escrito IMPLEMENTED vs PROPOSED; corregir verificación/validación.

**Puede esperar:** tilde en «teórico», C++17 vs 20, duplicados APA, figura 3.1, umbrales numéricos finos, plantilla EISI.

**No es necesario cambiar:** título general; decisión de no competir con Fluent; C++ como lenguaje del núcleo; FVM+MUSCL+HLL/HLLC+SSP-RK2; exacto como referencia 1D; Git; el laboratorio como prototipo *si* no se vende como ensayo pedagógico; no introducir IA/muones.

---

## 11. Decisiones que deben conservarse

- Tema: framework FVM para Euler, no un código industrial ni otra tesis (muones/IA).
- Autores, director y escuela del PDF.
- Núcleo numérico 1D ya escrito: no reescribir HLLC «por la GUI».
- Exacto fuera del avance.
- Namelist estricto (claves desconocidas = error), salvo que el director imponga JSON.
- GUI no duplica el solver.
- Fortran como oráculo de regresión.
- Contribución como laboratorio compacto y trazable, no como «primer HLLC intercambiable».
- Lista de bloqueos del director en `08_decisiones_director.md` hasta que él falle.
