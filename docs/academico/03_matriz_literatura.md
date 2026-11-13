# Matriz de literatura

Solo fuentes usadas en los capítulos revisados o en el `referencias.bib` del ZIP. No se listan artículos no leídos.

| Clave | Tipo | Contribución | Relevancia al TG | Afirmaciones que sostiene | Limitación |
|---|---|---|---|---|---|
| toro2009 | Libro | Riemann, HLL/HLLC, FVM, tests 1D | Base numérica | Familia HLL vs HLLC; exacto como referencia | No evalúa OpenFOAM |
| leveque2002 | Libro | FVM para hiperbólicas | Discretización conservativa | Problema de Riemann local | Poco software industrial |
| hirsch2007 | Libro | CFD, CFL, captura de choques | Fundamento | Necesidad de esquemas conservativos | Tratado general |
| liska2003 | Artículo SIAM J. Sci. Comput. | Comparación de esquemas Euler 1D/2D | Banco de pruebas | Ningún esquema gana en todos los casos | No es un *framework* educativo |
| mandli2016 | Artículo PeerJ CS | Ecosistema Clawpack | Contraejemplo al hueco ingenuo | Riemann intercambiable; Fortran vs PyClaw | No es C++ UIS |
| weller1998 | Artículo | OO en mecánica de continuos | Origen OpenFOAM | Arquitectura orientada a objetos | Época previa a OpenFOAM moderno |
| jasak2009 | Artículo | OpenFOAM investigación/industria | Software maduro | Código abierto de producción | No mide curva de aprendizaje |
| economon2016 | Artículo AIAA J. | SU2 | Software maduro de diseño | Alcance ingeniería, no laboratorio 1D | No pedagógico |
| stone2020 | Artículo ApJS | Athena++ AMR/MHD | Software experto | No es el público del TG | Fuera de Euler didáctico |
| wilson2014 | Artículo PLoS Biol. | Buenas prácticas software científico | Metodología | Git, tests, no scripts opacos | No CFD específico |
| ramakrishnan2017 | Congreso IEEE | Usabilidad de software científico | OE4 | Documentar para no expertos del dominio | No numérico |
| mesnard2017 | Artículo CiSE | Reproducibilidad en CFD | Justificación | Código público no basta | Relato de caso |
| oberkampf2010 | Libro | V&V | Vocabulario OE3 | Verificación ≠ validación | No implementa solvers |

**Documentación (no biblatex):** Clawpack Riemann docs (`clawpack.org/riemann.html`, `pyclaw/rp.html`). Sostienen HLL/HLLC en PyClaw y la interfaz común.

**Claves rotas en el `main.tex` del ZIP (no usar hasta añadirlas al `.bib`):** `raman2018review`, `toro2013riemann`.
