# Tabla de fases metodológicas

| Fase | Objetivo | Actividades | Entradas | Técnicas | Entregable | Criterio de cierre | Evidencia | Depende de | OE |
|---|---|---|---|---|---|---|---|---|---|
| 0 | Alcance real | Auditoría código/plan | Repo, ZIP | Inspección | Este expediente | Lista IMPLEMENTED/PROPOSED | `00_auditoria.md` | — | todos |
| 1 | Literatura y requisitos | Lectura dirigida | Toro, LeVeque, Mandli, Oberkampf | Revisión **no** sistemática | Cap. estado del arte | Citas del `.bib` resuelven | `01_`, `03_` | 0 | 1, 4 |
| 2 | Arquitectura | Diagramas = código | `include/euler1d` | Diseño | Diagrama de componentes | Un revisor localiza HLLC | docs arquitectura | 1 | 1 |
| 3 | Núcleo | Mantener 1D; extender solo lo aprobado | Fortran, tests | TDD existente | `xEuler1D` | CTest/regresión verde | logs de test | 2 | 2 |
| 4 | Interfaz | CLI + prototipo GUI | Namelist, `.xl` | Subproceso, no pybind | Laboratorio | Toro 1 igual por CLI y GUI | `fvlab_lab` | 3 | 2, 4 |
| 5 | V&V | Exacto, L1/L2, refino | Casos Toro | Oberkampf–Roy | Tablas | Criterios provisionales del director | `tests/`, `.xl` | 3–4 | 3 |
| 6 | Educación | Lista de comprobación | GUI, docs | Inspección; **sin** encuesta ficticia | Informe de inspección | RN-10–13 o recorte OE4 | acta | 4–5 | 4 |
| 7 | Memoria | Manuales, repo limpio | Todo | Reproducir desde cero | TG escrito | Tercero corre un caso | Git tag | 5–6 | 4 |
