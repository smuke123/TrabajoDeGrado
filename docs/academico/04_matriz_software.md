# Matriz comparativa de software (ampliada)

Criterios justificados por la pregunta y los OE: (C1) Euler FVM; (C2) cambiar Riemann; (C3) compactez / curva de entrada; (C4) traza ecuación–código; (C5) verificación 1D con exacto; (C6) 2D/producción; (C7) doc. pedagógica en el sentido del TG.

| Herramienta | C1 | C2 | C3 | C4 | C5 | C6 | C7 | Base de la celda |
|---|---|---|---|---|---|---|---|---|
| OpenFOAM | Sí | Parcial (código grande) | No | No | Posible, no foco | Sí | No | Weller et al., 1998; Jasak, 2009 |
| SU2 | Sí | Parcial | No | No | Posible, no foco | Sí | No | Economon et al., 2016 |
| Clawpack/PyClaw | Sí | Sí (PyClaw runtime; Fortran compile) | Media | Docs fuertes, no GUI UIS | Sí (solvers Python) | Sí | No en español/Sistemas | Mandli et al., 2016; docs Clawpack |
| Athena++ | Sí+ | Experto | No | No | — | Sí AMR | No | Stone et al., 2020 |
| Fluent | Sí | N/C (cerrado) | N/A comercial | No | — | Sí | No | No se auditó código |
| **Este TG (núcleo 1D)** | Sí 1D | Sí namelist HLL/HLLC | Sí (diseño) | Parcial (prototipo GUI) | Sí | 2D propuesto | Propuesto | Inspección del repositorio |

**Lectura:** C2 no es exclusivo del TG. La combinación C3+C4+C7 sobre un núcleo C++ pequeño es la tesis de diseño, sujeta a evidencia empírica de uso que **aún no existe**.
