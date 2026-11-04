#!/usr/bin/env python3
"""Ejecuta AC1-AC4 de PUL-193 y guarda la salida junto a este script.

Uso, desde Git Bash en la raíz del repo: python3 "$(pwd -W)/docs/evidence/PUL-193/run_acs.py"
Trabaja en sandboxes temporales con repo Git propio: no toca el backlog real ni escribe .pyc en él.
La línea base (hook y check_owns anteriores) sale de BASE con `git show`. Sale con 1 si algo falla.
"""
import ast
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
BASE = "ec25eccc95218293a53745b9c202815f0f1a66d2"
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
HOOK = ".claude/hooks/guard_ownership.py"
CHECK = "tools/check_owns.py"
MODULE = "tools/card_frontmatter.py"
sys.path.insert(0, str(REPO / "tools"))
from card_frontmatter import frontmatter_list  # noqa: E402

fails = 0
ENV = {k: v for k, v in os.environ.items() if k not in ("PYTHONUTF8", "PYTHONIOENCODING", "CLAUDE_PROJECT_DIR")}


def git_show(path: str) -> str:
    out = subprocess.run(["git", "show", f"{BASE}:{path}"], cwd=REPO, capture_output=True, check=True)
    return out.stdout.decode("utf-8")


class Report:
    def __init__(self, name: str) -> None:
        self.path = HERE / name
        self.lines: list[str] = []

    def say(self, line: str = "") -> None:
        self.lines.append(line)

    def check(self, ok: bool, line: str) -> None:
        global fails
        fails += 0 if ok else 1
        self.say(f"{'OK  ' if ok else 'FALLO'} {line}")

    def save(self, *secrets: str) -> None:
        text = "\n".join(self.lines) + "\n"
        for secret in secrets:
            text = text.replace(secret, "<sandbox>").replace(secret.replace("\\", "/"), "<sandbox>")
        self.path.write_text(text, encoding="utf-8", newline="\n")


def git(cwd: Path, *args: str) -> str:
    cmd = ["git", "-c", "user.name=pul193", "-c", "user.email=pul193@example.invalid",
           "-c", "core.autocrlf=false", "-c", "core.hooksPath=", *args]
    return subprocess.run(cmd, cwd=cwd, capture_output=True, check=True, encoding="utf-8").stdout


def install(box: Path, hook: str, check: str, module: bool = True) -> None:
    for rel, text in ((HOOK, hook), (CHECK, check)):
        (box / rel).parent.mkdir(parents=True, exist_ok=True)
        (box / rel).write_text(text, encoding="utf-8", newline="\n")
    if module:
        shutil.copy(REPO / MODULE, box / MODULE)


def write_card(box: Path, task: str, body: bytes) -> None:
    card = box / "docs" / "backlog" / f"{task}-x.md"
    card.parent.mkdir(parents=True, exist_ok=True)
    card.write_bytes(body)


def set_task(box: Path, task: str | None) -> None:
    marker = box / ".claude" / "current-task"
    marker.parent.mkdir(parents=True, exist_ok=True)
    if task is None:
        marker.unlink(missing_ok=True)
    else:
        marker.write_text(task + "\n", encoding="utf-8")


def run_hook(box: Path, rel: str, cwd: Path | None = None, project_env: bool = True) -> tuple[int, str]:
    env = dict(ENV)
    if project_env:
        env["CLAUDE_PROJECT_DIR"] = str(box)
    target = str(box / rel)
    payload = json.dumps({"tool_name": "Edit", "tool_input": {"file_path": target}}).encode("utf-8")
    done = subprocess.run([sys.executable, str(box / HOOK)], input=payload, capture_output=True,
                          cwd=cwd or box, env=env)
    return done.returncode, done.stderr.decode("utf-8", "backslashreplace")


def run_check(box: Path, branch: str, base: str = "main", cwd: Path | None = None) -> tuple[int, str]:
    done = subprocess.run([sys.executable, str(box / CHECK), branch, base], capture_output=True,
                          cwd=cwd or box, env=ENV)
    return done.returncode, (done.stdout + done.stderr).decode("utf-8", "backslashreplace")


def permitted(message: str, drop: int) -> list[str] | None:
    """Lista de rutas del mensaje de rechazo, sin las `drop` que añade cada herramienta."""
    found = re.search(r"Rutas permitidas: (.*)", message)
    if not found:
        return None
    items = found.group(1).strip().split(", ")
    return items[:-drop]


def card_text(front: str) -> str:
    return f"---\nid: X\ntitle: t\nstatus: ready\n{front}\n---\n\n## Target\nowns: [cuerpo/no-cuenta/**]\n"


# (nombre, frontmatter, lista esperada). Las rutas literales y los globs valen para todas menos los casos vacíos.
SCENE = "touches_scenes: [scenes/a.tscn]"
WANT = ["docs/a.txt", "src/**", "scenes/a.tscn"]
VARIANTS: list[tuple[str, bytes, list[str]]] = [
    ("inline", card_text(f"owns: [docs/a.txt, src/**]\n{SCENE}").encode(), WANT),
    ("bloque", card_text(f"owns:\n  - docs/a.txt\n  - src/**\n{SCENE}").encode(), WANT),
    ("inline con comentario final",
     card_text(f"owns: [docs/a.txt, src/**]   # nota, zz/fuera.txt, [zz/**]\n{SCENE}   # otra").encode(), WANT),
    ("bloque con comentarios",
     card_text(f"owns:   # nota\n  - docs/a.txt  # uno\n  # zz/**\n\n  - src/** # dos\n{SCENE}").encode(), WANT),
    ("bloque sin sangría", card_text(f"owns:\n- docs/a.txt\n- src/**\n{SCENE}").encode(), WANT),
    ("inline vacía con comentario", card_text("owns: []   # zz/**\ntouches_scenes: []  # zz/**").encode(), []),
    ("comillas y # dentro de un glob",
     card_text(f"owns: ['docs/a.txt', \"src/**\", docs/b#c.txt]  # zz/**\n{SCENE}").encode(),
     ["docs/a.txt", "src/**", "docs/b#c.txt", "scenes/a.tscn"]),
    ("BOM", b"\xef\xbb\xbf" + card_text(f"owns: [docs/a.txt, src/**]\n{SCENE}").encode(), WANT),
    ("CRLF", card_text(f"owns:\n  - docs/a.txt\n  - src/**\n{SCENE}").replace("\n", "\r\n").encode(), WANT),
]


def build_ac1_repo(box: Path, hook: str, check: str, module: bool) -> None:
    install(box, hook, check, module)
    git(box, "init", "-q", "-b", "main")
    for n, (_, body, _) in enumerate(VARIANTS):
        write_card(box, f"PUL-{900 + n}", body)
    git(box, "add", "-A")
    git(box, "commit", "-qm", "base")
    for n, (_, _, want) in enumerate(VARIANTS):
        branch = f"pul-{900 + n}-fuera"
        git(box, "switch", "-qc", branch, "main")
        for rel in ["zz/fuera.txt", *[w.replace("**", "d/e.gd") for w in want]]:
            (box / rel).parent.mkdir(parents=True, exist_ok=True)
            (box / rel).write_text("x\n", encoding="utf-8")
        git(box, "add", "-A")
        git(box, "commit", "-qm", "fuera")
        git(box, "switch", "-qc", f"pul-{900 + n}-dentro", "main")
        for rel in [w.replace("**", "d/e.gd") for w in want]:
            (box / rel).parent.mkdir(parents=True, exist_ok=True)
            (box / rel).write_text("x\n", encoding="utf-8")
        git(box, "add", "-A")
        git(box, "commit", "-qm", "dentro", "--allow-empty")
    git(box, "switch", "-q", "main")


def ac1(new_hook: str, new_check: str, old_hook: str, old_check: str) -> None:
    rep = Report("ac1.txt")
    rep.say("AC1: la misma ficha en cada forma; hook y check_owns dan la misma lista (mensaje de rechazo real).")
    rep.say("La línea `owns:` del cuerpo no debe contar. Código nuevo:")
    secrets: list[str] = []
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
        box = Path(tmp).resolve()
        secrets.append(str(box))
        build_ac1_repo(box, new_hook, new_check, True)
        for n, (name, body, want) in enumerate(VARIANTS):
            task = f"PUL-{900 + n}"
            set_task(box, task)
            parsed = frontmatter_list(body.decode("utf-8"), "owns") + frontmatter_list(body.decode("utf-8"),
                                                                                        "touches_scenes")
            rc_hook, err_hook = run_hook(box, "zz/fuera.txt")
            hook_list = permitted(err_hook, 3)
            rc_check, err_check = run_check(box, f"pul-{900 + n}-fuera")
            check_list = permitted(err_check, 2)
            rep.check(parsed == want and hook_list == want and check_list == want and rc_hook == 2 and rc_check == 1,
                      f"{name}: hook rc={rc_hook} {hook_list} | check_owns rc={rc_check} {check_list}")
            rcs_in = [run_hook(box, w.replace("**", "d/e.gd"))[0] for w in want]
            rc_in, _ = run_check(box, f"pul-{900 + n}-dentro")
            rep.check(all(rc == 0 for rc in rcs_in) and rc_in == 0,
                      f"{name}: rutas incluidas: hook rc={rcs_in} | check_owns rc={rc_in}")
        set_task(box, "PUL-901")
        rep.say()
        rep.say("Otro directorio de trabajo (carpeta ajena y subcarpeta del repo):")
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as other:
            other_dir = Path(other).resolve()
            secrets.append(str(other_dir))
            for label, cwd in (("ajena", other_dir), ("subcarpeta", box / "docs")):
                rc1, _ = run_hook(box, "docs/a.txt", cwd=cwd)
                rc2, _ = run_hook(box, "zz/fuera.txt", cwd=cwd)
                rc3, _ = run_hook(box, "zz/fuera.txt", cwd=cwd, project_env=False)
                rc4, _ = run_check(box, "pul-901-dentro", cwd=cwd)
                rc5, _ = run_check(box, "pul-901-fuera", cwd=cwd)
                rep.check((rc1, rc2, rc3, rc4, rc5) == (0, 2, 2, 0, 1),
                          f"{label}: hook incluida rc={rc1}, fuera rc={rc2}, fuera sin CLAUDE_PROJECT_DIR rc={rc3}; "
                          f"check_owns dentro rc={rc4}, fuera rc={rc5}")
        rep.say()
        rep.say("check_owns en rama sin pul-<n>, con módulo y sin él:")
        rc, out = run_check(box, "main")
        rep.check(rc == 0, f"con módulo: rc={rc} {out.strip()}")
        moved = box / MODULE
        keep = moved.read_bytes()
        moved.unlink()
        rc, out = run_check(box, "main")
        rep.check(rc == 0, f"sin módulo: rc={rc} {out.strip()}")
        rc, _ = run_check(box, "pul-901-dentro")
        rep.check(rc != 0, f"sin módulo en rama de ficha: rc={rc} (rechaza)")
        moved.write_bytes(keep)
        rep.say()
        set_task(box, None)  # .claude/current-task está en el .gitignore real, no en el del sandbox.
        status = git(box, "status", "--porcelain").strip()
        pycache = [p.relative_to(box).as_posix() for p in box.rglob("__pycache__")]
        rep.check(status == "" and not pycache, f"árbol limpio tras todo lo anterior: status={status!r}, __pycache__={pycache}")
        # Control: sin sys.dont_write_bytecode, el hook sí ensucia el árbol. La comprobación anterior puede fallar.
        set_task(box, "PUL-901")
        flag = "    sys.dont_write_bytecode = True\n"
        assert flag in new_hook
        (box / HOOK).write_text(new_hook.replace(flag, ""), encoding="utf-8", newline="\n")
        run_hook(box, "docs/a.txt")
        pycache = [p.relative_to(box).as_posix() for p in box.rglob("__pycache__")]
        rep.check(pycache == ["tools/__pycache__"], f"control sin la bandera: __pycache__={pycache}")
    rep.say()
    rep.say(f"Línea base, hook y check_owns de {BASE[:7]} (informativo, documenta el fallo que se corrige):")
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
        box = Path(tmp).resolve()
        secrets.append(str(box))
        build_ac1_repo(box, old_hook, old_check, False)
        for n, (name, _, want) in enumerate(VARIANTS):
            set_task(box, f"PUL-{900 + n}")
            _, err_hook = run_hook(box, "zz/fuera.txt")
            hook_list = permitted(err_hook, 3)
            rc_in, _ = run_check(box, f"pul-{900 + n}-dentro")
            same = "igual" if hook_list == want else "DISTINTA"
            rep.say(f"  {name}: hook {same} {hook_list} | check_owns rama con rutas incluidas rc={rc_in}")
    rep.save(*secrets)


def extract_old_check_parser(source: str):
    """El fm_list antiguo cierra sobre el global `text`: se ejecuta tal cual lo escribió check_owns.py."""
    tree = ast.parse(source)
    func = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "fm_list")
    scope: dict = {"re": re}
    exec(compile(ast.Module([func], []), "old_check_owns", "exec"), scope)

    def call(text: str, key: str) -> list[str]:
        scope["text"] = text
        return scope["fm_list"](key)

    return call


def ac2(new_hook: str, new_check: str, old_hook: str, old_check: str) -> None:
    rep = Report("ac2.txt")
    scope: dict = {"__name__": "old_hook"}
    exec(compile(old_hook, "old_guard_ownership", "exec"), scope)
    old_hook_parser = scope["frontmatter_list"]
    old_check_parser = extract_old_check_parser(old_check)
    cards = sorted((REPO / "docs" / "backlog").glob("*.md"))
    sources = [(c.name, c.read_bytes().decode("utf-8-sig")) for c in cards]
    sources.append((f"_TEMPLATE.md@{BASE[:7]}", git_show("docs/backlog/_TEMPLATE.md")))
    rep.say(f"AC2: parser nuevo frente a los dos de {BASE[:7]}, con owns y touches_scenes de docs/backlog/*.md.")
    rep.say("nombre | owns (n) | touches_scenes (n)")
    diffs = 0
    for name, text in sources:
        for key in ("owns", "touches_scenes"):
            new = frontmatter_list(text, key)
            old_a = old_hook_parser(text, key)
            old_b = old_check_parser(text, key)
            if not new == old_a == old_b:
                diffs += 1
                rep.say(f"DIFERENCIA {name} {key}: nuevo={new} hook={old_a} check_owns={old_b}")
        rep.say(f"{name} | {len(frontmatter_list(text, 'owns'))} | {len(frontmatter_list(text, 'touches_scenes'))}")
    rep.check(diffs == 0, f"{len(sources)} ficheros, {diffs} diferencias en el parser")

    # De extremo a extremo: mismo rc del hook nuevo y el antiguo en cada ficha.
    rep.say()
    rep.say("Hook completo, nuevo y antiguo, en cada ficha: primera ruta de owns y una ruta ajena.")
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_new, \
            tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_old:
        box_new = Path(tmp_new).resolve()
        box_old = Path(tmp_old).resolve()
        install(box_new, new_hook, new_check, True)
        install(box_old, old_hook, old_check, False)
        tasks = [c for c in cards if c.name.startswith("PUL-")]
        for box in (box_new, box_old):
            shutil.copytree(REPO / "docs" / "backlog", box / "docs" / "backlog")
        rc_diffs = 0
        allowed_ok = 0
        for card in tasks:
            task = card.name[:7]
            owns = frontmatter_list(card.read_bytes().decode("utf-8-sig"), "owns")
            own = owns[0].replace("**", "d/e").replace("*", "e") if owns else "sin/owns.txt"
            results = []
            for rel in (own, "zz_fuera/x.txt"):
                for box in (box_new, box_old):
                    set_task(box, task)
                results.append((run_hook(box_new, rel)[0], run_hook(box_old, rel)[0]))
            if any(a != b for a, b in results):
                rc_diffs += 1
                rep.say(f"DIFERENCIA {card.name}: {results}")
            allowed_ok += results[0][0] == 0 and results[1][0] == 2
        rep.check(rc_diffs == 0, f"{len(tasks)} fichas, {rc_diffs} con rc distinto entre hook nuevo y antiguo; "
                                 f"{allowed_ok} con rc=0 en su ruta y rc=2 en la ajena")
    rep.save()


def ac3(new_hook: str, new_check: str) -> None:
    rep = Report("ac3.txt")
    template = (REPO / "docs" / "backlog" / "_TEMPLATE.md").read_text(encoding="utf-8")
    rep.say("AC3: copia de _TEMPLATE.md con owns relleno.")
    secrets: list[str] = []
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
        box = Path(tmp).resolve()
        secrets.append(str(box))
        install(box, new_hook, new_check, True)
        assert "\nowns: []\n" in template
        filled = template.replace("\nowns: []\n", "\nowns: [docs/a.txt, src/**]\n", 1)
        write_card(box, "PUL-900", filled.encode("utf-8"))
        set_task(box, "PUL-900")
        for rel, want in (("docs/a.txt", 0), ("src/d/e.gd", 0), ("zz/fuera.txt", 2)):
            rc, _ = run_hook(box, rel)
            rep.check(rc == want, f"{rel}: rc={rc} (se espera {want})")
        # Una copia de la plantilla anterior, con su comentario tras `owns`, también se lee ya bien.
        old_template = git_show("docs/backlog/_TEMPLATE.md")
        write_card(box, "PUL-901", old_template.replace("owns: []  ", "owns: [docs/a.txt]  ", 1).encode("utf-8"))
        set_task(box, "PUL-901")
        rc, _ = run_hook(box, "docs/a.txt")
        rep.check(rc == 0, f"plantilla anterior con comentario tras owns, docs/a.txt: rc={rc}")
    rep.say()
    rep.say("Plantilla:")
    front = template.split("---")[1]
    line = {l.split(":", 1)[0]: l for l in front.splitlines() if ":" in l}
    rep.check(line["owns"] == "owns: []" and line["touches_scenes"] == "touches_scenes: []",
              f"sin comentarios: {line['owns']!r}, {line['touches_scenes']!r}")
    rep.check("opcional" in line["unity_sources"] and "D17" in line["unity_sources"]
              and "especificación" not in line["unity_sources"], line["unity_sources"])
    rep.check("superseded" in line["status"], line["status"])
    rep.check("docs/design/roadmap.md" in line["milestone"], line["milestone"])
    rep.say()
    rep.say("Cabecera de README.md:")
    readme = (REPO / "docs" / "backlog" / "README.md").read_bytes().decode("utf-8")
    old_readme = git_show("docs/backlog/README.md")
    mark = "## Fichas actuales"
    head = readme.split(mark)[0]
    for word in ("tal cual", "Ownership", "worker-start --spec"):
        rep.check(word not in head, f"sin {word!r} en la cabecera")
    rep.check(readme.split(mark)[1] == old_readme.split(mark)[1], f"tabla de fichas idéntica a {BASE[:7]}")
    rep.save(*secrets)


def ac4(new_hook: str, new_check: str) -> None:
    rep = Report("ac4.txt")
    rep.say("AC4: hook sin el módulo. Mensajes con la salida real de stderr.")
    secrets: list[str] = []
    card = card_text(f"owns: [docs/a.txt]\n{SCENE}").encode()

    def scenario(label: str, want_rc: int, prepare=None, task: str | None = "PUL-900", rel: str = "docs/a.txt",
                 cwd_shadow: bool = False) -> None:
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            box = Path(tmp).resolve()
            secrets.append(str(box))
            install(box, new_hook, new_check, False)
            write_card(box, "PUL-900", card)
            set_task(box, task)
            if prepare:
                prepare(box)
            cwd = box
            if cwd_shadow:
                cwd = box / "otra"
                cwd.mkdir()
                (cwd / "card_frontmatter.py").write_text(
                    "def frontmatter_list(text, key):\n    return ['**']\n", encoding="utf-8")
            rc, err = run_hook(box, rel, cwd=cwd)
            rep.check(rc == want_rc, f"{label}: rc={rc} (se espera {want_rc})")
            for line in err.strip().splitlines():
                rep.say(f"      {line}")

    def broken(body: str):
        def apply(box: Path) -> None:
            (box / MODULE).write_text(body, encoding="utf-8")
        return apply

    scenario("módulo ausente, con current-task, ruta incluida", 2)
    scenario("módulo ausente, con current-task, ruta ajena", 2, rel="zz/fuera.txt")
    scenario("módulo ausente, con otro card_frontmatter.py en el directorio de trabajo", 2, cwd_shadow=True)
    scenario("módulo con error de sintaxis", 2, broken("def frontmatter_list(:\n"))
    scenario("módulo sin la función", 2, broken("x = 1\n"))
    scenario("módulo que lanza al importar", 2, broken("raise RuntimeError('roto')\n"))
    scenario("módulo que hace sys.exit(0) al importar", 2, broken("import sys\nsys.exit(0)\n"))
    scenario("módulo ausente, sin current-task (no restringe nada)", 0, task=None)
    scenario("módulo presente (control)", 0, lambda box: shutil.copy(REPO / MODULE, box / MODULE))
    rep.save(*secrets)


def main() -> int:
    new_hook = (REPO / HOOK).read_bytes().decode("utf-8")
    new_check = (REPO / CHECK).read_bytes().decode("utf-8")
    old_hook = git_show(HOOK)
    old_check = git_show(CHECK)
    ac1(new_hook, new_check, old_hook, old_check)
    ac2(new_hook, new_check, old_hook, old_check)
    ac3(new_hook, new_check)
    ac4(new_hook, new_check)
    (HERE / "env.txt").write_text(
        f"{sys.platform} | python {sys.version.split()[0]} | locale {__import__('locale').getencoding()}\n",
        encoding="utf-8", newline="\n")
    (HERE / "summary.txt").write_text(f"fallos: {fails}\n", encoding="utf-8", newline="\n")
    print(f"fallos: {fails}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
