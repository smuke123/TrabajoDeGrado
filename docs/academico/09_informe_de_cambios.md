# Informe de cambios (estado del arte y metodología)

## Qué se creó

Carpeta `docs/academico/` (no se reescribió el núcleo C++ ni los tests numéricos).

| Archivo | Rol |
|---|---|
| `00_auditoria.md` | Etapa 1: inventario, clasificaciones, trazabilidad |
| `01_estado_del_arte.md` | Capítulo crítico (reemplazo intelectual del «marco» tipo manual) |
| `02_metodologia.md` | Investigación + ciclo software + V&V + educación |
| `03_matriz_literatura.md` | Fuentes y afirmaciones |
| `04_matriz_software.md` | Comparación de herramientas |
| `05_trazabilidad_requisitos.md` | RN → OE → pruebas |
| `06_fases_metodologia.md` | Tabla de fases |
| `07_plan_VV.md` | Verificación vs validación |
| `08_decisiones_director.md` | Bloqueos académicos |
| `10_capitulos_overleaf.tex` | Fragmento para pegar en Overleaf |
| `referencias_academico.bib` | Igual al ZIP + nota; sin claves inventadas |

El `main.tex` del ZIP **no se sobreescribió** (es el original del equipo). Los capítulos nuevos son la revisión propuesta.

## Mejoras principales

- El estado del arte deja de ser un recetario de MUSCL/HLL y admite que **Clawpack ya intercambia Riemann**.  
- El hueco se formula como laboratorio compacto + transparencia, no como «nadie puede cambiar HLLC».  
- La metodología deja de llamar validación física al tubo de Sod.  
- Se alinea el texto con el código: HLL-Davis + HLLC IMPLEMENTED; HLLE/WENO/2D/JSON PROPOSED.  
- Se eliminan del argumento las citas rotas `raman2018review` y `toro2013riemann` (siguen en el ZIP `main.tex` hasta que el equipo las borre o las añada al `.bib`).

## Por qué no se pegó aún encima del marco del plan

El usuario pidió no destruir material y el ZIP es su copia de radicación. Integrar `10_capitulos_overleaf.tex` es un paso explícito de Overleaf.

## Preparación

**Lista para revisión del director**, con salvedad: hace falta su fallo en la lista `08_`. Sin eso, el documento de grado aún **requiere revisión menor a sustancial** en pregunta vs OE vs Gantt.
