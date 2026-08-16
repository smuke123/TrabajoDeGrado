#!/usr/bin/env python3
"""
Estudio de convergencia formal (test 6: onda de entropia suave,
rho = 1 + 0.2 sin 2pi(x-t), u=p=1, periodicas, t_f = 1).
Corre N = 50..1600 para vl, mm y fo; reporta L1(rho), el orden
observado p = log2(L1(N)/L1(2N)) y la figura log-log con la
pendiente 2 de referencia. Estilo casa.
"""
import os
import subprocess
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

plt.rcParams.update({'font.family': 'serif', 'mathtext.fontset': 'cm',
                     'font.size': 11, 'axes.linewidth': 0.8})

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(HERE, '..')
BIN = os.path.join(BASE, 'xEuler1D')
RUNS = os.path.join(BASE, 'runs', 'convergencia')

NS = [50, 100, 200, 400, 800, 1600]
LIMS = ['vl', 'mm', 'fo']


def last_block(fn):
    bl, cur = [], []
    for line in open(fn):
        s = line.strip()
        if not s:
            continue
        if s.startswith('#Time'):
            if cur:
                bl.append(np.array(cur))
                cur = []
        else:
            q = s.split()
            if len(q) == 2:
                cur.append([float(q[0]), float(q[1])])
    if cur:
        bl.append(np.array(cur))
    return bl[-1]


L1 = {lim: [] for lim in LIMS}
for lim in LIMS:
    for N in NS:
        d = os.path.join(RUNS, f'{lim}_N{N}')
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, 'input.par'), 'w') as f:
            f.write(f"&euler\n test = 6\n N = {N}\n cfl = 0.5\n"
                    f" limiter = '{lim}'\n solver = 'hllc'\n/\n")
        subprocess.run([BIN], cwd=d, capture_output=True, check=True)
        num = last_block(os.path.join(d, 'rho_1.xl'))
        ex = last_block(os.path.join(d, 'rho_exact.xl'))
        dx = num[1, 0] - num[0, 0]
        L1[lim].append(dx*np.abs(num[:, 1] - ex[:, 1]).sum())

print('L1(rho) y orden observado p = log2(L1(N)/L1(2N)):')
print(f'{"N":>6s}', end='')
for lim in LIMS:
    print(f'  {"L1("+lim+")":>11s} {"p":>5s}', end='')
print()
for i, N in enumerate(NS):
    print(f'{N:6d}', end='')
    for lim in LIMS:
        if i > 0:
            p = np.log2(L1[lim][i-1]/L1[lim][i])
            print(f'  {L1[lim][i]:11.3e} {p:5.2f}', end='')
        else:
            print(f'  {L1[lim][i]:11.3e} {"--":>5s}', end='')
    print()

fig, ax = plt.subplots(figsize=(4.8, 3.7))
marcas = {'vl': ('o', '-', 'van Leer'), 'mm': ('s', '--', 'minmod'),
          'fo': ('^', ':', '1er orden')}
for lim in LIMS:
    m, ls, lab = marcas[lim]
    ax.loglog(NS, L1[lim], m + ls, mfc='none', color='k', ms=5,
              lw=0.9, label=lab)
# referencias de pendiente
Nref = np.array([NS[0], NS[-1]])
ax.loglog(Nref, L1['vl'][0]*0.7*(Nref/NS[0])**(-2.0), '-',
          color='0.6', lw=0.8)
ax.text(NS[-2], L1['vl'][0]*0.7*(NS[-2]/NS[0])**(-2.0)*1.5,
        r'$N^{-2}$', fontsize=9, color='0.4')
ax.loglog(Nref, L1['fo'][0]*0.7*(Nref/NS[0])**(-1.0), '-',
          color='0.6', lw=0.8)
ax.text(NS[-2], L1['fo'][0]*0.7*(NS[-2]/NS[0])**(-1.0)*1.5,
        r'$N^{-1}$', fontsize=9, color='0.4')
ax.set_xlabel('$N$')
ax.set_ylabel(r'$L_1(\rho)$')
ax.legend(frameon=False, fontsize=9)
ax.tick_params(direction='in', top=True, right=True, which='both')
fig.tight_layout()
out = os.path.join(BASE, 'runs', 'convergencia.png')
fig.savefig(out, dpi=170)
print(f'figura: {out}')
