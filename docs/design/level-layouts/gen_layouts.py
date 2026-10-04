#!/usr/bin/env python3
"""Genera las plantas SVG de PUL-041 y calcula distancias andando sobre la cuadrícula.

Uso: python3 docs/design/level-layouts/gen_layouts.py
Escribe planta-<id>.svg junto a este fichero e imprime la tabla de distancias en Markdown.

Cuadrícula: 16 × 11 celdas de 1 m. Columna c → x = c − 6,8 (centro c − 6,3); fila r → z = r − 4,5.
Encaja en la zona visible de la cámara ortográfica actual (size 12,74, pitch 38°, x 0,7).
"""

from __future__ import annotations

import heapq
import math
from pathlib import Path

OUT = Path(__file__).resolve().parent

X0 = -6.8  # x del borde izquierdo de la columna 0 (0,4 m libres a la derecha del HUD)
Z0 = -4.5  # z del borde trasero de la fila 0

# Zona visible de la cámara actual sobre el suelo (y = 0), calculada desde camera_rig.tscn.
VIEW_X = (-10.6, 12.0)
VIEW_Z = (-14.1, 6.6)
TICKETS_Z = -6.8  # por encima (z menor) tapan los tickets de comanda
HUD = (-10.6, -7.2, -0.1, 6.0)  # x0, x1, z0, z1 del panel de tiempo/recaudación

LEGEND: dict[str, tuple[str, str]] = {
    "N": ("Nevera (pulpo crudo)", "#9ec9e8"),
    "K": ("Cachelera (cachelos crudos)", "#e8d27a"),
    "O": ("Olla / fogón (2 plazas)", "#6b6b6b"),
    "B": ("Estantería de cajas", "#c8875a"),
    "T": ("Mesa de corte (se deja la caja)", "#b5c99a"),
    "C": ("Estación de condimentos (D18)", "#d9534f"),
    "=": ("Pasaplatos (mesa de apoyo a dos caras)", "#b39ddb"),
    "#": ("Mesa de apoyo / barra", "#d2a46c"),
    "X": ("Obstáculo (mástil, barriles)", "#7a5c3a"),
    "1": ("Puesto de entrega 1", "#ffffff"),
    "2": ("Puesto de entrega 2", "#ffffff"),
    "3": ("Puesto de entrega 3", "#ffffff"),
    "4": ("Puesto de entrega 4", "#ffffff"),
    "a": ("Salida J1", "#ffd84d"),
    "b": ("Salida J2", "#4dd2ff"),
}
WALKABLE = set(".ab")

LAYOUTS: dict[str, dict] = {
    "a": {
        "title": "A · Carpa en U con isla",
        "grid": [
            "##NK#OO####BB###",
            "#..............#",
            "#..............#",
            "#..............#",
            "#.....TTCC.....#",
            "#..............#",
            "#.b..........a.#",
            "#..............#",
            "#..............#",
            "#..............#",
            "###1#2##3#4#####",
        ],
        "cut": "T",
    },
    "b": {
        "title": "B · Barra partida (cocina | servicio)",
        "grid": [
            "##NK#O#O########",
            "#..............#",
            "#.b............#",
            "#..............#",
            "#=====CC======.#",
            "#..............#",
            "B..............#",
            "B..........a...#",
            "#..............#",
            "#..............#",
            "###1#2##3#4#####",
        ],
        "cut": "=",
    },
    "c": {
        "title": "C · Dos pulpeiras en espejo",
        "grid": [
            "##BB###NK###BB##",
            "#..............#",
            "O..............O",
            "#..............#",
            "#......CC......#",
            "T......CC......T",
            "T.b..........a.T",
            "#..............#",
            "#......XX......#",
            "#......XX......#",
            "##1#2######3#4##",
        ],
        "cut": "T",
    },
}

CELL = 40  # px por metro en el SVG


def cells(grid: list[str], ch: str) -> list[tuple[int, int]]:
    return [(r, c) for r, row in enumerate(grid) for c, v in enumerate(row) if v == ch]


def access(grid: list[str], targets: list[tuple[int, int]]) -> set[tuple[int, int]]:
    """Celdas pisables 4-vecinas de una estación: desde ahí se interactúa."""
    out: set[tuple[int, int]] = set()
    for r, c in targets:
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            rr, cc = r + dr, c + dc
            if 0 <= rr < len(grid) and 0 <= cc < len(grid[0]) and grid[rr][cc] in WALKABLE:
                out.add((rr, cc))
    return out


def dijkstra(grid: list[str], sources: set[tuple[int, int]]) -> dict[tuple[int, int], float]:
    """8-conexa, diagonal √2, sin cortar esquinas."""
    dist = {s: 0.0 for s in sources}
    heap = [(0.0, s) for s in sources]
    while heap:
        d, (r, c) = heapq.heappop(heap)
        if d > dist[(r, c)]:
            continue
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                if dr == dc == 0:
                    continue
                rr, cc = r + dr, c + dc
                if not (0 <= rr < len(grid) and 0 <= cc < len(grid[0])):
                    continue
                if grid[rr][cc] not in WALKABLE:
                    continue
                if dr and dc and (grid[r][cc] not in WALKABLE or grid[rr][c] not in WALKABLE):
                    continue
                nd = d + (math.sqrt(2) if dr and dc else 1.0)
                if nd < dist.get((rr, cc), math.inf):
                    dist[(rr, cc)] = nd
                    heapq.heappush(heap, (nd, (rr, cc)))
    return dist


def dijkstra_from(grid: list[str], start: dict[tuple[int, int], float]) -> dict[tuple[int, int], float]:
    """Como dijkstra() pero con distancia inicial por celda (para encadenar tramos)."""
    best: dict[tuple[int, int], float] = {}
    for cell, d0 in start.items():
        for k, v in dijkstra(grid, {cell}).items():
            if d0 + v < best.get(k, math.inf):
                best[k] = d0 + v
    return best


def chain(grid: list[str], start: str, stops: list[str]) -> float:
    """Recorrido más corto que sale de la estación start y visita stops en orden.

    Un jugador real no atraviesa mostradores: el camino respeta en qué cara se queda.
    """
    cur = {p: 0.0 for p in access(grid, cells(grid, start))}
    for stop in stops:
        reach = dijkstra_from(grid, cur)
        cur = {p: reach[p] for p in access(grid, cells(grid, stop)) if p in reach}
    return min(cur.values())


def dist_between(grid: list[str], a: str, b: str) -> float:
    """Distancia mínima andando entre las caras de dos estaciones (cualquier celda de cada una)."""
    da = dijkstra(grid, access(grid, cells(grid, a)))
    return min(da.get(p, math.inf) for p in access(grid, cells(grid, b)))


def stand_dists(grid: list[str], src: str) -> list[float]:
    da = dijkstra(grid, access(grid, cells(grid, src)))
    return [min(da.get(p, math.inf) for p in access(grid, cells(grid, s))) for s in "1234"]


def render_svg(lid: str, spec: dict) -> str:
    grid: list[str] = spec["grid"]
    vx0, vx1 = VIEW_X
    vz0, vz1 = TICKETS_Z, VIEW_Z[1]
    pad = 20
    legend_w = 300
    w = (vx1 - vx0) * CELL + 2 * pad + legend_w
    h = (vz1 - vz0) * CELL + 2 * pad + 30

    def px(x: float) -> float:
        return pad + (x - vx0) * CELL

    def pz(z: float) -> float:
        return pad + 30 + (z - vz0) * CELL

    o: list[str] = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{h:.0f}" '
        f'font-family="sans-serif" font-size="13">',
        f'<rect width="{w:.0f}" height="{h:.0f}" fill="#ffffff"/>',
        f'<text x="{pad}" y="{pad + 8}" font-size="18" font-weight="bold">{spec["title"]}</text>',
        # Encuadre visible bajo la banda de tickets.
        f'<rect x="{px(vx0)}" y="{pz(vz0)}" width="{(vx1 - vx0) * CELL}" '
        f'height="{(vz1 - vz0) * CELL}" fill="#dfe6b8" stroke="#555" stroke-dasharray="6 4"/>',
        f'<text x="{px(vx0) + 6}" y="{pz(vz0) + 16}" fill="#555">encuadre de la cámara '
        f"(debajo de la banda de tickets)</text>",
    ]
    hx0, hx1, hz0, hz1 = HUD
    o.append(
        f'<rect x="{px(hx0)}" y="{pz(hz0)}" width="{(hx1 - hx0) * CELL}" height="{(hz1 - hz0) * CELL}" '
        f'fill="#263238" opacity="0.85"/><text x="{px(hx0) + 6}" y="{pz(hz0) + 18}" fill="#fff">HUD</text>'
    )
    for r, row in enumerate(grid):
        for c, ch in enumerate(row):
            x, y = px(X0 + c), pz(Z0 + r)
            if ch in WALKABLE:
                fill = "#f4f1e6"
            else:
                fill = LEGEND[ch][1]
            o.append(
                f'<rect x="{x}" y="{y}" width="{CELL}" height="{CELL}" fill="{fill}" '
                f'stroke="#999" stroke-width="0.5"/>'
            )
            if ch not in ".#":
                if ch in "ab":
                    o.append(
                        f'<circle cx="{x + CELL / 2}" cy="{y + CELL / 2}" r="{CELL * 0.35}" '
                        f'fill="{LEGEND[ch][1]}" stroke="#333"/>'
                    )
                label = {"a": "J1", "b": "J2"}.get(ch, ch)
                color = "#fff" if ch in "OCX" else "#000"
                o.append(
                    f'<text x="{x + CELL / 2}" y="{y + CELL / 2 + 5}" text-anchor="middle" '
                    f'font-weight="bold" font-size="15" fill="{color}">{label}</text>'
                )
    # Escala y ejes.
    for c in range(len(grid[0]) + 1):
        if c % 2 == 0:
            o.append(
                f'<text x="{px(X0 + c)}" y="{pz(Z0 + len(grid)) + 14}" text-anchor="middle" '
                f'font-size="10" fill="#555">{X0 + c:+.1f}</text>'
            )
    for r in range(len(grid) + 1):
        if r % 2 == 0:
            o.append(
                f'<text x="{px(X0 + len(grid[0])) + 4}" y="{pz(Z0 + r) + 4}" font-size="10" '
                f'fill="#555">z {Z0 + r:+.1f}</text>'
            )
    # Leyenda.
    lx = px(vx1) + 16
    ly = pz(vz0) + 4
    used = {ch for row in grid for ch in row} - {"."}
    order = [k for k in LEGEND if k in used and k not in "234"]
    for i, k in enumerate(order):
        name, fill = LEGEND[k]
        if k == "1":
            name = "Puestos de entrega 1–4"
        yy = ly + i * 24
        o.append(f'<rect x="{lx}" y="{yy}" width="18" height="18" fill="{fill}" stroke="#333"/>')
        o.append(f'<text x="{lx + 26}" y="{yy + 14}">{name}</text>')
    o.append(f'<text x="{lx}" y="{ly + len(order) * 24 + 16}" font-size="11" fill="#555">'
             "1 celda = 1 m · arriba = fondo (z−)</text>")
    sy = ly + len(order) * 24 + 44
    o.append(f'<line x1="{lx}" y1="{sy}" x2="{lx + 2 * CELL}" y2="{sy}" stroke="#000" stroke-width="3"/>')
    o.append(f'<text x="{lx + 2 * CELL + 8}" y="{sy + 4}" font-size="11">2 m = 0,4 s a 5 m/s</text>')
    o.append("</svg>")
    return "\n".join(o)


def main() -> None:
    for lid, spec in LAYOUTS.items():
        (OUT / f"planta-{lid}.svg").write_text(render_svg(lid, spec), encoding="utf-8")

    def sub(spec: dict, seq: list[str]) -> list[str]:
        return [spec["cut"] if x == "cut" else x for x in seq]

    segs = [
        ("Cajas → mesa de corte", "B", "cut"),
        ("Nevera → olla", "N", "O"),
        ("Cachelera → olla", "K", "O"),
        ("Olla → mesa de corte", "O", "cut"),
        ("Mesa de corte → condimentos", "cut", "C"),
        ("Olla → condimentos (cachelos)", "O", "C"),
    ]
    rows: list[tuple[str, list[str]]] = []
    for name, a, b in segs:
        vals = []
        for spec in LAYOUTS.values():
            aa, bb = sub(spec, [a, b])
            vals.append(f"{chain(spec['grid'], aa, [bb]):.1f}")
        rows.append((name, vals))
    rows.append(
        (
            "Condimentos → puestos 1/2/3/4",
            ["/".join(f"{chain(s['grid'], 'C', [k]):.0f}" for k in "1234") for s in LAYOUTS.values()],
        )
    )
    spawn = []
    for spec in LAYOUTS.values():
        g = spec["grid"]
        d = dijkstra(g, set(cells(g, "b")))
        spawn.append(f"{d[cells(g, 'a')[0]]:.1f}")
    rows.append(("Salida J2 → salida J1 (cruzar la cocina)", spawn))

    def avg_stands(spec: dict, seq_for: object) -> float:
        return sum(seq_for(k) for k in "1234") / 4  # type: ignore[operator]

    solo, cook, serve = [], [], []
    for spec in LAYOUTS.values():
        g = spec["grid"]
        solo.append(
            avg_stands(spec, lambda k, s=spec, g=g: chain(g, k, sub(s, ["B", "cut", "N", "O", "cut", "C", k])))
        )
        cook.append(chain(g, "N", sub(spec, ["O", "cut", "N"])))
        serve.append(avg_stands(spec, lambda k, s=spec, g=g: chain(g, "B", sub(s, ["cut", "C", k, "B"]))))
    rows.append(("**Pedido completo, 1 jugador (m)**", [f"**{v:.0f}** ({v / 5:.1f} s)" for v in solo]))
    rows.append(("Bucle cocinero: nevera → olla → corte → nevera (m)", [f"{v:.0f}" for v in cook]))
    rows.append(("Bucle emplatador: cajas → corte → condimentos → puesto → cajas (m)", [f"{v:.0f}" for v in serve]))

    print("| Tramo (m, 1 celda = 1 m, 5 m/s) | " + " | ".join(k.upper() for k in LAYOUTS) + " |")
    print("|---|" + "---:|" * len(LAYOUTS))
    for name, vals in rows:
        print(f"| {name} | " + " | ".join(vals) + " |")


if __name__ == "__main__":
    main()
