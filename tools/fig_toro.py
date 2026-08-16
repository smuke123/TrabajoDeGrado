#!/usr/bin/env python3
"""
Figura de validacion de la suite de Toro: numerica (puntos) contra el
solver de Riemann exacto (linea), con errores L1 = dx*sum|num-ex| por
variable. Estilo de la casa: serif + cm, B/N, marcadores abiertos.
Uso: python3 fig_toro.py   (desde tools/; espera runs/toro1..5)
"""
import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

plt.rcParams.update({'font.family': 'serif', 'mathtext.fontset': 'cm',
                     'font.size': 10, 'axes.linewidth': 0.8})

HERE = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(HERE, '..', 'runs')


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


tests = ['toro1', 'toro2', 'toro3', 'toro4', 'toro5']
vars_ = [('rho', r'$\rho$'), ('vel', r'$u$'), ('press', r'$p$')]

fig, axs = plt.subplots(3, 5, figsize=(16, 7.5), sharex='col')
print('Errores L1 (dx * sum |num - exacta|):')
for col, tn in enumerate(tests):
    d = os.path.join(RUNS, tn)
    if not os.path.isdir(d):
        continue
    l1s = []
    for row, (v, lab) in enumerate(vars_):
        num = last_block(os.path.join(d, f'{v}_1.xl'))
        ex = last_block(os.path.join(d, f'{v}_exact.xl'))
        dx = num[1, 0] - num[0, 0]
        l1 = dx*np.abs(num[:, 1] - ex[:, 1]).sum()
        l1s.append(l1)
        ax = axs[row, col]
        ax.plot(ex[:, 0], ex[:, 1], 'k-', lw=1.1, label='exacta')
        ax.plot(num[::4, 0], num[::4, 1], 'o', mfc='none', mec='k',
                ms=3, label='HLLC+vl')
        ax.tick_params(direction='in', top=True, right=True)
        if col == 0:
            ax.set_ylabel(lab, fontsize=12)
        if row == 0:
            ax.set_title(f'Test {tn[-1]}', fontsize=11)
            if col == 0:
                ax.legend(frameon=False, fontsize=8)
        if row == 2:
            ax.set_xlabel('$x$')
    print(f'  {tn}:  L1(rho)={l1s[0]:.3e}  L1(u)={l1s[1]:.3e}  '
          f'L1(p)={l1s[2]:.3e}')
fig.suptitle('Euler 1D clasico: suite de Toro, HLLC + van Leer, '
             'N=400, CFL=0.9', fontsize=12)
fig.tight_layout()
out = os.path.join(RUNS, 'suite_toro.png')
fig.savefig(out, dpi=150)
print(f'figura: {out}')
