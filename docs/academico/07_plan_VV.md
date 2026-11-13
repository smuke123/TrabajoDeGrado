# Plan de verificación y validación

Definiciones: Oberkampf y Roy (2010). El Riemann exacto 1D es **verificación**, no validación experimental.

## Verificación de código

- Tests unitarios de limitadores, HLL, HLLC, EOS, CFL (ya en `tests/`).
- Prohibido modificar expectativas de regresión sin acta.
- El exacto no entra al `applyUpdate`.

## Verificación de solución

- Toro 1–5: perfiles y normas frente al exacto (malla y CFL fijos).
- Entropía periódica: refino; no exigir orden 2 en un choque.
- Conservación: un flujo por cara (invariante de diseño).
- Positividad: Toro 2; registrar pisos.

## Validación

- No hay campaña experimental.
- 2D: comparación con figuras/tablas de literatura **si** existe el solver 2D (Liska y Wendroff, 2003, como batería de referencia conceptual; Lax–Liu / Woodward–Colella solo si se implementan esos casos).

## Regresión

- Archivos `.xl` de referencia; `.gitattributes` binario (decisión ya tomada en el C++).

## Software / GUI

- Namelist desconocido → error.
- GUI solo escribe namelist y lee `.xl`.

## Criterios numéricos

**Provisionales** hasta aprobación: cualquier corrida de demostración debe coincidir con la banda de la suite ya aceptada frente a Fortran. No se publica aquí un ε nuevo sin el director.
