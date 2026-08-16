#!/usr/bin/env python3
"""
Validacion del capitulo de fuentes: Sedov-Taylor esferico contra los
tres numeros exactos de la solucion autosimilar (gamma=1.4):
  - exponente del choque: R_s(t) ~ t^{2/5} (m = 0.400)
  - constancia de xi_0 = R_s / (E0 t^2 / rho0)^{1/5} entre epocas
    (el VALOR exacto de xi_0(gamma) se deriva en la documentacion
    integrando las ODEs autosimilares; aqui se valida que es constante)
  - salto de densidad en el choque fuerte: (gamma+1)/(gamma-1) = 6
Figura: R_s(t) log-log con pendiente 2/5 + perfil rho(r) final.
El balance hidrostatico (test 7) se reporta como numero aparte.
"""
import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

plt.rcParams.update({'font.family': 'serif', 'mathtext.fontset': 'cm',
                     'font.size': 11, 'axes.linewidth': 0.8})

HERE = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(HERE, '..', 'runs')
GAMMA = 1.4
E0, RHO0 = 1.0, 1.0


def blocks(fn):
    bl, cur, ts = [], [], []
    for line in open(fn):
        s = line.strip()
        if not s:
            continue
        if s.startswith('#Time'):
            if cur:
                bl.append(np.array(cur))
                cur = []
            ts.append(float(s.split('=')[1]))
        else:
            q = s.split()
            if len(q) == 2:
                cur.append([float(q[0]), float(q[1])])
    if cur:
        bl.append(np.array(cur))
    return ts, bl


ts, bl = blocks(os.path.join(RUNS, 'sedov', 'rho_1.xl'))

# posicion del choque: ultimo maximo del gradiente de rho
Rs, Ts = [], []
for t, b in zip(ts, bl):
    if t < 0.05:      # epocas muy tempranas: blast aun en pocas celdas
        continue
    r, rho = b[:, 0], b[:, 1]
    i = int(np.argmax(rho))
    Rs.append(r[i])
    Ts.append(t)
Rs, Ts = np.array(Rs), np.array(Ts)

m, lnA = np.polyfit(np.log(Ts), np.log(Rs), 1)
xi0 = Rs/(E0*Ts**2/RHO0)**0.2
rho_max = bl[-1][:, 1].max()
salto = (GAMMA+1.0)/(GAMMA-1.0)

print(f'Sedov esferico (gamma=1.4, N=800):')
print(f'  exponente ajustado  m     = {m:.4f}   (exacto 2/5 = 0.4000)')
print(f'  constante xi_0 (promedio) = {xi0.mean():.4f} ± {xi0.std():.4f}'
      f'   (constancia = autosimilaridad)')
print(f'  salto de densidad max     = {rho_max:.3f}'
      f'   (choque fuerte exacto = {salto:.1f})')

fig, axs = plt.subplots(1, 2, figsize=(9.2, 3.6))
ax = axs[0]
ax.loglog(Ts, Rs, 'o', mfc='none', mec='k', ms=4, label='$R_s$ medido')
tt = np.array([Ts[0], Ts[-1]])
ax.loglog(tt, xi0.mean()*(E0*tt**2/RHO0)**0.2, 'k-', lw=1.0,
          label=r'$\xi_0\,(E_0 t^2/\rho_0)^{1/5}$')
ax.set_xlabel('$t$')
ax.set_ylabel('$R_s$')
ax.legend(frameon=False, fontsize=9)
ax.set_title(f'ajuste: $R_s \\propto t^{{{m:.3f}}}$', fontsize=10)
ax.tick_params(direction='in', top=True, right=True, which='both')

ax = axs[1]
r, rho = bl[-1][:, 0], bl[-1][:, 1]
ax.plot(r, rho, 'k-', lw=1.0)
ax.axhline(salto, color='0.5', lw=0.8, ls='--')
ax.text(0.06, salto*1.02, r'$(\gamma{+}1)/(\gamma{-}1) = 6$',
        fontsize=9, color='0.35')
ax.set_xlabel('$r$')
ax.set_ylabel(r'$\rho$')
ax.set_title(f'perfil a $t={ts[-1]:.2f}$', fontsize=10)
ax.tick_params(direction='in', top=True, right=True)

fig.suptitle('Sedov-Taylor esferico: fuente geometrica '
             r'$\alpha=2$ contra la autosimilar', fontsize=11)
fig.tight_layout()
out = os.path.join(RUNS, 'sedov_validacion.png')
fig.savefig(out, dpi=160)
print(f'figura: {out}')
