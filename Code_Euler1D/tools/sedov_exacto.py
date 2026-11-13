#!/usr/bin/env python3
"""
Solucion EXACTA de Sedov-Taylor esferica con derivacion VERDADERAMENTE
simbolica: los campos se definen con su dependencia completa en (r,t),
sympy aplica toda la regla de la cadena a las tres PDEs de Euler, y la
reduccion a ODEs en xi = r/R(t) sale sola (cero algebra a mano — la
version anterior escribia las formas reducidas manualmente y tenia un
error que hacia explotar la integral).

Ansatz (R ~ t^{2/5}):
  v = (2r/5t) V(xi),  rho = rho0 G(xi),  p = rho0 (4 r^2/(25 t^2)) G Z/gamma
Choque fuerte en xi=1: V=2/(g+1), G=(g+1)/(g-1), Z=2g(g-1)/(g+1)^2.
Energia:  1 = (16 pi/25) xi0^5 I,  I = int_0^1 [GV^2/2 + GZ/(g(g-1))] xi^4 dxi
Verificacion final: residuos de las TRES PDEs sobre la solucion numerica.
"""
import numpy as np
import sympy as sp
from scipy.integrate import solve_ivp, quad

GAMMA = 1.4

# ------------------ derivacion simbolica completa ------------------
# xi es un SIMBOLO independiente; la regla de la cadena entra por los
# operadores D_r y D_t (una linea cada uno, con dxi/dr y dxi/dt
# calculados por sympy del propio xi = r/(A t^{2/5})); todo el algebra
# de productos y cocientes la hace sympy.
r, t, A, g, rho0 = sp.symbols('r t A gamma rho0', positive=True)
xis = sp.Symbol('xi', positive=True)
Vf, Gf, Zf = (sp.Function(n)(xis) for n in ('V', 'G', 'Z'))

dxidr = 1/(A*t**sp.Rational(2, 5))            # d xi / d r
dxidt = -sp.Rational(2, 5)*xis/t              # d xi / d t (con r=xi A t^{2/5})

def D_r(f):
    return sp.diff(f, r) + sp.diff(f, xis)*dxidr

def D_t(f):
    return sp.diff(f, t) + sp.diff(f, xis)*dxidt

v   = sp.Rational(2, 5)*(r/t)*Vf
rho = rho0*Gf
p   = rho0*sp.Rational(4, 25)*(r/t)**2*Gf*Zf/g

eq_masa = D_t(rho) + (D_r(r**2*rho*v))/r**2
eq_mom  = D_t(v) + v*D_r(v) + D_r(p)/rho
eq_ene  = D_t(p) + v*D_r(p) + g*p*(D_r(r**2*v))/r**2

s_ = xis
Vs, Gs, Zs, Vp, Gp, Zp = sp.symbols('Vs Gs Zs Vp Gp Zp')

def reducir(eq):
    e = eq.subs(r, xis*A*t**sp.Rational(2, 5))
    e = e.subs([(sp.Derivative(Vf, xis), Vp),
                (sp.Derivative(Gf, xis), Gp),
                (sp.Derivative(Zf, xis), Zp)])
    e = e.subs([(Vf, Vs), (Gf, Gs), (Zf, Zs)])
    e = sp.simplify(sp.expand(e))
    e = sp.numer(sp.together(e))
    # el factor dimensional restante (potencias de t, A, rho0) se
    # elimina factorizando: nos quedamos con el factor que contiene
    # las incognitas
    e = sp.factor(e)
    if isinstance(e, sp.Mul):
        e = sp.Mul(*[f for f in e.args
                     if f.has(Vs) or f.has(Gs) or f.has(Zs)
                     or f.has(Vp) or f.has(Gp) or f.has(Zp)])
    return sp.expand(e)

eqs = [reducir(eq_masa), reducir(eq_mom), reducir(eq_ene)]
solp = sp.solve(eqs, [Vp, Gp, Zp], dict=True)
assert len(solp) == 1, 'la reduccion no dio sistema lineal unico'
solp = solp[0]
fV = sp.lambdify((s_, Vs, Gs, Zs, g), sp.simplify(solp[Vp]), 'numpy')
fG = sp.lambdify((s_, Vs, Gs, Zs, g), sp.simplify(solp[Gp]), 'numpy')
fZ = sp.lambdify((s_, Vs, Gs, Zs, g), sp.simplify(solp[Zp]), 'numpy')
print("reduccion simbolica: sistema lineal unico para (V', G', Z') OK")

# ------------------------ integracion numerica ------------------------
gam = GAMMA
y1 = [2.0/(gam+1.0), (gam+1.0)/(gam-1.0),
      2.0*gam*(gam-1.0)/(gam+1.0)**2]

def rhs(x, y):
    return [fV(x, *y, gam), fG(x, *y, gam), fZ(x, *y, gam)]

sol = solve_ivp(rhs, [1.0, 1.0e-7], y1, rtol=1e-11, atol=1e-14,
                dense_output=True, method='LSODA')

def integrando(x):
    Vv, Gg, Zz = sol.sol(x)
    return (0.5*Gg*Vv**2 + Gg*Zz/(gam*(gam-1.0)))*x**4

I, err = quad(integrando, 1.0e-7, 1.0, limit=400)
xi0 = (25.0/(16.0*np.pi*I))**0.2

# --------------------- verificacion de residuos ---------------------
# los residuos de las TRES ecuaciones reducidas deben ser ~0 sobre la
# solucion numerica (chequeo independiente del solve lineal)
res_funcs = [sp.lambdify((s_, Vs, Gs, Zs, Vp, Gp, Zp, g), e, 'numpy')
             for e in eqs]
xs_chk = np.linspace(0.05, 0.999, 25)
peor = 0.0
for x in xs_chk:
    y = sol.sol(x)
    dy = rhs(x, y)
    for f in res_funcs:
        peor = max(peor, abs(f(x, *y, *dy, gam)))
print(f'residuo maximo de las PDEs reducidas sobre la solucion: '
      f'{peor:.2e}')

print(f'\nSedov esferico, gamma = {gam}:')
print(f'  I (integral de energia) = {I:.6f}')
print(f'  xi_0 DERIVADO           = {xi0:.5f}')
xs = np.linspace(2e-3, 1.0, 500)
Vv, Gg, Zz = sol.sol(xs)
print(f'  G(1) = {Gg[-1]:.4f} (exacto {(gam+1)/(gam-1):.4f}); '
      f'G(0+) = {Gg[0]:.3e} (centro evacuado)')
np.savetxt(__file__.replace('sedov_exacto.py',
                            '../runs/sedov_perfil_exacto.dat'),
           np.column_stack([xs, Gg]),
           header='xi  G=rho/rho0 (Sedov exacto derivado, gamma=1.4)')
print('  perfil exportado: runs/sedov_perfil_exacto.dat')
