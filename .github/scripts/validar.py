#!/usr/bin/env python3
"""Valida as fichas da Matéria Médica: frontmatter YAML, campos obrigatórios por tipo,
[[wikilinks]] e anexos embutidos. Sai com código 1 se houver erro."""
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
IGNORAR = {"_templates", ".github", "_scripts", ".git"}

OBRIGATORIOS = {
    "planta": ["nome_comum", "nome_cientifico", "familia", "principios_ativos", "evidencia", "risco", "status", "revisado"],
    "farmaco": ["principio_ativo", "classe", "especies", "evidencia", "risco", "status", "revisado"],
    "composto": ["classe_quimica", "formula", "encontrado_em", "status", "revisado"],
    "homeopatico": ["nome_homeopatico", "origem", "evidencia_clinica", "status", "revisado"],
    "moc": [],
    "guia": [],
}
ESCALAS = {
    "evidencia": {"tradicional", "pre-clinica", "clinica-preliminar", "clinica-moderada", "clinica-forte"},
    "risco": {"baixo", "moderado", "alto"},
    "status": {"rascunho", "revisado"},
}

notas = [p for p in ROOT.rglob("*.md") if not (IGNORAR & set(p.relative_to(ROOT).parts)) and p.name != "README.md"]
nomes = {p.stem for p in ROOT.rglob("*.md")} | {p.name for p in ROOT.rglob("*") if p.is_file()}
erros = []

for p in notas:
    rel = p.relative_to(ROOT)
    texto = p.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", texto, re.S)
    if not m:
        erros.append(f"{rel}: sem frontmatter")
        continue
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError as e:
        erros.append(f"{rel}: YAML inválido ({str(e).splitlines()[0]})")
        continue
    tipo = fm.get("type")
    if tipo not in OBRIGATORIOS:
        erros.append(f"{rel}: type '{tipo}' desconhecido (use {', '.join(OBRIGATORIOS)})")
        continue
    for campo in OBRIGATORIOS[tipo]:
        if fm.get(campo) in (None, "", []):
            erros.append(f"{rel}: campo obrigatório vazio: {campo}")
    for campo, valores in ESCALAS.items():
        if campo in fm and fm[campo] not in (None, "") and fm[campo] not in valores:
            erros.append(f"{rel}: {campo}='{fm[campo]}' fora da escala ({', '.join(sorted(valores))})")
    corpo = re.sub(r"```.*?```", "", texto[m.end():], flags=re.S)
    for alvo in re.findall(r"!?\[\[([^\]|#]+)", m.group(1) + "\n" + corpo):
        alvo = alvo.strip()
        if alvo and alvo not in nomes:
            erros.append(f"{rel}: link sem destino [[{alvo}]]")

if erros:
    print(f"❌ {len(erros)} problema(s):")
    print("\n".join(f"  - {e}" for e in erros))
    sys.exit(1)
print(f"✅ {len(notas)} notas válidas")
