#!/usr/bin/env python3
"""
Gerador de site estático para o vault da Matéria Médica.

Lê as fichas em plantas/, farmacos/, compostos/, homeopatia/ (frontmatter YAML +
corpo Markdown com [[wikilinks]] e blocos ```mermaid), e gera um site HTML em
site/ pronto para o GitHub Pages — resolvendo os wikilinks, renderizando mermaid
no navegador e substituindo os painéis Dataview (só funcionam no Obsidian) por
tabelas geradas a partir do próprio frontmatter.

Uso: python3 _site_builder/build.py
"""
import re
import shutil
from pathlib import Path

import markdown
import yaml
from jinja2 import Environment, FileSystemLoader

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "site"
FOLDERS = ["plantas", "farmacos", "compostos", "homeopatia"]
IMAGES_DIR = ROOT / "_imagens"
IMG_EXTS = [".jpg", ".jpeg", ".png", ".webp"]

RISCO_LABEL = {"baixo": "Baixo", "moderado": "Moderado", "alto": "Alto"}
STATUS_LABEL = {"rascunho": "Rascunho", "revisado": "Revisado"}

env = Environment(loader=FileSystemLoader(str(Path(__file__).parent / "templates")))


def parse_frontmatter(text: str):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return {}, text
    fm = yaml.safe_load(m.group(1)) or {}
    return fm, m.group(2)


def slugify(name: str) -> str:
    return name.strip()


def find_image(slug: str):
    """Procura uma foto em _imagens/<slug>.(jpg|jpeg|png|webp). Convenção simples:
    o nome do arquivo de imagem é igual ao nome do arquivo .md da ficha."""
    if not IMAGES_DIR.exists():
        return None
    for ext in IMG_EXTS:
        p = IMAGES_DIR / f"{slug}{ext}"
        if p.exists():
            return p.name
    return None


env.globals["find_image"] = find_image


def collect_notes():
    """Varre as pastas e monta {slug_do_arquivo: {folder, slug, fm, body}}."""
    notes = {}
    for folder in FOLDERS:
        d = ROOT / folder
        if not d.exists():
            continue
        for f in sorted(d.glob("*.md")):
            text = f.read_text(encoding="utf-8")
            fm, body = parse_frontmatter(text)
            slug = f.stem
            notes[slug] = {"folder": folder, "slug": slug, "out_name": slug, "fm": fm, "body": body, "path": f}
    # home e guia também entram no mapa de links, mas não nas listagens por tipo.
    # A home vira "index.html" no site (não "00-materia-medica-home.html").
    for extra, folder, out_name in [
        ("00-materia-medica-home", ".", "index"),
        ("_guia/mm-como-preencher", "_guia", "mm-como-preencher"),
    ]:
        f = ROOT / f"{extra}.md"
        if f.exists():
            text = f.read_text(encoding="utf-8")
            fm, body = parse_frontmatter(text)
            slug = f.stem
            notes[slug] = {"folder": folder, "slug": slug, "out_name": out_name, "fm": fm, "body": body, "path": f}
    return notes


def resolve_wikilinks(body: str, notes: dict, current_folder: str) -> str:
    """Troca [[alvo]] e [[alvo|texto]] por links reais para o HTML gerado."""

    def repl(match):
        inner = match.group(1)
        if "|" in inner:
            target, label = inner.split("|", 1)
        elif "#" in inner:
            target, anchor = inner.split("#", 1)
            label = anchor
        else:
            target, label = inner, inner
        target = target.strip()
        label = label.strip()
        note = notes.get(target)
        if note:
            # "." (home) e "_guia" (guia de preenchimento) são publicados na raiz do site
            target_folder = "." if note["folder"] in (".", "_guia") else note["folder"]
            return f'<a href="__LINK__{target_folder}__{note["out_name"]}" class="wikilink">{label}</a>'
        return f'<span class="wikilink-missing" title="ficha não encontrada">{label}</span>'

    return re.sub(r"\[\[([^\]]+)\]\]", repl, body)


def fix_link_paths(html: str, from_folder: str) -> str:
    """Resolve os marcadores __LINK__folder__slug para caminhos relativos reais,
    dependendo de onde a página atual está (raiz do site ou dentro de plantas/ etc.)."""
    from_is_root = from_folder in (".", "_guia")

    def repl(match):
        target_folder, slug = match.group(1), match.group(2)
        target_is_root = target_folder == "."
        if from_is_root:
            prefix = "" if target_is_root else f"{target_folder}/"
        else:
            prefix = "../" if target_is_root else f"../{target_folder}/"
        return f'href="{prefix}{slug}.html"'

    return re.sub(r'href="__LINK__([^_]+)__([^"]+)"', repl, html)


def mermaid_preprocess(body: str) -> str:
    """Troca ```mermaid ... ``` por um <div class="mermaid"> antes do parser Markdown,
    senão o Markdown escapa o conteúdo como bloco de código comum."""

    def repl(match):
        code = match.group(1)
        return f'\n<div class="mermaid">\n{code}\n</div>\n'

    return re.sub(r"```mermaid\n(.*?)```", repl, body, flags=re.S)


def render_body(body: str, notes: dict, folder: str) -> str:
    body = mermaid_preprocess(body)
    body = resolve_wikilinks(body, notes, folder)
    html = markdown.markdown(
        body, extensions=["tables", "fenced_code", "toc", "sane_lists"], output_format="html5"
    )
    html = fix_link_paths(html, folder)
    return html


def badge(kind: str, value: str) -> str:
    if not value:
        return ""
    cls = f"badge badge-{kind}-{value}"
    label = RISCO_LABEL.get(value) if kind == "risco" else STATUS_LABEL.get(value, value)
    return f'<span class="{cls}">{label or value}</span>'


def build_index_tables(notes: dict):
    tables = {"planta": [], "farmaco": [], "composto": [], "homeopatico": []}
    for n in notes.values():
        t = n["fm"].get("type")
        if t in tables:
            tables[t].append(n)
    for k in tables:
        tables[k].sort(key=lambda n: n["slug"])
    return tables


def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    notes = collect_notes()
    tables = build_index_tables(notes)

    page_tpl = env.get_template("page.html")
    index_tpl = env.get_template("index.html")

    # páginas das fichas
    for n in notes.values():
        if n["folder"] in (".", "_guia"):
            continue
        html_body = render_body(n["body"], notes, n["folder"])
        out_dir = OUT / n["folder"]
        out_dir.mkdir(parents=True, exist_ok=True)
        page_html = page_tpl.render(
            title=n["fm"].get("nome_comum", [n["slug"]])[0] if n["fm"].get("nome_comum") else n["slug"],
            fm=n["fm"],
            badge_risco=badge("risco", n["fm"].get("risco", "")),
            badge_status=badge("status", n["fm"].get("status", "")),
            body=html_body,
            folder=n["folder"],
            image=find_image(n["slug"]),
        )
        (out_dir / f"{n['slug']}.html").write_text(page_html, encoding="utf-8")

    # guia (fica na raiz do site, igual ao vault)
    guia = notes.get("mm-como-preencher")
    if guia:
        html_body = render_body(guia["body"], notes, ".")
        page_html = page_tpl.render(
            title="Como preencher as fichas", fm=guia["fm"], badge_risco="", badge_status="", body=html_body, folder="."
        )
        (OUT / "mm-como-preencher.html").write_text(page_html, encoding="utf-8")

    # home / índice
    index_html = index_tpl.render(tables=tables, badge=badge)
    (OUT / "index.html").write_text(index_html, encoding="utf-8")

    # copiar anexos (PDFs) para o site, se existirem
    anexos_src = ROOT / "_anexos"
    if anexos_src.exists():
        shutil.copytree(anexos_src, OUT / "_anexos", dirs_exist_ok=True)

    # copiar fotos das plantas/itens, se existirem
    if IMAGES_DIR.exists():
        shutil.copytree(IMAGES_DIR, OUT / "_imagens", dirs_exist_ok=True)

    # css estático
    shutil.copy(Path(__file__).parent / "templates" / "style.css", OUT / "style.css")

    print(f"Site gerado em {OUT} — {sum(len(v) for v in tables.values())} fichas, "
          f"{len(notes)} notas no mapa de links.")


if __name__ == "__main__":
    main()
