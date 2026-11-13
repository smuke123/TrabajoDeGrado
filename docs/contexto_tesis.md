# Contexto persistente de la tesis (Euler / volúmenes finitos)

**Instrucción para sesiones futuras.** Este archivo es la base de contexto del trabajo de grado. No cambiar el tema. No introducir modelos generativos, IceCube, muones ni transporte óptimo. No tratar el ejemplo de estilo de otra tesis como el objeto de esta investigación. No modificar algoritmos numéricos C++/Fortran salvo petición explícita.

**Este documento no sustituye el plan PDF.** Distingue: (A) lo que dice el plan radicado, (B) lo verificado en código, (C) recomendaciones de auditoría aún no aprobadas por el estudiante ni por el director.

- Plan de referencia auditado: `C:\Users\USER\Downloads\main.pdf` (37 páginas, 2026).
- Auditoría detallada: `docs/auditoria_plan_main_pdf.md`.
- Núcleo de grado (C++): `C:\Users\USER\OneDrive\Documentos\Tesis\Euler1D_Cpp`.
- Oráculo Fortran 1D: `Code_Euler1D/Code_Euler1D/*.f90` (en este repositorio).
- Capítulos académicos propuestos (no sustituyen el PDF): `docs/academico/`.

---

## A. Decisiones confirmadas (plan + código; no contradecir sin justificación)

### Tema y título vigentes (plan PDF, portada)

*Framework computacional para la simulación de la dinámica de fluidos mediante el método de volúmenes finitos y esquemas de alta resolución para la captura de choques.*

Autores: Gabriel Antonio Chavarro Avellaneda, Edgar Santiago Ariza Garcia. Director: Dr. Jorge Villamizar Morales. Codirectores: Ph.D. Lola Xiomara Bautista Rozo, M.Sc. Oswaldo Alonso Nieto Narváez. UIS, Ingeniería de Sistemas, 2026.

**Propósito (plan + mensaje del estudiante).** Framework C++ modular para Euler compresible por volúmenes finitos, con transparencia algorítmica, modularidad, configurabilidad y reproducibilidad. No es un competidor industrial de OpenFOAM/SU2/Fluent ni, necesariamente, un método numérico nuevo. El valor está en un entorno accesible y pedagógico: aprender → modificar → ejecutar → visualizar → comparar → comprender.

### Problema, justificación y pregunta (como están en el PDF)

- Las ecuaciones de Euler son el prototipo hiperbólico para captura de choques; la calidad depende de la *combinación* reconstrucción–solver–integrador (LeVeque, 2002; Toro, 2009; Liska y Wendroff, 2003).
- Existen códigos maduros (OpenFOAM, SU2, Fluent, Clawpack, Athena++). El plan argumenta curva de aprendizaje y dificultad de aislar un componente, más reproducibilidad (Mesnard y Barba, 2017) e ingeniería del software científico (Wilson et al., 2014; Ramakrishnan y Gunter, 2017).
- Necesidad declarada: framework compacto en C++ moderno, Euler 1D y 2D en mallas cartesianas, selección por configuración sin recompilar, verificación integrada; banco de pruebas y recurso didáctico.
- Pregunta de investigación (p. 5): ¿es posible un framework C++ para Euler 1D y 2D en el que reconstrucciones (constante, MUSCL, WENO), solvers (HLLE, HLLC) e integrador RK SSP sean intercambiables por configuración, y cuantificar el efecto con normas de error y orden de convergencia, con resultados reproducibles?
- Justificación en tres frentes: numérico (compromiso contacto/robustez), pedagógico (trazar discretización), ingeniería de software (SOLID, Strategy, Factory, Git, pruebas).
- Antecedentes propios (p. 6): al radicar ya existe núcleo 1D C++20 validado frente a Fortran (FVM, MUSCL, limitadores, HLL y HLLC, SSP-RK2, CFL). El entregable de grado sigue siendo el framework 1D/2D alineado con la pregunta.

### Objetivos (texto del PDF; no reescribirlos aquí como si ya se hubieran cambiado)

- **OG:** Diseñar e implementar un framework computacional modular mediante los métodos de volúmenes finitos y de alta resolución de simulaciones de dinámica de fluidos, que permita la elaboración de un banco de pruebas y validación de esquemas numéricos y que garantice la reproducibilidad de resultados.
- **OE1:** Arquitectura modular OO, patrones estructurales, desacoplar componentes numéricos por interfaces.
- **OE2:** Núcleo C++ Euler FVM en dominios 1D y 2D estructurados, con distintos esquemas de reconstrucción, solvers de Riemann e integración temporal.
- **OE3:** «Validar» precisión y comportamiento en problemas de referencia 1D y 2D.
- **OE4:** Documentación técnica y pedagógica (desarrollo, extensión, instalación, enseñanza de CFD).

### Alcance explícito del plan

Incluye (según pregunta, marco, metodología y Gantt): Euler 1D/2D cartesiano; reconstrucción constante, MUSCL, WENO; HLLE y HLLC; RK/CFL; JSON/YAML; tests unitarios; casos 1D (Sod, Lax, 123, doble choque) y 2D (Lax–Liu, reflexión de Mach); VTK/ParaView; 16 semanas.

Exclusiones implícitas o débiles: no promete equivalencia industrial; OpenMP se menciona como extensión futura; no hay campaña experimental de laboratorio.

### Fundamentos y decisiones numéricas adoptadas en el *código* (no en el Gantt)

Verificado por inspección de `Euler1D_Cpp` (esta sesión **no** ejecutó la suite CTest):

- Conservación 1D, gas ideal, FVM Godunov.
- MUSCL 2.º orden; primer orden vía limitador `fo`; limitadores `mm`, `vl`, `mc`, `sb`.
- HLL con velocidades de **Davis** (no Einfeldt/HLLE) y HLLC.
- Riemann exacto **fuera** del avance temporal (`exact_riemann_solver.hpp`).
- Integrador SSP-RK2 (Heun); existe `ForwardEuler` para probar la interfaz.
- CFL adaptativo; BC trans/per/refl; fuentes gravedad y geometría cilíndrica/esférica.
- Configuración: namelist `&euler` (`input.par`), no JSON/YAML.
- Salida `.xl`; analizador L1/L2/máximo (`error_analyzer.hpp`).
- Tests propios (sin Google Test/Catch2): physics, numerics, exact Riemann, config, integration, regression vs Fortran.
- Laboratorio Python Tkinter+Matplotlib (`tools/fvlab_lab/`): escribe namelist, lanza `xEuler1D`, lee `.xl`. No reimplementa HLL/HLLC. Prototipo (título de ventana: laboratorio Euler 1D).
- CMake, C++20, OpenMP opcional y desactivado por defecto.

Fortran 1D: mismos métodos; tests Toro 1–5 + onda de entropía, atmósfera, Sedov.

### Arquitectura (código)

Directorios `include/euler1d/`: `mesh`, `reconstruction`, `riemann`, `time`, `boundary`, `config`, `io`, `physics`, `simulation`, `validation`, `source`. Patrón Strategy a granularidad de **barrido**, no de celda. Indirección virtual una vez por etapa.

---

## B. Estado real de implementación (clasificación)

| Ítem | Estado |
|---|---|
| Euler 1D FVM, MUSCL, limitadores, HLL-Davis, HLLC, SSP-RK2, CFL, BC, fuentes, exacto, namelist, `.xl`, CMake, tests, regresión Fortran | Implementado (verificación CTest **no repetida** en esta auditoría) |
| Laboratorio GUI Learn→Modify→Run→See | Parcialmente implementado (prototipo) |
| WENO, HLLE, Euler 2D en el binario C++, JSON/YAML, GTest/Catch2, VTK/ParaView, estudio de usuarios | Propuesto / no encontrado en el núcleo C++ |
| HPC / OpenMP de producción | Preparado, no es el entregable actual |

---

## C. Metodología prevista en el PDF (resumen fiel)

Investigación aplicada con desarrollo de software; cuatro etapas (literatura+arquitectura; implementación incremental 1D/2D incluyendo WENO y HLLE; «validación» 1D+2D; documentación) más cierre de reproducibilidad. Cronograma 16 semanas. Presupuesto total $56.983.600.

---

## D. Referencias principales y verificación

| Fuente | Uso en el plan | Estado |
|---|---|---|
| Toro (2009) | Riemann, HLL/HLLC, FVM | Verificada (monografía estándar); el texto también cita Toro (2013), duplicado de edición |
| LeVeque (2002), Hirsch (2007) | FVM / CFD | Verificadas como obras conocidas; no se releyó el PDF de cada libro aquí |
| Liska y Wendroff (2003) | Comparación de esquemas | Verificada (SIAM J. Sci. Comput.; DOI 10.1137/S1064827502402120). El `.bib` del plan pone «Barry»; el artículo SIAM es Burton Wendroff |
| Mandli et al. (2016) | Clawpack | Verificada (PeerJ CS e68) |
| Economon et al. (2016), Jasak (2009), Weller et al. (1998), Stone et al. (2020) | SU2, OpenFOAM, Athena++ | Títulos coherentes; Jasak aparece duplicado 2009a/2009b |
| Oberkampf y Roy (2010) | V&V | Verificada como monografía; duplicada en la bibliografía del PDF |
| Wilson et al. (2014), Mesnard y Barba (2017), Ramakrishnan y Gunter (2017), Gamma et al. (1994) | Software científico / patrones | Coherentes; Mesnard se cita una vez como 2016 en el cuerpo (p. 21) |
| Raman et al. (2018) | CFD general / Fluent caja negra | Fuente débil (International Journal of LNCT); no basta para afirmar opacidad de Fluent |
| Ramachandrappa (2024) | TDD / SOLID | Pendiente de comprobación de calidad; no respalda TDD del framework |
| Liu–Osher–Chan (1994), Van Leer (1979), Harten–Lax–van Leer (1983), Einfeldt (1988), Toro–Spruce–Speares (1994), Lax–Liu (1998), Woodward–Colella (1984) | Citas en el marco | **No aparecen** en la bibliografía del PDF (pendiente de añadir o de no citar) |
| Bulka y Mayhew (2000) | Rendimiento C++ vs Python | No se verificó el dato cuantitativo «significativamente menores» |

---

## E. Contradicciones detectadas (hechos)

1. Pregunta y Gantt nombran WENO, HLLE, 2D, JSON; los OE recortados no nombran WENO/HLLE; el código tiene HLL-Davis + HLLC, 1D, namelist.
2. El plan usa «validar» para comparación con Riemann exacto (eso es **verificación** según Oberkampf y Roy, que el propio plan cita).
3. El marco afirma que el framework «implementa» WENO, HLLE, JSON, GTest/Catch2, VTK; el código no.
4. C++17 en el marco vs C++20 en antecedentes y en `CMakeLists.txt`.
5. Clawpack *sí* intercambia Riemann (Mandli, 2016); el estado del arte del PDF es breve y no lo desarrolla; el hueco no puede ser «nadie puede cambiar HLLC».
6. Metodología etapa 2 describe el 1D como si partiera de cero; p. 6 admite que el 1D ya existe.

---

## F. Recomendaciones de auditoría (NO aprobadas aún)

Prioridad 1 — alinear pregunta, OE, Gantt y código, o ampliar el código, con fallo del director (`docs/academico/08_decisiones_director.md`).

Prioridad 2 — distinguir verificación / validación; no llamar revisión «sistemática» sin protocolo.

Prioridad 3 — corregir fórmulas (p. ej. (3.2) `dU_i/dt`; último ramo de HLLC; paréntesis de `p_obs`) y bibliografía incompleta o duplicada.

Prioridad 4 — tratar el laboratorio Python como prototipo evaluable **solo si** el director lo incluye en OE4.

No son requisitos obligatorios hasta que el equipo las acepte.

---

## G. Cuestiones pendientes de aprobación (estudiante / director)

Lista vigente en `docs/academico/08_decisiones_director.md`: OE recortados vs largos; HLLE vs HLL-Davis; WENO; 2D mínimo; JSON vs namelist; GUI como contribución; evaluación con usuarios; umbrales L1/L2; nombre metodológico; plantilla EISI.

---

## H. Lo que este archivo no conserva

- El PDF original (sigue en Descargas; no se modificó).
- Memorias ECC CLI (`ecc memory`): no se escribió en el vault en esta sesión.
- Resultados de CTest de esta fecha (no se ejecutaron).
- Sombreado semanal del Gantt (el extractor no recuperó las celdas pintadas).
- La figura 3.1 del PDF (no se interpretó visualmente).
