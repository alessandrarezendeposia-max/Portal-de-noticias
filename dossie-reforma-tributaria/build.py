#!/usr/bin/env python3
"""Monta o dossiê a partir do JSON de dados mais recente.

Uso:  python3 dossie-reforma-tributaria/build.py

Lê o dados-AAAA-MM-DD.json mais recente desta pasta, valida o conteúdo,
embute o JSON no template.html e grava:
  - dossie-reforma-tributaria-AAAA-MM-DD.html  (versão do dia, histórico)
  - dossie-reforma-tributaria-ATUAL.html       (sempre a mais recente)
  - ../docs/index.html                         (página publicada no GitHub Pages)
Sai com código 1 e lista os erros se a validação falhar (nada é gravado).
"""
import datetime
import json
import pathlib
import re
import sys

BASE = pathlib.Path(__file__).resolve().parent
DOCS = BASE.parent / "docs"
SECOES = ("meta", "ui", "kpis", "novidades", "genomma", "isipi", "cronograma",
          "aliquotas", "tributos", "mecanismos", "impactos", "comex", "checklist")
GRUPOS = ("ec", "lc", "dec", "res", "ac", "atc", "proj")


def data_iso(valor):
    try:
        datetime.date.fromisoformat(valor)
        return True
    except (TypeError, ValueError):
        return False


def validar(o):
    erros = []
    for lang in ("pt", "es"):
        bloco = o.get(lang)
        if not isinstance(bloco, dict):
            erros.append(f"falta o idioma '{lang}'")
            continue
        for s in SECOES:
            if s not in bloco:
                erros.append(f"{lang}: falta a seção '{s}'")
        nav = bloco.get("ui", {}).get("nav", [])
        if len(nav) != 11:
            erros.append(f"{lang}: ui.nav deve ter 11 itens (tem {len(nav)})")
        for n in bloco.get("novidades", []):
            if not n.get("links"):
                erros.append(f"{lang}: novidade sem links: {n.get('titulo')}")
    if len(o.get("pt", {}).get("novidades", [])) != len(o.get("es", {}).get("novidades", [])):
        erros.append("pt e es têm quantidades diferentes de novidades")

    refs = o.get("refs", {})
    for chave, ids in o.get("fontesItens", {}).items():
        for r in ids:
            if r not in refs:
                erros.append(f"fontesItens['{chave}']: ref inexistente '{r}'")

    for item in o.get("legislacao", []):
        if item.get("g") not in GRUPOS:
            erros.append(f"legislacao: grupo inválido em {item.get('num')}")
        if not data_iso(item.get("data")):
            erros.append(f"legislacao: data inválida em {item.get('num')}")
        if not isinstance(item.get("desc"), dict) or not item["desc"].get("pt") or not item["desc"].get("es"):
            erros.append(f"legislacao: descrição pt/es ausente em {item.get('num')}")

    for chave, p in o.get("prioridades", {}).items():
        if p.get("p") not in ("alta", "media", "baixa"):
            erros.append(f"prioridades['{chave}']: prioridade inválida")
        if not data_iso(p.get("prazo")):
            erros.append(f"prioridades['{chave}']: prazo inválido")

    urls = [r.get("u", "") for r in refs.values()]
    urls += [x.get("url", "") for x in o.get("legislacao", [])]
    for lang in ("pt", "es"):
        for n in o.get(lang, {}).get("novidades", []):
            urls += [x.get("url", "") for x in n.get("links", [])]
        urls += [f.get("url", "") for f in o.get(lang, {}).get("fontes", [])]
        urls += [e.get("url", "") for e in o.get(lang, {}).get("entidades", [])]
    for u in urls:
        if not u.startswith("https://"):
            erros.append(f"URL sem https: {u!r}")
    return erros


def main():
    arquivos = sorted(p for p in BASE.glob("dados-*.json") if re.fullmatch(r"dados-\d{4}-\d{2}-\d{2}\.json", p.name))
    if not arquivos:
        sys.exit("Nenhum dados-AAAA-MM-DD.json encontrado.")
    fonte = arquivos[-1]
    data = fonte.stem[len("dados-"):]
    texto = fonte.read_text(encoding="utf-8").strip()
    try:
        obj = json.loads(texto)
    except json.JSONDecodeError as e:
        sys.exit(f"{fonte.name}: JSON inválido: {e}")
    if "</script" in texto.lower():
        sys.exit(f"{fonte.name}: o JSON não pode conter '</script'.")
    erros = validar(obj)
    if erros:
        print(f"{fonte.name}: {len(erros)} erro(s) de validação:")
        for e in erros:
            print("  -", e)
        sys.exit(1)

    template = (BASE / "template.html").read_text(encoding="utf-8")
    if template.count("__DADOS__") != 1:
        sys.exit("template.html deve conter exatamente um marcador __DADOS__.")
    html = template.replace("__DADOS__", texto)

    (BASE / f"dossie-reforma-tributaria-{data}.html").write_text(html, encoding="utf-8")
    (BASE / "dossie-reforma-tributaria-ATUAL.html").write_text(html, encoding="utf-8")
    DOCS.mkdir(exist_ok=True)
    (DOCS / "index.html").write_text(html, encoding="utf-8")
    (DOCS / ".nojekyll").write_text("", encoding="utf-8")
    print(f"OK: {fonte.name} -> dossie-reforma-tributaria-{data}.html, ATUAL.html e docs/index.html")


if __name__ == "__main__":
    main()
