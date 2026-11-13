# Auditoría académica — Estado del arte y metodología

**Fecha:** 9 de octubre de 2026  
**Fuentes inspeccionadas:** `Degree Proyect.zip` (`main.tex`, `referencias.bib`), `plan_overleaf/`, conversación y código C++/Python del núcleo Euler 1D (no se modificó el solver).  
**Estilo de citas del plan:** APA 7 vía biblatex.

Este documento no es el capítulo de tesis. Es la auditoría (etapa 1) y la trazabilidad que justifican los capítulos revisados.

---

## 1. Estado actual de los capítulos en el plan (`main.tex` del ZIP)

| Capítulo en el plan | Qué es realmente | Diagnóstico |
|---|---|---|
| «Marco teórico» (seis pilares) | Manual de CFD + software + V&V | **No es estado del arte.** Define FVM, HLL, MUSCL, SOLID. Hay fórmulas incorrectas (`dt/dU`). Cita `raman2018review` y `toro2013riemann`, **ausentes** del `referencias.bib` del ZIP. Afirma WENO/HLLE/JSON como si el framework ya los implementara. |
| «Metodología» (cuatro etapas) | Plan de implementación | Confunde **verificación** con **validación física**. Llama «revisión sistemática» a una revisión no protocolizada. El 1D ya existe; el texto habla como si se construyera desde cero. No distingue ciclo de software, V&V numérico ni evaluación educativa. No hay criterios de aceptación ni evidencia retenida. |

La justificación del director (Euler, Clawpack/Athena++, curva de aprendizaje) es más defendible que el marco. Los **objetivos específicos vigentes en el ZIP son los recortados**; la pregunta sigue nombrando WENO, HLLE y RK SSP. Eso **REQUIRES ADVISOR INPUT**.

---

## 2. Clasificación frente al repositorio (núcleo C++ + laboratorio Python)

| Afirmación | Clasificación | Evidencia |
|---|---|---|
| Euler 1D, FVM Godunov, MUSCL, limitadores fo/mm/vl/mc/sb | IMPLEMENTED | `include/euler1d/numerical/reconstruction/` |
| Flujo HLL (velocidades de Davis) y HLLC | IMPLEMENTED | `hll.hpp`, `hllc.hpp` — **no es HLLE** (Einfeldt) |
| Riemann exacto **fuera** del avance temporal | IMPLEMENTED | `exact_riemann_solver.hpp`; ADR documentada |
| SSP-RK2; CFL; BC trans/per/refl; fuentes gravedad/geometría | IMPLEMENTED | núcleo C++ |
| Namelist `&euler`; salida `.xl` | IMPLEMENTED | parser + `OutputManager` |
| Suite de tests y regresión vs Fortran | IMPLEMENTED | `tests/` (el plan no debe reescribir algoritmos) |
| Laboratorio Tkinter + matplotlib (concepto → código → gráfica) | PARTIALLY IMPLEMENTED | `tools/fvlab_lab/`; prototipo, no producto final |
| WENO | PROPOSED | no está en el núcleo C++ 1D |
| HLLE | PROPOSED | el código tiene HLL-Davis |
| Euler 2D en el mismo binario C++ | PROPOSED / UNCONFIRMED | hay Fortran 2D aparte; no se auditó como núcleo único |
| Configuración JSON/YAML | PROPOSED | el contrato actual es namelist |
| Estudio de usuarios / prueba pedagógica formal | PROPOSED | no hay datos; no inventar resultados |
| Equivalencia con Fluent/OpenFOAM en madurez | No aplica | el proyecto **no** debe reclamarla |

---

## 3. Hallazgo de literatura sobre el «hueco» (no asumir el gap)

**VERIFIED (documentación Clawpack + Mandli et al., 2016):** Clawpack concentra solvers de Riemann en un repositorio con interfaz común. En Fortran la selección es en **compilación** (Makefile); en **PyClaw** es en **tiempo de ejecución**. PyClaw documenta `euler_hll_1D` y `euler_hllc_1D`.

Por tanto **no** es cierto que «no exista software abierto donde se intercambie HLL/HLLC». El hueco defendible es más estrecho:

> Los códigos maduros (OpenFOAM, SU2, Clawpack, Athena++) cubren métodos y, en varios casos, intercambiabilidad; su costo de entrada y su desacople entre ecuación, algoritmo, archivo fuente y gráfica no están pensados como laboratorio compacto en español para un curso de Ingeniería de Sistemas. El proyecto **propone explorar** ese laboratorio sobre Euler cartesiano, sin competir en alcance físico ni en rendimiento industrial.

---

## 4. Matriz de trazabilidad (objetivos → evidencia)

| OE (plan vigente, ZIP) | Hallazgo del estado del arte | Hueco | Rasgo del framework | Actividad metodológica | Verificación | Entregable |
|---|---|---|---|---|---|---|
| OE1 arquitectura modular | Wilson (2014); Strategy en el núcleo 1D a granularidad de barrido | Interfaces auditables sin monolito | `Reconstruction`, `RiemannSolver`, `TimeIntegrator`, `Mesh` | Diseño y diagramas; no reescribir kernels | Revisión de contratos; test de un solver nuevo tocando pocos archivos | Diagrama + interfaces |
| OE2 núcleo C++ 1D/2D | Toro (2009); LeVeque (2002) | 2D y WENO/HLLE son metas, no hechos | 1D IMPLEMENTED; 2D PROPOSED | Adaptar/documentar 1D; 2D solo si el director lo confirma | Tests unitarios + Sod; 2D aparte | Binario + casos |
| OE3 «validar precisión» | Oberkampf y Roy (2010); Liska y Wendroff (2003) | Distinguir verificación de validación física | Riemann exacto 1D; casos 2D de literatura | Verificación de código y de solución | L1/L2 vs exacto 1D; 2D vs referencia publicada | Tablas de error |
| OE4 documentación pedagógica | Ramakrishnan y Gunter (2017); Mesnard y Barba (2017) | Trazar ecuación–código–resultado | Manual en GUI + docs | Inspección de requisitos; sin fingir encuesta | Lista de comprobación | Manuales + repo |

---

## 5. Decisiones que requieren al director

1. ¿Los OE recortados o los OE largos (WENO, HLLE, L1/L2 explícitas) son los de radicación?  
2. ¿HLLE es obligatorio o basta HLL-Davis + HLLC (lo implementado)?  
3. ¿WENO entra en el TG o es trabajo futuro?  
4. ¿2D (Lax–Liu / Mach) es entregable o solo 1D + un caso 2D mínimo?  
5. ¿Configuración JSON/YAML o se acepta namelist como contrato?  
6. ¿Habrá evaluación con usuarios o solo inspección de requisitos?  
7. ¿El laboratorio Python es contribución del TG o solo demostración?

---

## 6. Plan de acción (prioridad)

1. Reescribir estado del arte como análisis crítico (no manual).  
2. Reescribir metodología: investigación aplicada + ciclo de artefacto + V&V + límites educativos.  
3. Bibliografía: solo claves verificadas del ZIP + Toro (2009) para HLL/HLLC; no citar `raman2018review` ni `toro2013riemann` hasta que existan en el `.bib`.  
4. Matrices comparativa, literatura, fases, V&V.  
5. No tocar algoritmos numéricos.
