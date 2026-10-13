#!/usr/bin/env python3
"""PUL-164: tablas de balance a partir de los JSON del bot (`godot/tests/tools/balance_measure.gd`).

Uso (desde la raíz): python3 docs/evidence/PUL-164/balance_tables.py
Escribe `tables.md` y `summary.json` en esta carpeta. Los valores actuales se leen de los `.tres`
(no se copian a mano) y la propuesta se re-puntúa sobre los registros de las partidas del bot.
"""

import json
import re
import statistics
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DATA = ROOT / "godot" / "data"
SLACK_FLAG = 5.0
RECIPES = ["Á feira", "Picante", "Con cachelos", "Bravo cachelos"]
ORDER_FILES = {
    "Á feira": "a_feira",
    "Picante": "picante",
    "Con cachelos": "con_cachelos",
    "Bravo cachelos": "bravo_cachelos",
}
MODES = {"solo": "Individual", "coop": "Local 2P"}

# Propuesta (AC3). Se presenta al gate G2; no se aplica a los .tres (la aplica PUL-166).
PROPOSAL = {
    "thresholds": {"Individual": [40, 90, 140], "Local 2P": [130, 300, 490]},
    "multipliers": [1.0, 0.85, 0.8],
    "phase_starts_s": [0, 90, 180],
    "prices": {"Á feira": 8, "Picante": 9, "Con cachelos": 12, "Bravo cachelos": 13},
    "presses_to_fill": 6,
}
# Fracciones del bot para estimar a un jugador humano (cota: el bot no duda y pulsa cada 4 frames).
HUMAN_SHARES = [0.3, 0.5, 0.75]


def num(text: str, key: str) -> float:
    return float(re.search(rf"^{key} = ([0-9.]+)", text, re.M).group(1))


def current_values() -> dict:
    cfg = (DATA / "config" / "round_config.tres").read_text()
    phases = []
    starts = [float(x) for x in re.findall(r"start_fraction = ([0-9.]+)", cfg)]
    mults = [float(x) for x in re.findall(r"patience_multiplier = ([0-9.]+)", cfg)]
    slots = [int(x) for x in re.findall(r"active_slots = ([0-9]+)", cfg)]
    ids = dict(re.findall(r'path="res://data/orders/(\w+)\.tres" id="(\w+)"', cfg))
    by_id = {v: k for k, v in ids.items()}
    names = {v: k for k, v in ORDER_FILES.items()}
    for i, block in enumerate(re.findall(r"^orders = \[(.*?)\]$", cfg, re.M)):
        refs = re.findall(r'ExtResource\("(\w+)"\)', block)
        phases.append(
            {
                "phase": i + 1,
                "start_s": round(starts[i] * num(cfg, "duration")),
                "slots": slots[i],
                "multiplier": mults[i],
                "orders": [names[by_id[r]] for r in refs],
            }
        )
    orders = {}
    for name, stem in ORDER_FILES.items():
        order = (DATA / "orders" / f"{stem}.tres").read_text()
        recipe = (DATA / "recipes" / f"{stem}.tres").read_text()
        orders[name] = {
            "max_time": num(order, "max_time"),
            "price": int(num(recipe, "base_points")),
        }
    thresholds = [int(x) for x in re.search(r"revenue_thresholds = Array\[int\]\(\[(.*?)\]\)", cfg).group(1).split(",")]
    box = (DATA / "boxes" / "box.tres").read_text()
    return {
        "duration": num(cfg, "duration"),
        "time_bonus_max": int(num(cfg, "time_bonus_max")),
        "expire_penalty": int(num(cfg, "expire_penalty")),
        "thresholds": thresholds,
        "phases": phases,
        "orders": orders,
        "presses_to_fill": int(num(box, "presses_to_fill")),
    }


def stars(revenue: int, thresholds: list) -> int:
    return sum(1 for t in thresholds if revenue >= t)


def load(pattern: str) -> list:
    out = []
    for path in sorted(HERE.glob(pattern)):
        for entry in json.loads(path.read_text()):
            entry["_file"] = path.name
            out.append(entry)
    return out


def fmt(x: float) -> str:
    return f"{x:.1f}".replace(".", ",")


def recipe_table(cur: dict, recipes: list) -> tuple:
    """AC1: tiempo del bot, paciencia y holgura por receta, fase y modo."""
    rows, data = [], []
    for entry in recipes:
        mode = entry["mode"]
        name = entry["kind"]
        times = {o["from"]: o["seconds"] for o in entry["orders"] if o["completed"]}
        for phase in cur["phases"]:
            if name not in phase["orders"]:
                continue
            patience = cur["orders"][name]["max_time"] * phase["multiplier"]
            rec = {
                "mode": MODES[mode],
                "slots": entry["slots"],
                "recipe": name,
                "phase": phase["phase"],
                "patience_s": round(patience, 2),
            }
            for key in ("cero", "flujo"):
                bot = times.get(key)
                rec[f"bot_{key}_s"] = bot
                rec[f"slack_{key}_s"] = None if bot is None else round(patience - bot, 2)
                rec[f"flag_{key}"] = bot is not None and patience - bot < SLACK_FLAG
            data.append(rec)
            mark = lambda k: (" ⚠" if rec[f"flag_{k}"] else "")
            rows.append(
                f"| {rec['mode']} | {entry['slots']} | {name} | {phase['phase']} | {fmt(patience)} | "
                f"{fmt(rec['bot_cero_s'])} | **{fmt(rec['slack_cero_s'])}**{mark('cero')} | "
                f"{fmt(rec['bot_flujo_s'])} | **{fmt(rec['slack_flujo_s'])}**{mark('flujo')} |"
            )
    head = (
        "| Modo | Pasaplatos caja/sobrante | Receta | Fase | Paciencia (s) | Bot desde cero (s) | "
        "Holgura cero (s) | Bot en flujo (s) | Holgura flujo (s) |\n"
        "|---|---|---|---:|---:|---:|---:|---:|---:|"
    )
    return head + "\n" + "\n".join(rows), data


def queue_table(cur: dict, recipes: list, mults: list) -> tuple:
    """Holgura con todos los puestos llenos: la última comanda de la cola espera a las demás.

    Con reposición inmediata, en régimen hay `slots` comandas vivas y un bot secuencial tarda
    `slots × t` en servir la última. Holgura = paciencia − slots × t, con dos t por receta (mejor
    ruta de pasaplatos del bot, media de las recetas de la fase):
      - t flujo: pedido con el pulpo sobrante (cota optimista: nunca cuece);
      - t ciclo: media de desde cero y en flujo (1 pulpo = 2 cajas: se cuece uno de cada dos).
    """
    flow, cycle = {}, {}
    for entry in recipes:
        secs = {o["from"]: o["seconds"] for o in entry["orders"] if o["completed"]}
        if "cero" not in secs or "flujo" not in secs:
            continue
        key = (entry["mode"], entry["kind"])
        flow[key] = min(flow.get(key, 999.0), secs["flujo"])
        cycle[key] = min(cycle.get(key, 999.0), (secs["cero"] + secs["flujo"]) / 2)
    rows, data = [], []
    for mode in MODES:
        for i, phase in enumerate(cur["phases"]):
            names = [n for n in phase["orders"] if (mode, n) in flow]
            if not names:
                continue
            t_flow = statistics.mean(flow[(mode, n)] for n in names)
            t_cycle = statistics.mean(cycle[(mode, n)] for n in names)
            for name in phase["orders"]:
                patience = cur["orders"][name]["max_time"] * mults[i]
                rec = {
                    "mode": MODES[mode],
                    "phase": phase["phase"],
                    "slots": phase["slots"],
                    "recipe": name,
                    "patience_s": round(patience, 2),
                    "t_flow_s": round(t_flow, 2),
                    "t_cycle_s": round(t_cycle, 2),
                    "queue_slack_flow_s": round(patience - phase["slots"] * t_flow, 2),
                    "queue_slack_cycle_s": round(patience - phase["slots"] * t_cycle, 2),
                }
                rec["flag_flow"] = rec["queue_slack_flow_s"] < SLACK_FLAG
                rec["flag_cycle"] = rec["queue_slack_cycle_s"] < SLACK_FLAG
                data.append(rec)
                mark = lambda k: " ⚠" if rec[k] else ""
                rows.append(
                    f"| {rec['mode']} | {phase['phase']} | {phase['slots']} | {name} | "
                    f"{fmt(patience)} | {fmt(t_flow)} | **{fmt(rec['queue_slack_flow_s'])}**"
                    f"{mark('flag_flow')} | {fmt(t_cycle)} | **{fmt(rec['queue_slack_cycle_s'])}**"
                    f"{mark('flag_cycle')} |"
                )
    head = (
        "| Modo | Fase | Puestos | Receta | Paciencia (s) | t flujo (s) | Holgura cola, flujo (s) | "
        "t ciclo (s) | Holgura cola, ciclo (s) |\n|---|---:|---:|---|---:|---:|---:|---:|---:|"
    )
    return head + "\n" + "\n".join(rows), data


def round_rows(cur: dict, rounds: list) -> tuple:
    """AC2: recaudación, entregas, caducadas y estrellas por modo y semilla."""
    rows, data = [], []
    for r in sorted(rounds, key=lambda e: (e["mode"], e["seed"])):
        mode = MODES[r["mode"].removeprefix("round_")]
        served = {}
        for o in r["orders_log"]:
            if "done_at" in o:
                served[o["kind"]] = served.get(o["kind"], 0) + 1
        rec = {
            "mode": mode,
            "seed": r["seed"],
            "revenue": r["revenue"],
            "delivered": r["delivered"],
            "expired": r["expired"],
            "stars_game": r["stars"],
            "stars_current": stars(r["revenue"], cur["thresholds"]),
            "served": served,
            "trashed": r["trashed"],
            "burnt": r.get("burnt", 0),
            "bot_warnings": r["bot_warnings"],
        }
        data.append(rec)
        srv = ", ".join(f"{k} {v}" for k, v in served.items())
        rows.append(
            f"| {mode} | {r['seed']} | {r['revenue']} | {r['delivered']} | {r['expired']} | "
            f"{r['stars']} | {srv} | {r['trashed']} | {rec['burnt']} | {r['bot_warnings']} |"
        )
    head = (
        "| Modo | Semilla | Recaudación (€) | Entregas | Caducadas | Estrellas (30/60/90) | "
        "Servidas | Al cubo | Quemados | Avisos del bot |\n|---|---:|---:|---:|---:|---:|---|---:|---:|---:|"
    )
    return head + "\n" + "\n".join(rows), data


def round_slack(rounds: list) -> tuple:
    """Holgura real en partida: segundos que le quedaban a cada comanda al entregarla."""
    groups = {}
    for r in rounds:
        mode = MODES[r["mode"].removeprefix("round_")]
        for o in r["orders_log"]:
            key = (mode, o["kind"], o["phase"])
            g = groups.setdefault(key, {"left": [], "expired": 0, "patience": o["patience"]})
            if "time_left" in o:
                g["left"].append(o["time_left"])
            elif "expired_at" in o:
                g["expired"] += 1
    rows, data = [], []
    for (mode, kind, phase), g in sorted(groups.items(), key=lambda kv: (kv[0][0], RECIPES.index(kv[0][1]), kv[0][2])):
        left = g["left"]
        rec = {
            "mode": mode,
            "recipe": kind,
            "phase": phase,
            "patience_s": g["patience"],
            "delivered": len(left),
            "expired": g["expired"],
            "time_left_min": min(left) if left else None,
            "time_left_median": round(statistics.median(left), 2) if left else None,
            "flag": bool(left) and min(left) < SLACK_FLAG,
        }
        data.append(rec)
        rows.append(
            f"| {mode} | {kind} | {phase} | {fmt(g['patience'])} | {len(left)} | {g['expired']} | "
            f"{fmt(rec['time_left_min']) + (' ⚠' if rec['flag'] else '') if left else '—'} | "
            f"{fmt(rec['time_left_median']) if left else '—'} |"
        )
    head = (
        "| Modo | Receta | Fase | Paciencia (s) | Entregadas | Caducadas | Le quedaban mín. (s) | "
        "Mediana (s) |\n|---|---|---:|---:|---:|---:|---:|---:|"
    )
    return head + "\n" + "\n".join(rows), data


def phase_rates(cur: dict, rounds: list) -> dict:
    """€ por segundo de cada fase (por modo, media de semillas): entregas (precio + bonus) en el
    instante de entrega menos las caducadas en el instante de caducar."""
    starts = [p["start_s"] for p in cur["phases"]] + [cur["duration"]]
    acc = {}
    for r in rounds:
        mode = MODES[r["mode"].removeprefix("round_")]
        per = acc.setdefault(mode, {"runs": 0, "eur": [0.0] * len(cur["phases"])})
        per["runs"] += 1
        for o in r["orders_log"]:
            if "done_at" in o:
                t, eur = o["done_at"], o["points"] + int(o["time_left"] / o["patience"] * cur["time_bonus_max"])
            elif "expired_at" in o:
                t, eur = o["expired_at"], -cur["expire_penalty"]
            else:
                continue
            i = max(k for k in range(len(cur["phases"])) if t >= starts[k])
            per["eur"][i] += eur
    out = {}
    for mode, per in acc.items():
        out[mode] = [
            round(per["eur"][i] / per["runs"] / (starts[i + 1] - starts[i]), 3) for i in range(len(cur["phases"]))
        ]
    return out


def project(rates: list, starts: list, duration: float) -> float:
    bounds = list(starts) + [duration]
    return sum(rates[i] * (bounds[i + 1] - bounds[i]) for i in range(len(rates)))


def rescore(cur: dict, r: dict, prices: dict, mults: list) -> int:
    """Recaudación de una partida del bot con otros precios y multiplicadores, mismas entregas.

    Supone que el bot entrega en el mismo instante: la paciencia nueva cambia el bonus
    (proporción restante) y salva o caduca comandas cuya entrega o caducidad cae dentro del margen.
    """
    total = 0
    for o in r["orders_log"]:
        base = cur["orders"][o["kind"]]["max_time"]
        patience = base * mults[o["phase"] - 1] if o["phase"] else base
        if "done_at" in o:
            waited = o["done_at"] - o["at"]
            if waited <= patience:
                left = patience - waited
                total += prices[o["kind"]] + int(left / patience * cur["time_bonus_max"])
            else:
                total -= cur["expire_penalty"]
        elif "expired_at" in o:
            total -= cur["expire_penalty"]
    return max(total, 0)


def main() -> None:
    cur = current_values()
    recipes = load("metrics_recipes_*.json")
    every = load("metrics_round_*.json")
    rounds = [r for r in every if r.get("variant", "current") == "current"]
    measured = [r for r in every if r.get("variant") == "proposal"]
    t1, d1 = recipe_table(cur, recipes)
    t2, d2 = round_rows(cur, rounds)
    t3, d3 = round_slack(rounds)
    tq, dq = queue_table(cur, recipes, [p["multiplier"] for p in cur["phases"]])
    tqp, dqp = queue_table(cur, recipes, PROPOSAL["multipliers"])
    rescored = []
    for r in rounds:
        rescored.append(
            {
                "mode": MODES[r["mode"].removeprefix("round_")],
                "seed": r["seed"],
                "revenue_bot": r["revenue"],
                "revenue_check_current": rescore(
                    cur, r, {k: v["price"] for k, v in cur["orders"].items()}, [p["multiplier"] for p in cur["phases"]]
                ),
                "revenue_proposal": rescore(cur, r, PROPOSAL["prices"], PROPOSAL["multipliers"]),
            }
        )
    rates = phase_rates(cur, rounds)
    cur_starts = [p["start_s"] for p in cur["phases"]]
    projection = {
        mode: {
            "eur_per_s_by_phase": r,
            "revenue_current_limits": round(project(r, cur_starts, cur["duration"]), 1),
            "revenue_proposed_limits": round(project(r, PROPOSAL["phase_starts_s"], cur["duration"]), 1),
        }
        for mode, r in rates.items()
    }
    star_rows = []
    for mode in ("Individual", "Local 2P"):
        revs = [x["revenue_bot"] for x in rescored if x["mode"] == mode]
        if not revs:
            continue
        mean = statistics.mean(revs)
        for share in [1.0] + HUMAN_SHARES:
            rev = mean * share
            star_rows.append(
                {
                    "mode": mode,
                    "share_of_bot": share,
                    "revenue": round(rev),
                    "stars_current": stars(rev, cur["thresholds"]),
                    "stars_proposal": stars(rev, PROPOSAL["thresholds"][mode]),
                }
            )
    measured_rows = []
    for r in sorted(measured, key=lambda e: (e["mode"], e["seed"])):
        mode = MODES[r["mode"].removeprefix("round_")]
        base = next(b for b in rounds if b["mode"] == r["mode"] and b["seed"] == r["seed"])
        measured_rows.append(
            {
                "mode": mode,
                "seed": r["seed"],
                "revenue_current": base["revenue"],
                "revenue_proposal": r["revenue"],
                "delivered_current": base["delivered"],
                "delivered_proposal": r["delivered"],
                "expired_current": base["expired"],
                "expired_proposal": r["expired"],
                "stars_current": stars(base["revenue"], cur["thresholds"]),
                "stars_proposal": stars(r["revenue"], PROPOSAL["thresholds"][mode]),
                "cachelos_served_current": sum(1 for o in base["orders_log"] if "done_at" in o and "cachelos" in o["kind"]),
                "cachelos_served_proposal": sum(1 for o in r["orders_log"] if "done_at" in o and "cachelos" in o["kind"]),
            }
        )
    summary = {
        "current": cur,
        "proposal": PROPOSAL,
        "slack_flag_s": SLACK_FLAG,
        "recipes": d1,
        "rounds": d2,
        "round_slack": d3,
        "queue_slack_current": dq,
        "queue_slack_proposal": dqp,
        "rescored": rescored,
        "phase_projection": projection,
        "stars_by_share": star_rows,
        "measured_proposal": measured_rows,
    }
    (HERE / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
    rows = "\n".join(
        f"| {x['mode']} | {x['seed']} | {x['revenue_bot']} | {x['revenue_check_current']} | {x['revenue_proposal']} |"
        for x in sorted(rescored, key=lambda e: (e["mode"], e["seed"]))
    )
    md = (
        "# Tablas generadas por balance_tables.py\n\n## AC1 · Holgura por receta y fase\n\n"
        + t1
        + "\n\n## Holgura con la cola llena (valores actuales)\n\n"
        + tq
        + "\n\n## Holgura con la cola llena (multiplicadores propuestos)\n\n"
        + tqp
        + "\n\n## AC2 · Partidas de 300 s\n\n"
        + t2
        + "\n\n## Holgura real en partida (lo que le quedaba a cada comanda al entregarla)\n\n"
        + t3
        + "\n\n## Re-puntuación de las partidas con la propuesta\n\n"
        "| Modo | Semilla | € del juego | € recalculado (valores actuales) | € con la propuesta |\n"
        "|---|---:|---:|---:|---:|\n" + rows + "\n"
    )
    md += (
        "\n## € por segundo de cada fase y proyección de los límites de fase\n\n"
        "| Modo | €/s fase 1 | €/s fase 2 | €/s fase 3 | € con límites actuales | € con límites propuestos |\n"
        "|---|---:|---:|---:|---:|---:|\n"
        + "\n".join(
            f"| {m} | " + " | ".join(f"{x:.2f}".replace(".", ",") for x in v["eur_per_s_by_phase"]) + f" | {fmt(v['revenue_current_limits'])} | "
            f"{fmt(v['revenue_proposed_limits'])} |"
            for m, v in projection.items()
        )
        + "\n\n## Estrellas según la parte del bot que haga un jugador\n\n"
        "| Modo | Parte del bot | € | ★ con 30/60/90 | ★ con la propuesta |\n|---|---:|---:|---:|---:|\n"
        + "\n".join(
            f"| {x['mode']} | {int(x['share_of_bot'] * 100)} % | {x['revenue']} | {x['stars_current']} | {x['stars_proposal']} |"
            for x in star_rows
        )
        + "\n"
    )
    md += (
        "\n## Partidas del bot con la propuesta aplicada en memoria (límites 0/90/180 s, ×1/0,85/0,8)\n\n"
        "| Modo | Semilla | € actual → propuesta | Entregas | Caducadas | Con cachelos servidas | "
        "★ actual (30/60/90) → ★ propuesta |\n|---|---:|---|---|---|---|---|\n"
        + "\n".join(
            f"| {x['mode']} | {x['seed']} | {x['revenue_current']} → {x['revenue_proposal']} | "
            f"{x['delivered_current']} → {x['delivered_proposal']} | {x['expired_current']} → {x['expired_proposal']} | "
            f"{x['cachelos_served_current']} → {x['cachelos_served_proposal']} | {x['stars_current']} → {x['stars_proposal']} |"
            for x in measured_rows
        )
        + "\n"
    )
    (HERE / "tables.md").write_text(md)
    print(md)


if __name__ == "__main__":
    main()
