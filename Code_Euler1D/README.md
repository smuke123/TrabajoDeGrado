# Code_Euler1D — CFD clásico en volúmenes finitos

Euler 1D compresible (gas ideal), tipo Godunov. Espejo clásico de la
arquitectura de los códigos RRHD del proyecto:

- Reconstrucción MUSCL con limitadores `fo|mm|vl|mc|sb`
- Solvers de Riemann `hll|hllc` (Toro cap. 10)
- **Solver de Riemann EXACTO** (Toro cap. 4) integrado como referencia
- SSP-RK2, dt adaptativo por CFL, fronteras transmisivas
- Suite de validación: tests 1–5 de Toro (Tabla 4.1) con L1 vs exacta

## Uso
```
make euler
# editar input.par (test, N, cfl, limiter, solver) y correr:
./xEuler1D
# suite completa + figura:
cd tools && python3 fig_toro.py
```

Valores estrella verificados contra Toro (Tabla 4.3 / §4.3.3):
test1 0.46629/1.36091 · test2 0.0018939/0 · test3 460.894/19.5975 ·
test4 1691.65/8.68977 · test5 460.894/~0.
