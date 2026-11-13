# Guía de decisiones de arquitectura — reunión de avance

**Fecha de la reunión:** 13 de noviembre de 2026
**Director:** Dr. Jorge Villamizar Morales
**Codirectores:** Ph.D. Lola Xiomara Bautista Rozo · M.Sc. Oswaldo Alonso Nieto Narváez
**Autores:** Gabriel Antonio Chavarro Avellaneda · Edgar Santiago Ariza Garcia
**Programa:** Ingeniería de Sistemas, UIS

**Documento de respaldo** de `presentacion_avance.tex`. Todo lo que aparece aquí
está verificado por inspección directa del código o por ejecución en la máquina
de desarrollo el 12 de noviembre de 2026. Las cifras llevan su procedencia.

---

## Convención de estados usada en todo el documento

| Marca | Significado |
|---|---|
| **IMPLEMENTADO** | Existe en el código, compila y está cubierto por la suite |
| **PARCIAL** | Existe pero no con la forma que exige el objetivo |
| **PENDIENTE** | No existe en el núcleo C++ |
| **DECIDIDO** | Decisión registrada en `decision_log.md` como `Aceptada` |
| **RECOMENDACIÓN** | Propuesta de los autores, aún no aprobada |
| **PENDIENTE DEL DIRECTOR** | Requiere su criterio o su material |

Esta separación es deliberada: el riesgo principal de una reunión de avance es
que una recomendación nuestra se registre en el acta como decisión suya, o al
contrario.

---

## Aviso previo sobre la ubicación del código

El núcleo de grado en C++ **no vive en este repositorio**. Está en el repositorio
hermano:

```
C:\Users\USER\OneDrive\Documentos\Tesis\Euler1D_Cpp
   remoto: github.com/smuke123/Explicacion-de-Code_Euler1
```

Este repositorio (`Code_Euler1D`) contiene el **oráculo Fortran** de regresión
(`Code_Euler1D/*.f90`), la documentación académica (`docs/`) y el plan en LaTeX
(`plan_overleaf/`). Es útil decirlo al abrir la reunión para que nadie busque el
framework donde no está.

Dos hallazgos de higiene de repositorio que conviene mencionar:

1. El prototipo de laboratorio (`tools/fvlab_lab/`), los lanzadores
   `run_lab.ps1` / `run_lab.bat` y `docs/mvp_plan.md` **están sin commitear** en
   `Euler1D_Cpp`. Si el portátil falla hoy, ese trabajo no está respaldado.
2. El nombre del repositorio remoto (`Explicacion-de-Code_Euler1`) no describe el
   entregable. `ADR-001` propone renombrar a **FVLab** (*Finite Volume
   Laboratory*) con namespace `fvlab`, y está `Propuesta` desde el 27 de
   septiembre.

---

# Bloque 1 · Radiografía del estado actual

## 1.1 Resumen en cifras

| Métrica | Valor | Procedencia |
|---|---|---|
| Cabeceras públicas | 24 `.hpp` en `include/euler1d/` | conteo de archivos |
| Unidades de implementación | 17 `.cpp` (15 en la biblioteca + 2 ejecutables) | `CMakeLists.txt` |
| Líneas de C++ | ≈ 4 010 (1 117 cabeceras · 1 571 implementación · 1 324 tests) | conteo de líneas |
| Casos de prueba | **87** en 6 ejecutables bajo CTest | ejecución |
| Resultado de CTest hoy | **6/6 Passed · 0 fallos · 9,57 s** (Release, GCC UCRT64) | ejecución 12-nov-2026 |
| Regresión contra Fortran | **26/26** configuraciones en tolerancia, pasos temporales idénticos | `docs/validation_results.csv` |
| Coincidencia byte a byte | 9 de 13 corridas archivadas | `docs/validation.md` |
| Advertencias de compilación | 0 con `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wsign-conversion` | ejecución |
| Dependencias externas obligatorias | **ninguna** | `ADR-010` |

El punto de partida fue `euler1d.f90`: **555 líneas, 13 subrutinas internas**
compartiendo por visibilidad léxica los arrays `U`, `U1`, `U2`, `W`, `Fnum`, `x`
y todo el módulo global `global_numbers`.

## 1.2 Inventario real: interfaces y sus implementaciones

Las cinco interfaces con alternativas, con el archivo exacto donde vive cada una.

| Interfaz (archivo) | Implementaciones existentes | Estado | Falta |
|---|---|---|---|
| `Reconstruction` (`numerical/reconstruction/reconstruction.hpp`) | `MusclReconstruction` | **PARCIAL** | `FirstOrderReconstruction` como clase propia; `WenoReconstruction` |
| `RiemannSolver` (`numerical/riemann/riemann_solver.hpp`) | `HllRiemannSolver` (`hll.hpp`), `HllcRiemannSolver` (`hllc.hpp`) | **IMPLEMENTADO** | `HlleRiemannSolver` |
| `TimeIntegrator` (`numerical/time/time_integrator.hpp`) | `SspRk2` (Heun), `ForwardEuler` | **IMPLEMENTADO** | SSP-RK3 si se exige orden 3 |
| `BoundaryCondition` (`boundary/boundary_condition.hpp`) | `TransmissiveBoundary`, `PeriodicBoundary`, `ReflectiveBoundary` | **IMPLEMENTADO** | versión 2D por borde |
| `DivergenceOperator` (`numerical/source/source_term.hpp`) | `CartesianDivergence`, `RadialDivergence` | **IMPLEMENTADO** | versión 2D sin separación |
| `SourceTerm` (mismo archivo) | `GravitySource` | **IMPLEMENTADO** | — (fuera de alcance) |

**Matiz que hay que decir en voz alta:** el orden 1 funciona hoy como una
*opción de limitador* (`LimiterKind::FirstOrder` → pendiente nula), no como
módulo independiente. El resultado numérico es correcto y está probado
(`primer_orden_anula_la_pendiente`, `primer_orden_da_estados_de_cara_constantes_por_celda`),
pero el OE2 pide «módulos concretos para al menos dos reconstructores».
Extraerlo es trabajo de horas y deja preparado el hueco donde entra WENO.

### Limitadores de pendiente — `numerical/reconstruction/slope_limiter.hpp`

Cinco, como tipos-política sin estado con método estático `slope(a, b)`:
`FirstOrder` (`fo`), `MinMod` (`mm`), `VanLeer` (`vl`), `MonotonizedCentral`
(`mc`), `Superbee` (`sb`). Incluyen `fortranSign()`, que replica
`sign(1.0d0, x) = +1` cuando `x = 0`, porque eso decide si la pendiente se anula
en minmod y superbee.

### Componentes de soporte

| Componente | Archivo | Responsabilidad |
|---|---|---|
| `SimulationConfig`, `ConfigError` | `config/simulation_config.hpp` | Configuración validada, sin estado global |
| parser de namelist | `src/config/namelist_parser.cpp` (243 líneas) | Lee `&euler ... /`; clave desconocida = error |
| `TestCaseDefinition`, `resolveTestCase` | `initial/test_case.hpp` | Los 8 casos como dato declarativo |
| `Mesh1D` | `mesh/mesh1d.hpp` | Centros, caras, `dx` |
| `CellField<T>`, `kGhostCells = 2` | `physics/field.hpp` | Almacenamiento AoS, índices `-1 … N+2` |
| `IdealGas` | `physics/ideal_gas.hpp` | EOS, conversiones, sonido, flujo físico, pisos |
| `CflController` | `numerical/cfl_controller.hpp` | `dt` adaptativo; detecta NaN por checksum |
| `SemiDiscreteOperator` | `numerical/semi_discrete_operator.hpp` | Contrato `u_out = u_in + dt·L(u_in)` |
| `FiniteVolumeOperator` | `numerical/finite_volume_operator.hpp` | Compone los cinco pasos; cero asignaciones en el ciclo |
| `ExactRiemannSolver`, `StarState` | `numerical/riemann/exact_riemann_solver.hpp` | Riemann **exacto** (Toro cap. 4) |
| `ErrorMetrics`, `compareFields` | `validation/error_analyzer.hpp` | `max|d|`, `L1`, `L2`, `rel_max` |
| `OutputManager` | `io/output_manager.hpp` | `.xl` idéntico al Fortran + `run_info.txt` |
| `Simulation`, `SimulationReport` | `simulation/simulation.hpp` | Orquestación; «Facade» |

## 1.3 Arquitectura implementada hoy

```
                             main.cpp
                                │  (-i namelist, -o dir, -q, --help)
                                ▼
                     ┌─────────────────────┐
                     │     Simulation      │   «Facade»: compone y controla
                     │  no hay fórmulas    │   el ciclo; no calcula nada
                     └──┬────┬────┬────┬───┘
                        │    │    │    │
     ┌──────────────────┘    │    │    └──────────────┐
     ▼                       ▼    ▼                   ▼
┌───────────┐      ┌──────────────┐  ┌──────────┐  ┌──────────────────┐
│CflController│    │TimeIntegrator│  │ Output   │  │ExactRiemannSolver│
│ dt por CFL │    │ SspRk2 |     │  │ Manager  │  │ referencia; NO    │
│            │    │ ForwardEuler │  │  .xl     │  │ avanza el fluido  │
└───────────┘      └──────┬───────┘  └──────────┘  └──────────────────┘
                          │ aplica
                   ┌──────▼─────────────────┐
                   │ SemiDiscreteOperator   │  «interfaz»
                   │ u_out = u_in + dt·L(u) │
                   └──────┬─────────────────┘
                          │
                   ┌──────▼─────────────────┐
                   │ FiniteVolumeOperator   │  ← único punto que conoce
                   └─┬────┬────┬────┬────┬──┘    las cinco interfaces
                     │    │    │    │    │
   ┌─────────────────┘    │    │    │    └──────────────────┐
   ▼                      ▼    ▼    ▼                       ▼
┌────────────┐ ┌──────────────┐ ┌───────────┐ ┌──────────┐ ┌────────────┐
│Reconstruc- │ │ RiemannSolver│ │Divergence │ │SourceTerm│ │ Boundary   │
│tion        │ │              │ │Operator   │ │          │ │ Condition  │
│«interfaz»  │ │ «interfaz»   │ │«interfaz» │ │«interfaz»│ │ «interfaz» │
├────────────┤ ├──────────────┤ ├───────────┤ ├──────────┤ ├────────────┤
│Muscl<Lim>✅ │ │ Hll  (Davis)✅│ │Cartesian ✅│ │Gravity ✅ │ │Transmissive✅│
│FirstOrder ⚠ │ │ Hllc        ✅│ │Radial    ✅│ │          │ │Periodic   ✅│
│Weno       ⬚ │ │ Hlle        ⬚│ │Unsplit2D ⬚│ │          │ │Reflective ✅│
└────────────┘ └──────────────┘ └───────────┘ └──────────┘ └────────────┘

✅ implementado y probado   ⚠ existe pero no como módulo   ⬚ pendiente

Soporte, sin dependencias salientes:
  PrimitiveState / ConservedState / FluxVector   (physics/state.hpp)
  CellField<T>  con 2 celdas fantasma por lado   (physics/field.hpp)
  Mesh1D · IdealGas · SimulationConfig
```

**La frase que resume el diagrama:** hay exactamente cinco interfaces con
implementaciones alternativas y **todas** se invocan desde un solo componente,
`FiniteVolumeOperator`. Esa concentración es lo que hace que añadir un esquema no
toque el núcleo, y es la afirmación que el OE1 tiene que demostrar con un número.

### Lo que el diseño hace y conviene defender

**Strategy con granularidad de barrido, no de celda.** El método virtual procesa
un barrido completo:

```cpp
virtual void computeFluxes(const std::vector<PrimitiveState>& q_left,
                           const std::vector<PrimitiveState>& q_right,
                           std::vector<FluxVector>& out) const = 0;
```

Resultado: una llamada virtual por etapa de Runge-Kutta —unas 5 por paso
temporal— en lugar de una por celda y componente. Dentro, el bucle es plano y
vectorizable. Cada solver expone **además** `flux(qL, qR)` para una sola cara,
que es lo que usan los tests y lo que hace la fórmula legible y comparable con
el texto de Toro; un test comprueba que ambos caminos coinciden
(`el_barrido_por_lotes_coincide_con_la_cara_individual`).

**El contrato implícito del Fortran se hizo explícito.** `rhs_fv(Uin, Uout)`
recibía `Uin` como argumento pero **reconstruía leyendo el array global `W`**.
Pasarle un `Uin` no sincronizado con `W` evaluaba el operador espacial en un
estado distinto del pedido, sin aviso. En C++ `w` es un parámetro de
`applyUpdate`, así que la obligación está en la firma.

**Se corrigió un aliasing ilegal.** El Fortran llamaba `rhs_fv(U1, U1)`: el mismo
array como `intent(in)` e `intent(out)`, comportamiento indefinido. `SspRk2` usa
dos destinos separados (`stage1_`, `stage2_`).

**La geometría es divergencia, no fuente.** `RadialDivergence` usa áreas
`A = r^α` y volumen exacto `V = (r₊^{α+1} − r₋^{α+1})/(α+1)`, más el término
geométrico de presión `p(A₊−A₋)/V`. La forma alternativa `−(α/r)F` **no
conserva**: según la auditoría del Fortran, el arranque del Sedov inyectaba un
**42 % de energía espuria**.

## 1.4 Cómo se compila y se ejecuta hoy

```powershell
# Windows + MSYS2 UCRT64
$env:PATH = "C:\msys64\ucrt64\bin;" + $env:PATH
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build --output-on-failure
```

CMake 3.20+, **C++20** (ver decisión rápida R-1), Ninja como generador. Dos
opciones: `EULER1D_BUILD_TESTS` (ON) y `EULER1D_ENABLE_OPENMP` (OFF, preparado
pero desactivado a propósito).

**Prohibido `-ffast-math` y `-Ofast`** (`ADR-003`): reasociarían las operaciones
en coma flotante y romperían la equivalencia byte a byte con el Fortran, que es
el criterio de aceptación central.

Dos ejecutables: `xEuler1D` (el solver) y `euler1d_compare` (comparador
cuantitativo de dos corridas, el que produce `docs/validation.md`).

### Configuración: namelist `&euler`, no JSON

```fortran
&euler
 test = 1
 N = 400
 cfl = 0.9
 gamma = 1.4
 limiter = 'vl'
 solver = 'hllc'
/
```

Claves: `test` (1–8), `N`, `cfl`, `gamma`, `limiter`, `solver`, `bc`, `grav`,
`alpha_geo`, `xmin`, `xmax`, `x0`, `tf`, `every_out`, `rho_floor`, `p_floor`.
Una clave desconocida o un valor fuera de rango **abortan con error explícito**.
Ninguna opción inválida selecciona otro algoritmo en silencio, que era el fallo
concreto del original que motivó esta parte del diseño.

### Los ocho casos de prueba — `initial/test_case.hpp`

| `test` | Problema | `x0` | `tf` | Impone |
|---|---|---|---|---|
| 1 | Sod modificado, rarefacción sónica (Toro 4.1) | 0.3 | 0.2 | — |
| 2 | «123»: dos rarefacciones, casi vacío | 0.5 | 0.15 | — |
| 3 | Blast izquierdo (Woodward–Colella) | 0.5 | 0.012 | — |
| 4 | Colisión de dos choques | 0.4 | 0.035 | — |
| 5 | Test 3 desplazado: contacto casi estacionario | 0.8 | 0.012 | — |
| 6 | Onda de entropía suave (convergencia) | — | 1.0 | `bc='per'` |
| 7 | Atmósfera hidrostática isoterma | — | 10.0 | `bc='refl'`, `grav=1` |
| 8 | Sedov–Taylor esférico | — | 0.5 | `bc='refl'`, `alpha_geo=2`, `xmax=1.2` |

Cuando un test sobreescribe una opción que el usuario fijó explícitamente, **se
avisa por pantalla**; el Fortran lo hacía en silencio.

### Salida y visualización

`rho_1.xl`, `vel_1.xl`, `press_1.xl` (numérica), `rho_exact.xl`, `vel_exact.xl`,
`press_exact.xl` (referencia) y `run_info.txt` (configuración efectiva, pasos,
tiempo de pared, `p*`/`u*` exactos, residuo del Newton y contadores de pisos).
Los `.xl` se abren en modo binario y terminan línea con LF para ser **idénticos
byte a byte** a los del Fortran en Linux.

Visualización hoy: matplotlib desde `tools/`, y el prototipo de laboratorio.
**No hay VTK ni ParaView todavía.**

## 1.5 La suite de pruebas

Arnés propio en `tests/test_support.hpp` (110 líneas), sin dependencias externas.
Cada archivo es un ejecutable y se registra en CTest.

| Ejecutable | Casos | Qué cubre |
|---|---|---|
| `test_physics` | 15 | EOS involutiva, sonido, flujo físico, pisos en el orden del Fortran, malla, índices fantasma, CFL, NaN como error |
| `test_numerics` | 21 | los cinco limitadores, reconstrucción exacta de rampa lineal, HLL/HLLC consistentes, contacto estacionario, barrido vs cara, cotas de Davis, las tres fronteras, pared con gravedad |
| `test_exact_riemann` | 12 | valores estrella publicados de Toro, muestreo autosimilar, vacío |
| `test_config` | 25 | parser estricto, rangos, sobreescrituras del test, errores |
| `test_integration` | 12 | simulaciones completas extremo a extremo |
| `test_regression` | 2 | contra las salidas `.xl` archivadas del Fortran |
| **Total** | **87** | |

**Ejecución de hoy, 12 de noviembre de 2026** (Release, GCC UCRT64, build limpio
en `build-reunion/`):

```
1/6 test_physics ........... Passed  0.04 s
2/6 test_numerics .......... Passed  0.03 s
3/6 test_exact_riemann ..... Passed  0.03 s
4/6 test_config ............ Passed  0.04 s
5/6 test_integration ....... Passed  0.32 s
6/6 test_regression ........ Passed  9.08 s

100% tests passed, 0 tests failed out of 6
Total Test time (real) = 9.57 sec
```

**Salvaguarda de no circularidad** (`ADR-013`): `tests/reference/` contiene
**exclusivamente** salidas del Fortran. Las líneas base producidas por el C++ van
en `tests/baseline/` y nunca se llaman «referencia». El fallo que esto previene
—regenerar «la referencia» con el código que se quería validar— es silencioso e
invalidaría toda la estrategia de validación.

## 1.6 Resultados preliminares medidos

### (a) Equivalencia con el Fortran

De `docs/validation_results.csv`: **26 de 26** configuraciones con el número de
pasos temporales **idéntico** y el peor error normalizado ≤ 1 × 10⁻¹¹.

Corrida en vivo de hoy, caso 1 (Sod modificado, N = 400, HLLC + van Leer), contra
la salida archivada del Fortran:

```
pasos: 245    t final: 0.200000
exacto: p* = 4.662936E-01    u* = 1.360906E+00

rho_1.xl        max|d| = 0.000e+00   L1 = 0.000e+00   L2 = 0.000e+00   OK
vel_1.xl        max|d| = 0.000e+00   L1 = 0.000e+00   L2 = 0.000e+00   OK
press_1.xl      max|d| = 0.000e+00   L1 = 0.000e+00   L2 = 0.000e+00   OK
rho_exact.xl    max|d| = 0.000e+00   L1 = 0.000e+00   L2 = 0.000e+00   OK
vel_exact.xl    max|d| = 0.000e+00   L1 = 0.000e+00   L2 = 0.000e+00   OK
press_exact.xl  max|d| = 0.000e+00   L1 = 0.000e+00   L2 = 0.000e+00   OK

resultado: TODAS LAS METRICAS DENTRO DE TOLERANCIA
```

Cero, no «pequeño»: coincidencia byte a byte en las seis variables.

### (b) Orden de convergencia observado

Caso 6 (onda de entropía suave), MUSCL + van Leer + HLLC, CFL 0.9, cinco
resoluciones. Normas sobre la densidad frente al perfil de referencia:

| N | L₁ | p_obs(L₁) | L₂ | p_obs(L₂) |
|---|---|---|---|---|
| 50 | 3.1197 × 10⁻³ | — | 3.7179 × 10⁻³ | — |
| 100 | 8.3188 × 10⁻⁴ | 1.907 | 1.1137 × 10⁻³ | 1.739 |
| 200 | 2.0866 × 10⁻⁴ | 1.995 | 3.3030 × 10⁻⁴ | 1.754 |
| 400 | 5.2186 × 10⁻⁵ | 1.999 | 9.8093 × 10⁻⁵ | 1.752 |
| 800 | 1.2904 × 10⁻⁵ | 2.016 | 2.9291 × 10⁻⁵ | 1.744 |

**En L₁ el esquema converge a orden 2 limpio** (1.999 y 2.016 en las dos mallas
más finas), lo que satisface con holgura el criterio propuesto
`p_obs ≥ 0.9 · p_teórico`.

**Hay que presentar también el matiz, no esconderlo:** en L₂ el orden se estanca
en ≈ 1.75. El comportamiento es el esperado del recorte del limitador en los
extremos del perfil suave, donde van Leer reduce localmente a primer orden; L₂
pesa esos puntos más que L₁. Es exactamente el tipo de observación que el banco de
pruebas debe cuantificar, y sugiere una pregunta para los codirectores: **¿se
reporta `p_obs` en L₁, en L₂, o en ambas con la explicación?** Nuestra propuesta
es ambas, porque la discrepancia es informativa y no un defecto.

### (c) Aislamiento del efecto del solver de Riemann

Esta es la celda mínima de la matriz de comparación del banco de pruebas, y es la
que responde directamente a la pregunta de investigación. Mismo caso, misma malla
(N = 400), mismo limitador (van Leer), mismo CFL (0.9), mismo integrador: la
**única** variable es el solver.

| Caso | Solver | L₁(ρ) | L₂(ρ) | Mejora de HLLC |
|---|---|---|---|---|
| Sod modificado (test 1) | HLL | 2.4390 × 10⁻³ | 1.2181 × 10⁻² | — |
| | HLLC | 2.3840 × 10⁻³ | 1.2166 × 10⁻² | 2,3 % en L₁ |
| «123» (test 2) | HLL | 4.6338 × 10⁻³ | 6.7571 × 10⁻³ | — |
| | HLLC | 4.6274 × 10⁻³ | 6.7493 × 10⁻³ | 0,1 % en L₁ |
| **Contacto casi estacionario (test 5)** | HLL | 3.4922 × 10⁻² | 2.2476 × 10⁻¹ | — |
| | **HLLC** | **1.3536 × 10⁻²** | **1.1699 × 10⁻¹** | **factor 2,58 en L₁ · 1,92 en L₂** |

**Lectura física, que es el resultado presentable:** HLLC y HLL son
prácticamente indistinguibles cuando la solución no tiene un contacto que
resolver (tests 1 y 2, diferencias por debajo del 2,5 %), y HLLC reduce el error
en **un factor 2,58 en L₁** justo en el caso diseñado para aislar la onda de
contacto. El framework no solo corre: **mide el efecto del componente que se
intercambia, con todo lo demás fijo.** Ese es el entregable central del banco de
pruebas, y ya existe en 1D a escala de una celda de la matriz.

### (d) Positividad sin activar pisos

El caso 2 es el de casi vacío (`p* = 1.8938734201 × 10⁻³`). Su `run_info.txt` de
hoy reporta:

```
floor_rho_hits = 0
floor_p_hits   = 0
exact_residual = 8.882e-16
```

Las velocidades de Davis preservan la positividad en este caso **sin que se
dispare ningún piso numérico**, que es el criterio propuesto en `alcance.md` §3.
Es un dato relevante para la decisión D-3.

## 1.7 El laboratorio pedagógico (prototipo)

`tools/fvlab_lab/` — Tkinter + matplotlib, ≈ 50 KB de Python en siete módulos:
`app.py`, `ui.py` (22 KB), `catalog.py` (13,7 KB), `controller.py`,
`examples.py`, `xl_io.py`, `test_lab.py`.

Decisiones ya registradas (MVP-01 a MVP-06):

- **MVP-02:** el núcleo se invoca **por proceso** (`xEuler1D`), no por pybind11.
- **MVP-03:** el contrato GUI ↔ núcleo es el namelist `&euler` más los `.xl`.
- **MVP-04:** **cero cambios en fórmulas numéricas** para integrar la GUI.
- **MVP-06:** comparar = dos corridas en memoria, no un segundo solver.

Es decir: la GUI **no contiene** HLL, HLLC ni MUSCL. Lanza el binario y pinta.
Eso la mantiene fuera del camino crítico de verificación, y es deliberado.

Materializa el ciclo *aprender → modificar → ejecutar → ver → comparar →
entender*. **Pendiente del director:** si esto cuenta como contribución
evaluable del OE4 o es material de apoyo. Hoy no está comprometido en ningún
objetivo.

## 1.8 Lo que NO existe (dicho antes de que lo pregunten)

| Elemento | Lo dice | Estado real |
|---|---|---|
| **Euler 2D** | pregunta de investigación, OE2, OE3, metodología | **PENDIENTE** |
| **HLLE** (Roe + Einfeldt) | OE2 del anteproyecto, Cuadro 3.1 | **PENDIENTE** — hoy hay HLL con velocidades de **Davis** |
| **WENO** | OE2 («orden 3+»), Gantt | **PENDIENTE** |
| **JSON / YAML** | §4.4 del anteproyecto | **PENDIENTE** — hoy namelist Fortran |
| **GoogleTest / Catch2** | §5.2 | **PENDIENTE** — hoy arnés propio de 110 líneas |
| **VTK / ParaView** | §5.3 | **PENDIENTE** — hoy `.xl` + matplotlib |
| **Sod clásico y Lax** | OE3 («incluyendo el problema de Sod») | **PENDIENTE** — el test 1 es el Sod *modificado* de Toro, con `u_L = 0.75` |
| **Reflexión de Mach** | metodología, Etapa 3 | **PENDIENTE** — exige frontera dependiente del tiempo |
| **Integración continua** | no está en los OE | **PENDIENTE** — sin ella, portabilidad y determinismo son promesas |
| **SSP-RK3** | OE2 pide «orden ≥ 2» | **PENDIENTE** — SSP-RK2 ya cumple la letra |

Esta tabla es el acta de honestidad de la reunión. El marco teórico del plan
radicado afirma en algunos puntos que el framework «implementa» WENO, HLLE, JSON,
GoogleTest y VTK. **No es cierto hoy**, y es mejor decirlo nosotros.

---

# Bloque 2 · Hoja de ruta

## 2.1 Criterio de ordenación

Los hitos **no** están ordenados por tamaño ni por el orden lógico de los
componentes. Están ordenados por **cuánto riesgo eliminan**. Tres reglas:

1. **Primero lo que puede invalidar el diseño.** El *spike* de dimensionalidad va
   antes de escribir 2D: si falla, cambiar de estrategia cuesta mucho menos con
   cero líneas de 2D escritas que con tres mil.
2. **Un resultado publicable lo antes posible.** La matriz de comparación 1D
   llega a mitad del camino. Desde ahí existe algo que responde la pregunta de
   investigación, aunque el 2D no esté.
3. **Lo barato y visible antes que lo caro.** HLLE cuesta poco y cierra dos
   huecos críticos. WENO cuesta mucho y **no toca la pregunta de
   investigación**, que es sobre solvers de Riemann y no sobre reconstructores.

## 2.2 Las fases

### F1 — Cierre de decisiones *(esta reunión)*

Resolver los puntos `A-1`…`C-5` para que el resto del trabajo no se rehaga. Cero
implementación. Cada respuesta se registra en `decision_log.md` y se actualizan
los documentos afectados en el mismo commit.

Si no hay respuesta en algún punto, **no se detiene nada**: cinco de los seis
hitos de la ruta crítica no están bloqueados por ninguna decisión pendiente.

### F2 — Infraestructura y rigor

Convierte los requisitos no funcionales de afirmados a verificados.

- CI en GitHub Actions, matriz de cinco trabajos: GCC Release, GCC Debug, Clang
  Release, regresión con `gfortran`, determinismo.
- Bajar a C++17 si procede (`C-1`): verificado que no se usa ninguna
  característica exclusiva de C++20 (`concept`, `requires`, `consteval`,
  `std::span`, `std::format`, `std::ranges`, `<=>`, corrutinas). **Una línea.**
- Renombrar proyecto y namespace a `fvlab` (`ADR-001`).
- `clang-format` en un commit de formato aislado.
- Completar `run_info.txt` con hash de commit, compilador y opciones.
- Prueba de determinismo: dos ejecuciones idénticas byte a byte.
- Separar `tests/` en `unit/`, `integration/`, `regression/`; crear
  `tests/baseline/` con su política.

**Criterio de cierre:** cinco trabajos de CI en verde. **La regresión debe quedar
exactamente igual**: este hito no cambia numérica, y si algo cambia, el renombrado
tocó lo que no debía.

### F3 — Huecos baratos de alcance

- Extraer `FirstOrderReconstruction` como clase propia que implementa la interfaz.
- Añadir **Sod clásico** (`u_L = u_R = 0`) y **problema de Lax** a la tabla de casos.
- Ejemplos de configuración para ambos.
- `--dry-run` y `--print-config`.

**La prueba que importa:** que `FirstOrderReconstruction` reproduce **exactamente**
el comportamiento del limitador `fo` anterior. Si difiere en el último bit, algo
se reordenó.

### F4 — HLLE y medición del acoplamiento ◄ el hito de mayor valor por esfuerzo

- `HlleRiemannSolver`: promedios de Roe y estimación de velocidades de Einfeldt.
- Valor en el enumerado `RiemannSolverKind`, conversión de cadena, rama en la
  fábrica.
- **Contar y registrar los archivos del núcleo modificados.**

Esa última línea es el punto. El OE1 afirma que se puede intercambiar un
componente sin modificar el núcleo. Aquí se **mide**: si el número de archivos
del núcleo tocados es cero, hay evidencia; si no, el diseño necesita revisión y
es mucho mejor saberlo ahora que en la defensa.

Componentes que deberían bastar: `numerical/riemann/`, el enumerado y la fábrica.
**Si hay que tocar algo más, es un hallazgo y se reporta como tal.**

**Validación obligatoria antes de usarlo en cualquier comparación:** análisis de
convergencia de HLLE por separado. Comparar dos implementaciones sin verificar
antes que ambas son correctas no demuestra nada.

### F5 — Adaptadores de configuración y salida

Lector JSON, escritor CSV en 1D, **conservando** namelist y `.xl`. Prueba de
equivalencia: el mismo caso en JSON y en namelist produce configuraciones
efectivas idénticas. Solo toca `config/` e `io/`; nada numérico.

### F6 — Matriz de comparación 1D ◄ primer resultado publicable

Barrido completo con una sola variable cambiando a la vez, tabulado. Tabla de
L₁, L₂ y **anchura del contacto en celdas**. Adaptar `fig_toro.py` y
`fig_convergencia.py` de las herramientas del director. Figura de detalle del
contacto para el caso 5.

Ya tenemos el prototipo de una celda de esta matriz (§1.6c). Falta
industrializarlo y añadir HLLE.

**Las herramientas que calculan métricas necesitan sus propias pruebas**, porque
producen números que van en la memoria de tesis.

### F7 — Spike de dimensionalidad ◄ el hito de mayor riesgo

Acotado a **un día**. Plantillar `FaceState`, `FaceFlux`, `hllFlux` y `hllcFlux`
e instanciar **solo con `NT = 0`**. No se escribe nada de 2D.

- **Éxito:** suite verde **y** regresión sin cambios (26/26 con pasos idénticos y
  los 9 casos byte a byte que ya coincidían).
- **Aborto:** cualquier cambio en la regresión, o revisión de legibilidad
  negativa por parte de los dos autores. Se pasa a implementaciones separadas por
  dimensión y se documenta como deuda técnica consciente.

Instanciar solo con `NT = 0` es lo que separa «la plantilla rompió algo» de «el
2D está mal». Sin esa separación, un fallo posterior tiene dos causas posibles y
cuesta el doble diagnosticarlo.

### F8 — Núcleo 2D

`Mesh2D`; `CellField2D` con **anchura de fantasmas configurable**; fronteras por
borde con tratamiento correcto de **esquinas**; energía cinética multicomponente
en la EOS; **segunda fórmula de CFL** para el esquema sin separación.

**Riesgo principal: las esquinas.** Son la parte que el código de referencia
resuelve por el orden de llenado —primero periódica en x, después pared en y— y
es fácil equivocarse. Merece una prueba propia y explícita.

Criterio de cierre: se puede construir un estado 2D, rellenar sus fantasmas y
calcular un paso de tiempo. **Todavía no avanza nada.**

### F9 — Operador 2D y Lax–Liu

Reconstrucción direccional; empaquetado/desempaquetado de la rotación en el
barrido en y; divergencia **sin separación dimensional**; Lax–Liu configuración
3; explosión cilíndrica para la prueba de simetría radial.

**La prueba más sensible:** transposición x↔y con u↔v, verificable a nivel de
redondeo (la auditoría del código de referencia la verificó a 10⁻¹⁶). Más: Sod a
lo largo de x contra Sod a lo largo de y, y conservación con fronteras
periódicas. Barrido de CFL de 0.45 a 0.95 midiendo el indicador de tablero de
ajedrez.

### F10 — Salida VTK

Escritor VTK para malla estructurada, conservando `.xyl`. Criterio: ParaView abre
el archivo sin conversión intermedia. Solo toca `io/`.

### F11 — WENO *(condicional a `A-2`)*

`WenoReconstruction` con indicadores de suavidad y pesos no lineales. Orden según
`C-5`. Criterio: `p_obs ≥ 0.9 × 3` medido sobre solución suave, y ausencia de
oscilaciones cerca de discontinuidades.

Es el hito más caro y el único que no toca la pregunta de investigación. Si el
tiempo aprieta, es el **primer candidato a trabajo futuro**, y `A-2` existe
precisamente para decidirlo por escrito y a tiempo.

### F12 — Validación 2D y matriz 2D

Matriz de comparación en 2D. Adaptar `fig_euler2d.py` incluida su métrica de
simetría radial. Reflexión de Mach si `B-2` lo confirma.

### F13 — Documentación pedagógica y reproducibilidad

Manual de instalación; tutoriales progresivos 1D → 2D; un archivo de
configuración por caso; referencia de interfaces completa en las cabeceras.

**Prueba de reproducibilidad desde cero:** instalar, configurar y simular
siguiendo únicamente la documentación, **sin intervención de los autores**. Se
ejecuta y se documenta el resultado, incluidos los puntos donde la documentación
resultó insuficiente.

### F14 — Cierre de tesis

Diagrama de componentes en su formato final; trazabilidad sin filas críticas
huérfanas; cada figura etiquetada con el commit que la produjo.

## 2.3 Ruta crítica

```
F2 → F3 → F4 → F6                     primer resultado publicable (1D)
          F4 → F7 → F8 → F9 → F12     dos dimensiones
```

F5, F10 y F11 están **fuera** de la ruta crítica: se pueden reordenar o diferir
sin retrasar el resultado central.

## 2.4 Módulo integrado de verificación y validación

Hoy existen las piezas: `ErrorMetrics` con `max|d|`, `L1`, `L2` y `rel_max`
(`validation/error_analyzer.hpp`), el `ExactRiemannSolver`, y `euler1d_compare`.
Lo que falta es convertirlas en un módulo que produzca el entregable
directamente:

| Capacidad | Hoy | Objetivo |
|---|---|---|
| L₁, L₂ por variable | sí, vía `compareFields` y `euler1d_compare` | reporte automático por corrida |
| Orden `p_obs` | script externo *ad hoc* (§1.6b) | integrado y probado |
| Anchura del contacto en celdas | no | métrica propia, con prueba |
| Exportación CSV | no (`.xl`) | sí (`C-4`) |
| Exportación VTK | no | sí, 2D (`C-4`) |
| Positividad / pisos | sí, `floor_rho_hits`, `floor_p_hits` en `run_info.txt` | criterio de aceptación explícito |
| Conservación discreta | probada en la suite | reportada por corrida |
| Simetría radial 2D | no | métrica de `fig_euler2d.py`, adaptada y probada |

**Nota terminológica que conviene cerrar con los codirectores.** El plan usa
«validar» para la comparación contra el Riemann exacto. Según Oberkampf y Roy
(2010) —que el propio plan cita— eso es **verificación**: comparar el código con
una solución del mismo modelo matemático. «Validación» es comparar el modelo con
la realidad física. Propuesta: usar *verificación* en 1D (solución exacta) y
*validación* en 2D (referencia de alta fidelidad publicada), y explicarlo en una
nota al pie. Es gratis y quita una pregunta de la defensa.

---

# Bloque 3 · Decisiones técnicas para el director y codirectores

Cada decisión tiene: el hecho verificado, las opciones, nuestra recomendación con
su razón, el coste de equivocarse, y qué necesitamos exactamente de ustedes.

---

## D-1 · Polimorfismo dinámico vs. polimorfismo estático

### Lo que hay hoy

Interfaces virtuales puras para los cinco puntos de variación, **pero con
granularidad de barrido**: el método virtual procesa un vector completo de caras,
no una celda. Resultado: **≈ 5 llamadas virtuales por paso temporal** (una por
etapa de Runge-Kutta y por interfaz), con un bucle plano y vectorizable dentro.

Los limitadores ya son polimorfismo **estático**: tipos-política con métodos
estáticos instanciados en `sweep<Limiter>`. El Fortran hacía
`select case (trim(limiter))` dentro del bucle sobre celdas y componentes, es
decir **una comparación de cadenas por celda y componente**. Aquí el coste es
cero.

### Las opciones

| | A — mantener interfaces virtuales | B — migrar a `std::variant` / CRTP |
|---|---|---|
| Coste en ejecución | ≈ 5 llamadas virtuales por paso | 0 |
| Legibilidad para un estudiante | alta: `virtual FluxVector flux(qL, qR)` se lee como la fórmula | baja: `std::visit` y plantillas recursivas |
| Inyección por configuración | trivial: `unique_ptr` desde la fábrica | exige que el conjunto de tipos sea cerrado en compilación |
| Extensibilidad por terceros | añadir una clase | modificar el `variant`, es decir **tocar el núcleo** |
| Cumple «clases abstractas» del anteproyecto §4.2 | sí, literalmente | requiere explicación |

### Nuestra recomendación: **A**, y está ya registrada

`architecture.md` §12.7 descarta CRTP y `std::variant` explícitamente. La razón
es cuantitativa: el *overhead* que B elimina son **cinco llamadas indirectas por
paso temporal**. Para dimensionarlo en 2D: una malla de 400² tiene 160 000 celdas
y unas 320 800 caras. Con granularidad de celda, B ahorraría cientos de miles de
indirecciones por barrido y sería obligatorio. **Con granularidad de barrido, lo
que ahorra es 5.**

Y hay un argumento que pesa más que el rendimiento: con `std::variant`, añadir
HLLE significa **modificar el tipo `variant`**, es decir tocar un archivo del
núcleo. Eso degrada precisamente la métrica que el OE1 va a reportar («número de
archivos del núcleo tocados = 0»). La opción B nos haría más difícil demostrar la
tesis.

Donde sí usamos plantillas es donde el punto de variación está **dentro** de un
bucle caliente: limitadores (ya hecho) y dimensión (`ADR-009`, ver D-2).

### Lo que pedimos

1. Aval de que interfaces virtuales con granularidad de barrido satisface
   «interfaces abstractas fundamentales» del anteproyecto §4.2.
2. Confirmación de `ADR-012`: de las cuatro interfaces que enumera el
   anteproyecto, `Mesh` se implementaría como **contrato de tiempo de
   compilación** (verificado con `static_assert`) y no como clase virtual, porque
   la malla se consulta celda a celda y una llamada virtual ahí caería en el punto
   más caliente del código. Aparecería como interfaz en el diagrama, documentada
   con el mismo rigor, pero sin tabla virtual. **Conviene tenerlo acordado por
   escrito antes de la defensa, no durante.**
3. Si prefieren que midamos en lugar de argumentar: podemos instrumentar un
   *benchmark* y reportar el porcentaje real del tiempo de pared. Nuestra
   estimación es que queda por debajo del ruido de medición.

---

## D-2 · Extensión a 2D: *dimensional splitting* vs. *unsplit*

### Las opciones

| | A — *Strang/Godunov splitting* | B — *Unsplit* |
|---|---|---|
| Reutiliza el solver 1D | casi literalmente | sí, vía `FaceState<NT>` |
| Esfuerzo inicial | menor | mayor: reconstrucción direccional + rotación |
| Criterio de CFL | el 1D por eje | **distinto**: hay que deducirlo y verificarlo |
| Error adicional | término de separación O(Δt²) | ninguno |
| Comparabilidad con el `Code_Euler2D` del director | **se pierde** | se conserva |
| Simetría x↔y | no exacta (depende del orden de barrido) | exacta a nivel de redondeo |

### Nuestra recomendación: **B, *unsplit***

Tres razones, en orden de peso:

1. **Contamina la medición.** El *splitting* introduce un error de separación que
   se suma al error del esquema. La pregunta de investigación es «¿cuánto cambia
   el resultado al cambiar el solver de Riemann?». Si hay un término de
   separación O(Δt²) de por medio, parte de la diferencia observada entre HLLE y
   HLLC no es del solver. **La variable que queremos aislar queda mezclada con
   una que introdujimos nosotros.**
2. **Pierde la regresión en 2D.** El `Code_Euler2D` de referencia es *unsplit*.
   Con *splitting* el criterio de CFL es otro, el número de pasos difiere, y la
   comparación celda a celda contra su código —que es la estrategia de validación
   que ya funciona en 1D— deja de ser posible. Perderíamos en 2D el activo más
   valioso que tenemos en 1D.
3. **La simetría deja de ser exacta.** Con *splitting*, Sod a lo largo de x y Sod
   a lo largo de y dan resultados distintos al último bit según el orden de
   barrido. Con *unsplit*, la transposición x↔y con u↔v es verificable a 10⁻¹⁶, y
   es la prueba más sensible que tenemos para detectar un error en la rotación.

El coste de B está acotado y ya está diseñado (`ADR-009`): el solver de Riemann
se escribe **una sola vez** sobre un estado en el marco de la cara, con velocidad
normal explícita y `NT` velocidades tangenciales pasivas (`NT = 0` en 1D,
`NT = 1` en 2D). `std::array<double, 0>` está vacío y los bucles de longitud cero
desaparecen en compilación: **el 1D no paga nada**. La rotación vive en el
barrido, no en el solver, lo que la localiza en un sitio y permite probarla por
separado.

### El punto que hay que confirmar con el director

El esquema *unsplit* exige una **segunda fórmula de CFL**, más restrictiva que la
1D, porque las velocidades de señal de ambos ejes compiten por el mismo Δt. La
forma estándar es

$$\Delta t = \frac{\mathrm{CFL}}{\dfrac{S_x}{\Delta x} + \dfrac{S_y}{\Delta y}}$$

**Esto es propuesta nuestra, no está implementado.** Queremos confirmar que es la
forma que usa su `Code_Euler2D`, porque si difiere, el número de pasos no
coincidirá y la comparación celda a celda fallará por una razón que no es un
error de nuestro código. Registrado como invariante `INV-006`, a verificar con un
barrido de CFL de 0.45 a 0.95 midiendo el indicador de tablero de ajedrez.

### Lo que pedimos

1. Confirmación de la fórmula de CFL de su código 2D *unsplit*.
2. Aval de que **no** usemos *dimensional splitting*, aunque el camino corto sea
   tentador.
3. `B-3`: ¿cuántas configuraciones de Lax–Liu? Su código de referencia trae la
   configuración 3 únicamente.

---

## D-3 · Estimación de velocidades de onda (S_L, S_R, S*)

### Lo que hay hoy, con precisión

`davisWaveSpeeds()` en `numerical/riemann/riemann_solver.hpp`:

```cpp
S_L = min(u_L - a_L,  u_R - a_R)
S_R = max(u_L + a_L,  u_R + a_R)
```

Son las **estimaciones directas de Davis** (Toro §10.5.1), que corresponden a la
columna «Simple» del Cuadro 3.1 del anteproyecto. **No son Einfeldt.** No hay
promedios de Roe en ninguno de los dos códigos.

La velocidad del contacto en `hllc.hpp` sigue literalmente Toro (10.37):

$$S_* = \frac{p_R - p_L + \rho_L u_L (S_L - u_L) - \rho_R u_R (S_R - u_R)}
             {\rho_L (S_L - u_L) - \rho_R (S_R - u_R)}$$

**Consecuencia que hay que decir con claridad: lo que el anteproyecto llama HLLE
no está implementado.** Lo que está implementado es HLL con Davis. El OE2 nombra
«HLLE y HLLC», así que esto es un hueco de alcance real, no una cuestión de
nombres.

### Las opciones

| | A — Davis (actual) | B — Roe + Einfeldt (HLLE propiamente) | C — híbrido adaptativo de Toro (PVRS/TRRS, §10.5.2) |
|---|---|---|---|
| Coste de implementación | 0, ya está | bajo: promedios de Roe y una corrección | medio: lógica de selección por régimen |
| Positividad en casi vacío | **verificada**: test 2 con 0 disparos de piso | en principio mejor acotada | la más robusta |
| Precisión en el contacto | la que ya medimos (§1.6c) | a medir | a medir |
| Cumple el OE2 | **no** | **sí** | sí, con explicación |
| Rompe la regresión contra el Fortran | no | no, si es clase nueva | no, si es clase nueva |

### Nuestra recomendación: **las tres coexisten; ninguna sustituye a otra**

Esta decisión suele plantearse como «cuál elegimos». Creemos que es la pregunta
equivocada. **La diferencia entre estimaciones de velocidad es exactamente lo que
la tesis mide.** Si elegimos una, destruimos el objeto de estudio.

Propuesta concreta:

1. **`HllRiemannSolver` se queda intacto con Davis.** Es el ancla de regresión
   contra el Fortran: 26/26 configuraciones, pasos idénticos. Tocarlo cuesta ese
   activo y no gana nada.
2. **`HlleRiemannSolver` nuevo**, con promedios de Roe y corrección de Einfeldt.
   Es el hito F4 y cierra el hueco del OE2. Al implementarlo medimos cuántos
   archivos del núcleo hay que tocar, que es la evidencia del OE1.
3. **El `S*` de HLLC se queda como está**, Toro (10.37). Está verificado contra
   los valores estrella publicados de Toro en `test_exact_riemann`.
4. **C queda como opción si aparece un caso que lo exija.** Hoy no lo exige
   ninguno: el test 2, que es el de casi vacío con `p* = 1.89 × 10⁻³`, corre con
   `floor_rho_hits = 0` y `floor_p_hits = 0`. No vamos a añadir complejidad para
   un problema que no se ha manifestado; si aparece en 2D, se añade como tercera
   política de velocidades.

Hay una decisión de diseño implícita que conviene hacer explícita: **¿la
estimación de velocidades es una política inyectable o parte del solver?** Hoy
está acoplada (`davisWaveSpeeds` se llama dentro de `hllFlux` y `hllcFlux`).
Separarla permitiría cruzar «HLLC con Davis» contra «HLLC con Einfeldt», lo que
**duplica la resolución de la matriz de comparación** sin escribir un solver
nuevo. Es una celda más de la matriz por casi nada de código.

### Lo que pedimos

1. Confirmación de que HLLE es entregable comprometido (`A-1`, `A-2` lo tocan de
   refilón, pero el OE2 lo nombra explícitamente).
2. Criterio sobre si la estimación de velocidades debe ser un punto de variación
   independiente del solver. **Recomendamos que sí**, por lo que dobla en la
   matriz.
3. `B-4`: ¿la matriz completa 3 × 3 (tres reconstructores × tres solvers), o
   basta aislar HLLE contra HLLC con el reconstructor fijo? Nueve combinaciones ×
   cuatro resoluciones × varios casos es sensiblemente más trabajo y más
   superficie de figura.

---

## D-4 · Soluciones exactas y de referencia para la verificación

### En 1D: ya está decidido por el código

`ExactRiemannSolver` (`numerical/riemann/exact_riemann_solver.hpp` + 185 líneas
de `.cpp`) implementa Toro capítulo 4: función de presión `f_K(p)` con rama de
choque (Rankine–Hugoniot) y de rarefacción (invariante de Riemann), Newton–Raphson
sobre `f(p) = f_L + f_R + (u_R − u_L) = 0` con semilla TRRS (4.46), muestreo
autosimilar `W(x/t)` incluido el interior de los abanicos, y el criterio de vacío
(4.40). Tolerancias: `kNewtonTolerance = 1e-14`, `kResidualTolerance = 1e-10`.

Está verificado contra los **valores estrella publicados de Toro** en
`test_exact_riemann` (12 casos). Residuos medidos hoy: 8.88 × 10⁻¹⁶ (test 2),
1.42 × 10⁻¹⁴ (test 5).

**Por qué en C++ y no en un script externo de Python:** `ADR-022` establece que
el solver exacto **no participa en el avance temporal**. Si participara, la
comparación contra la solución exacta sería circular. Pero sí tiene que estar
*dentro* del framework, por tres razones: (a) produce los `*_exact.xl` en la misma
corrida y con la misma malla, sin interpolación intermedia; (b) un script externo
reintroduciría una dependencia de Python para calcular un número que va en la
memoria de tesis, y `ADR-010` elimina deliberadamente las dependencias
obligatorias; (c) los mismos tests unitarios lo verifican contra Toro, lo que no
sería posible si viviera fuera.

Python se queda **solo para figuras** (`ADR-007`), nunca para calcular métricas
que se reporten… con una excepción que hay que probar: la métrica de simetría
radial de `fig_euler2d.py`. Esa **calcula**, no dibuja, y por tanto necesita sus
propias pruebas.

### En 2D: aquí sí hay decisión que tomar

No hay solución analítica cerrada para Lax–Liu ni para la reflexión de Mach.

| | A — malla ultra-fina del propio código | B — datos digitalizados de la literatura (Liska & Wendroff 2003, Woodward & Colella 1984) |
|---|---|---|
| Independencia de nuestra implementación | **ninguna** | total |
| Riesgo de circularidad | **alto** | ninguno |
| Coste | tiempo de cómputo | digitalización y su error |
| Qué demuestra | autoconsistencia (convergencia de malla) | acuerdo con resultados publicados |
| Nombre correcto | **verificación** | **validación** |

### Nuestra recomendación: **los dos, con roles distintos y nombres distintos**

El error que hay que evitar es tratar A como «la referencia». `ADR-013` existe
precisamente para eso: el fallo es fácil de cometer, silencioso, e invalidaría la
estrategia completa —alguien regenera «la referencia» con el código que quería
validar, y a partir de ahí todo pasa siempre.

Propuesta:

1. **B es la referencia de validación.** Datos digitalizados de Liska & Wendroff
   (2003) para Lax–Liu. Se documenta la fuente, la figura concreta y el error de
   digitalización estimado. Van en `tests/reference/` junto a los datos del
   Fortran, con su procedencia anotada.
2. **A es un estudio de autoconvergencia, y se llama así.** La malla fina propia
   vive en `tests/baseline/`, nunca en `tests/reference/`, y lo que demuestra es
   que la solución converge al refinar, no que sea correcta.
3. **Métricas estructurales como tercer pilar**, porque no necesitan referencia
   externa y son muy sensibles: simetría radial de la explosión cilíndrica,
   transposición x↔y con u↔v a nivel de redondeo, y conservación exacta con
   fronteras periódicas. Estas tres detectan un error de rotación o de
   ensamblado que una comparación visual con una figura publicada no detectaría.
4. **Salvaguarda automática:** el test de regresión aborta si encuentra en
   `tests/reference/` un archivo que solo el C++ produce.

### Lo que pedimos (material, no solo criterio)

1. **`correr_pruebas.py`** — la suite de regresión del proyecto. El `Makefile` de
   `Code_Euler2D` la invoca (`cd .. && python3 correr_pruebas.py Code_Euler2D`,
   admite `--rapido`) pero no venía en ninguno de los dos paquetes recibidos. Sin
   ella no conocemos su criterio operativo de «pasa», sus tolerancias ni sus
   métricas. Nuestra suite puede estar exigiendo más o menos que la suya, y en
   cualquiera de los dos casos conviene saberlo.
2. **`Code_Euler1D` actualizado.** El paquete recibido corresponde al estado del
   18 de agosto a las 07:36. Ese mismo día a las 18:21 hay un commit —«El piso de
   presión deja de dispararse en silencio»— cuyo texto declara haber modificado
   los cuatro códigos con ecuación de energía, Euler1D incluido. Verificamos que
   el `euler1d.f90` que tenemos **no contiene** ese contador. La migración se
   validó contra una versión que usted ya no tiene. La validación es real y
   medida; simplemente hay que poder declarar con precisión contra qué.
3. **Confirmación de que no hay entregas de Euler posteriores** al 18 de agosto.
4. **Un ejemplo del estándar esperado** para el capítulo de resultados: una figura
   o tabla de un trabajo similar. El entregable central es una tabla y una
   figura; saber el formato esperado ahorra una iteración completa.
5. `B-5`: confirmación de la tolerancia aceptable. Propuesta:
   `max|diff| ≤ 10⁻¹² + 10⁻⁹ · max|ref|` en todas las variables **y número de
   pasos temporales idéntico**. Ese criterio ya se cumple hoy; confirmarlo sirve
   para poder afirmarlo en la memoria sin tener que defender el número.

---

## D-5 · Ecosistema de herramientas, dependencias y formatos

### Lo que hay hoy

**Cero dependencias externas obligatorias** (`ADR-010`). Compilar y probar
requiere solo un compilador y CMake. Nada de red, submódulos ni gestores de
paquetes.

- Configuración: parser propio de namelist `&euler` (`src/config/namelist_parser.cpp`, 243 líneas), estricto como gfortran.
- Salida: `.xl` con el formato `es20.10e3` del Fortran, byte a byte.
- Tests: arnés propio (`tests/test_support.hpp`, 110 líneas), 87 casos bajo CTest.

### D-5a · Formato de configuración

| | A — JSON con parser propio | B — `nlohmann/json` incorporado | C — `yaml-cpp` |
|---|---|---|---|
| Dependencia de red | no | no, si se versiona la cabecera | **sí**, o submódulo + compilación |
| Tamaño añadido al repo | ~300 líneas propias | ~900 KB de cabecera | biblioteca completa |
| Esfuerzo | escribir y probar el parser, entradas mal formadas incluidas | ninguno | configuración de CMake |
| Robustez del formato | esquema plano y conocido | la de una biblioteca madura | YAML es sutil y fácil de malinterpretar |
| Cumple §4.4 del anteproyecto | sí | sí | sí |

**Nuestra recomendación: JSON, no YAML.** La razón es concreta y no estética: JSON
se puede analizar sin dependencias externas; YAML no, y un «subconjunto de YAML
escrito a mano» es una mala idea por lo sutil que resulta el formato (indentación
significativa, tipos implícitos, anclas).

Entre A y B somos honestos: **las dos son defendibles.** `ADR-010` elige A porque
el esquema es plano y ya tenemos un parser estricto con 25 pruebas. Pero
`nlohmann/json` versionado como cabecera única **también** satisface el requisito
de no-red, y nos ahorraría escribir y probar un parser. Si ustedes prefieren el
estándar de la industria sobre el código propio, B es aceptable sin discusión.
**Nuestra preferencia es A por coherencia con `ADR-010`, pero no es una colina en
la que morir.**

En cualquier caso, el **lector de namelist se conserva** (`ADR-011`). No es
duplicación gratuita: es lo que preserva indefinidamente la capacidad de ejecutar
sus `input.par` y comparar byte a byte con sus salidas, y es la demostración
práctica del desacoplamiento que defiende el OE1 —dos adaptadores que convergen
en un único punto de validación.

### D-5b · Arnés de pruebas

| | A — arnés propio (actual) | B — Catch2 v2, cabecera única versionada | C — GoogleTest vía `FetchContent` |
|---|---|---|---|
| Cumple §5.2 del anteproyecto | **no** | **sí** | sí |
| Requiere red | no | **no** | **sí** |
| Coste | ninguno, ya funciona | migrar 87 casos, mecánico | configuración + red |

**Nuestra recomendación: B** (`ADR-004`). Es la única opción que satisface
simultáneamente §5.2 (que nombra «Google Test o Catch2») y el requisito de no
descargar nada. Catch2 v2 se distribuye como un único `catch.hpp` versionable en
`third_party/`. **GoogleTest queda descartado** no por calidad, sino porque su
integración práctica exige red.

El mapeo es directo: `TEST(nombre)` → `TEST_CASE("nombre")`, `CHECK_NEAR(a,b,tol)`
→ `REQUIRE_THAT(a, WithinAbs(b,tol))`, `CHECK_THROWS(e,T)` →
`REQUIRE_THROWS_AS(e,T)`. CTest no cambia, lo que acota el riesgo a la forma de
escribir aserciones.

Se migra **en un solo hito, no gradualmente**: dos arneses conviviendo es peor
que cualquiera de los dos.

### D-5c · Salida y visualización

**Recomendación: VTK Legacy ASCII escrito a mano**, sin enlazar VTK-dev.

Para una malla cartesiana estructurada el formato legacy es una cabecera de seis
líneas (`# vtk DataFile Version 3.0`, `STRUCTURED_POINTS`, `DIMENSIONS`,
`ORIGIN`, `SPACING`, `POINT_DATA`) seguida de los valores. Son unas 60 líneas de
código. Enlazar VTK-dev añadiría cientos de megabytes de dependencia para
escribir eso.

- 1D: CSV para análisis y matplotlib, conservando `.xl` para la regresión.
- 2D: VTK legacy para ParaView, conservando `.xyl` para la regresión.
- **Binario vs ASCII:** empezamos en ASCII porque es inspeccionable y
  diff-eable, que importa para la depuración y para la docencia. Si el tamaño
  molesta en mallas de 400², añadimos la variante binaria después; el cambio es
  local a `io/`.

### Lo que pedimos

1. `C-3`: ¿JSON o YAML? **Recomendamos JSON.** Y si JSON, ¿parser propio o
   `nlohmann/json` versionado? Nos vale cualquiera de los dos.
2. `C-2`: ¿Catch2 v2 versionado, o conservamos el arnés propio? El arnés propio
   se eligió deliberadamente para que el proyecto compile sin descargar nada; si
   eso les parece más valioso que la letra de §5.2, lo dejamos y lo justificamos
   en la memoria.
3. `C-4`: aval de CSV + VTK legacy conservando `.xl`/`.xyl`.
4. `P-14`: ¿adoptamos el estilo de figuras de sus herramientas —mapas en
   `inferno`, perfiles en blanco y negro, tipografía serif— como estándar del
   proyecto? Afecta solo a la presentación, pero decidirlo una vez ahorra rehacer
   figuras al final.

---

## D-6 · Alcance de WENO y condiciones de contorno

### El dato técnico que decide

`physics/field.hpp` línea 14:

```cpp
/// Numero de celdas fantasma por lado. El Fortran declara `U(3,-1:N+2)`,
/// es decir dos fantasmas a cada lado; la reconstruccion MUSCL en la cara
/// k+1/2 necesita las celdas k-1, k, k+1, k+2.
inline constexpr int kGhostCells = 2;
```

Dos celdas fantasma por lado: exactamente lo que MUSCL necesita, ni una más.

| | A — WENO3 | B — WENO5 (Jiang–Shu) |
|---|---|---|
| Stencil | 3 celdas | 5 celdas |
| Celdas fantasma | **2 — las que ya hay** | **3 — hay que ampliar** |
| Cumple «orden 3+» del OE2 | sí | sí |
| Archivos del núcleo que toca | solo `numerical/reconstruction/` | además `physics/field.hpp` y **las tres condiciones de frontera** |
| Impacto en la reflexión de Mach 2D | ninguno | hay que revisar la pared reflectiva y **las esquinas** |
| Es el estándar de la literatura | no | sí |

### Nuestra recomendación: **WENO3, y condicionado a que WENO entre en el alcance**

Dos razones:

1. **WENO3 cabe en el diseño actual sin tocar el núcleo.** WENO5 obliga a ampliar
   `kGhostCells` de 2 a 3, lo que arrastra `physics/field.hpp` y las tres
   condiciones de frontera, y en 2D arrastra el tratamiento de esquinas, que ya
   es el riesgo principal del hito F8.
2. **Y aquí está la ironía que conviene decirle al director:** WENO5 sería el
   único cambio del proyecto que **daña la afirmación que la tesis mide**. El OE1
   va a reportar «archivos del núcleo tocados al añadir un esquema = 0». WENO5
   convierte «añadir un reconstructor» en una modificación del núcleo
   (`field.hpp` + tres fronteras). Tendríamos que documentarlo como tal y
   explicar por qué ese caso es la excepción. WENO3 no tiene ese problema.

**Pero antes que el orden hay una pregunta previa y más importante: `A-2`,
¿WENO es entregable comprometido o trabajo futuro?**

Es el único entregable grande que **no toca la pregunta de investigación**, que es
sobre solvers de Riemann y no sobre reconstructores. Y es la mayor adición técnica
del proyecto: indicadores de suavidad, pesos no lineales, y la ampliación de
fantasmas si es WENO5.

Hay además una asimetría documental que conviene resolver en la misma frase: la
presentación del tema pide «al menos **dos** reconstructores» —que ya se cumple
con orden 1 y MUSCL— y el anteproyecto pide «**tres**, incluido WENO de orden
3+». Son dos documentos con exigencias distintas, y de eso depende todo el
alcance (`A-1`).

**Nuestra posición honesta:** si el tiempo aprieta, WENO es el primer candidato a
pasar a trabajo futuro, y preferimos decidirlo hoy por escrito que descubrirlo en
la semana 14. Si entra, debe decidirse **antes** del hito F8, porque la anchura
configurable de celdas fantasma se diseña ahí y es más barato hacerlo bien la
primera vez que readaptarlo.

### Sobre las condiciones de contorno de la reflexión de Mach

Un detalle que conviene tener presente al decidir `B-2`: la reflexión de Mach
requiere una **condición de frontera dependiente del tiempo** (la posición del
choque incidente en la frontera superior avanza con el tiempo) que **no existe en
el código de referencia**, además del tratamiento de la rampa. Lax–Liu por sí solo
satisface el OE3 tal como está redactado («al menos un caso en 2D»); la
metodología, Etapa 3, nombra además la reflexión de Mach.

### Lo que pedimos

1. `A-1`: ¿rige el anteproyecto sobre la presentación del tema? Asumimos que sí,
   por ser posterior y más detallado. **Es la pregunta de mayor impacto de toda la
   lista.**
2. `A-2`: ¿WENO es entregable comprometido o trabajo futuro?
3. `C-5`: si entra, ¿WENO3 o WENO5? **Recomendamos WENO3.**
4. `B-2`: ¿la reflexión de Mach es entregable comprometido o meta opcional?

---

## Decisiones rápidas (un minuto cada una)

Están aquí para cerrarlas en la reunión y no arrastrarlas.

| # | Punto | Hoy | Recomendación |
|---|---|---|---|
| **R-1** | `C-1`: el marco del plan dice **C++17**, `CMakeLists.txt` dice **C++20** | C++20 | **Bajar a C++17.** Verificado por búsqueda que no se usa ninguna característica exclusiva de C++20: ni `concept`, `requires`, `consteval`, `std::span`, `std::format`, `std::ranges`, `<=>` ni corrutinas. **Es una línea.** Deja de haber una discrepancia con un documento ya radicado |
| **R-2** | `ADR-001`: el nombre `Euler1D_Cpp` / namespace `euler1d` queda incorrecto al entrar el 2D | propuesto desde septiembre | Renombrar a **FVLab** / `fvlab`. Un namespace `euler1d::` en código bidimensional resta credibilidad al trabajo de ingeniería. Sin efecto numérico: si la regresión cambia, el renombrado tocó lo que no debía |
| **R-3** | `B-1`: formato del diagrama de componentes (entregable del OE1) | notación libre en `architecture.md` §13 | Confirmar si esperan **UML formal, C4 o libre**. Hay uno usable tal cual; rehacerlo en notación formal es trabajo de un día |
| **R-4** | Terminología verificación / validación | el plan usa «validar» para la comparación contra el exacto | Usar **verificación** en 1D y **validación** en 2D, con nota al pie citando a Oberkampf y Roy (2010), que el propio plan ya cita |
| **R-5** | El prototipo de laboratorio GUI | no está comprometido en ningún objetivo | Decidir si cuenta como contribución evaluable del **OE4** o es material de apoyo. Hoy trabajamos en él sin que esté en el alcance |
| **R-6** | `P-15`: objetivo de rendimiento (§4.3 dice «tiempo razonable») | sin número, no verificable | Propuesta: **Lax–Liu en malla 400² hasta su tiempo final en menos de 10 minutos en un solo núcleo** |
| **R-7** | Integración continua | no existe | Activarla. Sin CI, portabilidad, determinismo, ausencia de advertencias y regresión son **promesas**, no hechos verificados |

---

## Resumen de lo que pedimos hoy

### Decisiones (doce puntos abiertos de `alcance.md`)

| # | Pregunta | Bloquea | Nuestra recomendación |
|---|---|---|---|
| A-1 | ¿Rige el anteproyecto sobre la presentación del tema? | todo el alcance | sí, el anteproyecto |
| A-2 | ¿WENO es entregable o trabajo futuro? | F11 | decidirlo hoy; si aprieta, trabajo futuro |
| B-1 | Formato del diagrama de componentes | F14 | el existente, o UML si lo prefieren |
| B-2 | ¿Reflexión de Mach comprometida u opcional? | F12 | opcional; Lax–Liu ya satisface el OE3 |
| B-3 | ¿Cuántas configuraciones de Lax–Liu? | F12 | la 3, que es la de su código |
| B-4 | ¿Matriz 3 × 3 completa o HLLE vs HLLC? | F6, F12 | infraestructura completa, presentar un subconjunto |
| B-5 | Tolerancia aceptable frente al Fortran | criterio de aceptación | `10⁻¹² + 10⁻⁹·max|ref|` y pasos idénticos |
| C-1 | ¿C++17 o C++20? | implementación | **C++17**, es una línea |
| C-2 | ¿Catch2 o arnés propio? | F2/migración | **Catch2 v2 versionado** |
| C-3 | ¿JSON o YAML? ¿Parser propio o biblioteca? | F5 | **JSON**; parser propio o `nlohmann` versionado |
| C-4 | ¿CSV y VTK conservando `.xl`? | F5, F10 | **sí, ambos** |
| C-5 | ¿WENO3 o WENO5? | F11 | **WENO3** |

### Material

1. `correr_pruebas.py`
2. `Code_Euler1D` posterior al 18 de agosto de 2026
3. Confirmación de que no hay entregas de Euler posteriores
4. Un ejemplo del estándar esperado para el capítulo de resultados
5. Fórmula de CFL de su `Code_Euler2D` *unsplit*

### Lo que NO necesitamos decidir hoy

Para que la reunión no se alargue sin necesidad: **cinco de los seis hitos de la
ruta crítica no están bloqueados por ninguna decisión pendiente.** F2
(infraestructura), F3 (huecos baratos), F4 (HLLE y su medición), F6 (matriz 1D) y
F7 (*spike* de dimensionalidad) se pueden ejecutar íntegramente con lo que ya hay
decidido. Si la reunión se queda sin tiempo, lo importante es cerrar `A-1`, `A-2`
y la fórmula de CFL 2D.

---

## Anexo · Cómo reproducir todas las cifras de este documento

```powershell
cd C:\Users\USER\OneDrive\Documentos\Tesis\Euler1D_Cpp
$env:PATH = "C:\msys64\ucrt64\bin;" + $env:PATH

# 1. Build limpio y suite completa (§1.1, §1.5)
cmake -S . -B build-reunion -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-reunion
ctest --test-dir build-reunion --output-on-failure

# 2. Equivalencia byte a byte con el Fortran, caso 1 (§1.6a)
.\build-reunion\xEuler1D.exe -i runs_reunion\toro1\input.par -o runs_reunion\toro1
.\build-reunion\euler1d_compare.exe tests\reference\toro1 runs_reunion\toro1

# 3. Orden de convergencia observado (§1.6b)
python runs_reunion\convergencia.py runs_reunion

# 4. HLL vs HLLC aislando el solver (§1.6c)
python runs_reunion\matriz_hll_hllc.py runs_reunion
```

Los dos scripts de análisis (`runs_reunion/convergencia.py` y
`runs_reunion/matriz_hll_hllc.py`) son *ad hoc* de esta reunión. Si el director
aprueba el formato, se industrializan en el hito F6 con sus propias pruebas,
porque producen números que irán en la memoria.

---

## Anexo · Cómo compilar la presentación

```bash
pdflatex presentacion_avance.tex    # dos veces, por el índice
```

No hay LaTeX instalado en esta máquina, así que **el `.tex` no se pudo compilar
para verificarlo**. Está escrito para compilar con `pdflatex` sin paquetes fuera
de una instalación estándar de TeX Live o MiKTeX, y funciona igual en Overleaf
(subir el `.tex` y elegir *pdfLaTeX*). Tres notas por si algo falla:

1. **Tema.** Está activo `Madrid`, que existe en cualquier instalación. Para usar
   Metropolis, comentar las tres líneas del bloque `% ---- tema ----` y
   descomentar las dos marcadas `ALTERNATIVA METROPOLIS`. Metropolis se ve mejor
   compilado con XeLaTeX o LuaLaTeX, porque usa la tipografía Fira.
2. **Diapositivas densas.** Las que llevan tablas largas usan la opción
   `[shrink]` de Beamer, que reduce el contenido automáticamente si no cabe.
   Verás avisos del tipo `Overfull \vbox` o `shrinking by N percent`: son
   advertencias, no errores, y el PDF sale bien. Si una diapositiva queda
   demasiado pequeña para proyectar, pártela en dos.
3. **Diapositivas con código.** Las cuatro que contienen `lstlisting` llevan
   `[fragile]` y **no** llevan `[shrink]` (las dos opciones no se combinan bien).
   Si alguna se desborda, baja `\scriptsize` a `\tiny` en ese bloque.

El diagrama de arquitectura está en TikZ con tres niveles: orquestación, avance
temporal y los cinco puntos de variación. Solo usa las bibliotecas `positioning`,
`arrows.meta` y `fit`.

---

## Procedencia de este documento

- Código inspeccionado: `Euler1D_Cpp` en el commit `72fdcbb` («Plan de
  implementacion del prototipo FVLab Studio») más cambios locales sin commitear
  (`README.md`, `docs/decision_log.md`, `docs/mvp_plan.md`, `run_lab.*`,
  `tools/`).
- Documentos de proyecto consultados: `alcance.md`, `roadmap.md`,
  `architecture.md`, `decision_log.md`, `technology_stack.md`,
  `pending_input.md`, `validation_results.csv`, `README.md`.
- Contexto de tesis: `Code_Euler1D/docs/contexto_tesis.md`.
- Mediciones ejecutadas el 12 de noviembre de 2026 en Windows con MSYS2 UCRT64,
  GCC, build Release, sin `-ffast-math`.
