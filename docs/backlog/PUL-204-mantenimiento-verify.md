---
id: PUL-204
title: Ajustar timeouts, diagnóstico y documentación de verify
status: review
milestone: M4
role: godot-architect
deps: []
orca_task: null
unity_sources: []
owns: [tools/verify.sh, .claude/hooks/verify_on_stop.sh, .claude/skills/godot-verify/SKILL.md, AGENTS.md, CLAUDE.md, tools/card_frontmatter.py, docs/evidence/PUL-190/run_acs.sh]
touches_scenes: []
---

## Target
`verify.sh`, hook de Stop, `godot-verify`, y dos flecos de PUL-190 y PUL-193.

## Change
- **R9:** `timeout 600` de GUT con una suite de ~488 s deja poco margen. Subirlo sin superar el `timeout` de 900 s del hook de Stop en `settings.json`; si no cabe, dilo.
- **Filtro de errores de `verify.sh`:** solo muestra la ubicación si la línea lleva `GDScript::reload` (se pierde la de `@static_initializer`), y `head -60` puede recortar la lista y su resumen.
- **Hook de Stop:** solo mira `godot/`; incluir `AGENTS.md` y `CLAUDE.md`.
- **Documentación:** `godot-verify` y la línea «Verificación completa» de `AGENTS.md` y `CLAUDE.md` no mencionan compilación ni sincronía; sin hacer crecer el texto más de lo necesario.
- **`card_frontmatter.py:27`:** cambiar el U+FEFF literal por el escape de Python.
- **`run_acs.sh`:** copiar `tools/card_frontmatter.py` al sandbox para que el control «hook intacto» vuelva a probar `owns` y no `ModuleNotFoundError`, y exigir al final los `ac*.txt` esperados.

## Constraints
No cambia qué se verifica. `AGENTS.md` y `CLAUDE.md` siguen idénticos.

## Acceptance
- [x] AC1 Given un error en un `static var` y otro en un script distinto, When `verify.sh --quick`, Then rc≠0, y se ven la ubicación y el resumen → docs/evidence/PUL-204/
- [x] AC2 Given `verify.sh` completo, When corre la suite, Then verde dentro del nuevo timeout → docs/evidence/PUL-204/
- [x] AC3 Given `run_acs.sh`, When se ejecuta con el hook actual, Then el control bloquea por `owns` y con salida faltante falla → docs/evidence/PUL-204/

## Plan
1. Línea base con el código actual, errores inyectados en `godot/` y revertidos sin commitear: AC1 (`@static_initializer`, lista larga) y AC3 (control de `run_acs.sh` y salida faltante). Hook de Stop y `card_frontmatter.py` se reproducen aparte.
2. `verify.sh`: subir el `timeout` de GUT, conservar la ubicación de cualquier `SCRIPT ERROR` y no recortar nunca la lista ni el resumen de `check_scripts`.
3. Hook de Stop: incluir `AGENTS.md` y `CLAUDE.md`; sin `current-task` sigue saliendo con 0.
4. Documentación mínima en `godot-verify`, `AGENTS.md` y `CLAUDE.md`, idénticos byte a byte.
5. `card_frontmatter.py`: escape `\ufeff`. `run_acs.sh`: copiar el parser al sandbox, exigir que el control bloquee por `owns` y exigir los `ac*.txt`.
6. Peor caso de `verify.sh` frente a los 900 s del hook, con tiempos medidos. `verify.sh` completo en segundo plano y evidencia en `docs/evidence/PUL-204/`.

## Evidence
Windows 11, Git Bash, Python 3.13.18, Godot 4.7.2. Errores inyectados en `godot/zz_pul204/` y revertidos sin commitear. Ninguna salida lleva rutas absolutas.

| Comprobación | Línea base (`31603ce`) | Tras el cambio | Salida |
|---|---|---|---|
| AC1 `static var` y otro script | rc=1, sin ubicación de los dos `static var` | rc=1, con `at: @static_initializer (res://zz_pul204/static_direct.gd:3)`, `at: fail_on_load (…/static_boom.gd:8)`, la de `other_broken.gd:5` y el resumen | `ac1_linea_base.txt`, `ac1.txt` |
| AC1 solo `static var` (`check_scripts: OK`) | rc=1, sin ubicación | rc=1, con ubicación | ídem |
| AC1 45 scripts que no compilan | 0 de 45 en la lista, sin resumen | 45 de 45 en la lista, resumen y aviso de líneas omitidas; 60 líneas de `SCRIPT ERROR` y `at:` | ídem |
| AC2 `tools/verify.sh` completo | no aplica | `✓ verify OK`, rc=0 en 531 s; 1378 de 1378 tests | `ac2.txt` |
| AC3 control con el hook actual | `BLOQUEA` por `ModuleNotFoundError`, rc=0 | `BLOQUEA` por `owns`, `PASS`, rc=0, `fallos=0` | `ac3.txt`, `run_acs/` |
| AC3 con `ac2.txt` sin poder escribirse | `fallos=0`, rc=0 | `FAIL faltan salidas: ac2.txt`, rc=1 | `ac3.txt` |
| AC3 sandbox sin el parser (error inyectado) | no aplica | `FAIL el control no bloquea por owns`, rc=1 | `ac3.txt` |
| Hook de Stop | 9 de 15 casos fallan: no mira `AGENTS.md` ni `CLAUDE.md` | 15 de 15; sin `current-task`, rc=0 y `verify` sin llamar | `stop_hook_linea_base.txt`, `stop_hook.txt` |
| `card_frontmatter.py` L27 | U+FEFF crudo | escape; mismo resultado con BOM y sin él | `card_frontmatter.txt` |

`run_stop_hook.sh` prueba el hook en un repo temporal con un `verify.sh` falso, para no lanzar la suite en cada caso.

### Peor caso frente a los 900 s del hook: no cabe
`timeout` de GUT: de 600 a 720 s. Sobre los 505,9 s de GUT medidos (510 s de reloj), el margen pasa de 94 s (+19 %) a 214 s (+42 %).

| Paso | Timeout | Medido, en caché | Medido, worktree sin importar |
|---|---|---|---|
| sincronía | sin timeout | 0 s | 0 s |
| gdformat + gdlint | sin timeout | 13 s | 13 s |
| import | 300 s | 4 s | 30 s |
| compilación | 300 s | 3 s | 3 s |
| GUT | 720 s (antes 600) | 510 s | no medido por separado |
| smoke | 120 s | 1 s | no medido por separado |
| **Total** | **1440 s + 13 s** | **531 s** | **557 s** (estimado: 46 s de `--quick` en frío + 510 + 1) |

- **Peor caso nominal:** 300 + 300 + 720 + 120 = 1440 s, más 13 s de lint sin timeout: 1453 s, 553 s por encima de 900. `verify.sh` no se corta al primer fallo, así que todos los pasos cuentan. Con 600 s ya eran 1333 s.
- **Para que cupiera sin tocar los otros timeouts:** GUT debería tener 900 − 720 − 13 = 167 s como máximo, menos que los 510 s de la suite. No es posible.
- **Peor caso con GUT colgado y el resto en su tiempo medido:** 720 + 47 = 767 s, 133 s por debajo de 900. Es lo que cubre el valor elegido.
- **Queda sin cubrir:** si el import, la compilación o el smoke se acercan a su timeout además de una suite lenta, el hook de 900 s corta antes que `verify.sh`. Cerrarlo exige un `timeout` de al menos 1453 s en `settings.json`, fuera de `owns`, o bajar los otros timeouts.

### No verificable
- **Linux y macOS:** todo se ha ejecutado en Windows; el encargo prohíbe usar WSL y esta máquina no es un Mac. En particular, el `awk` de `verify.sh`, `run_stop_hook.sh` y `run_acs.sh`.
- **Agotar los timeouts reales** (720 s de GUT, 900 s del hook): no se han provocado. Tampoco qué hace Claude Code con el agente al agotarse los 900 s.
- **Evento Stop real de Claude Code:** el hook se ha invocado directamente, con `verify.sh` falso. `verify.sh` real se ha pasado aparte.
