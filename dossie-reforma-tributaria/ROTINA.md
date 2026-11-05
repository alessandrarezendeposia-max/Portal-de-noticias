# Rotina diária — atualização do Dossiê da Reforma Tributária

Instruções para o agente agendado (dias úteis, 08:00 BRT). Objetivo: manter o dossiê fiel às fontes oficiais e setoriais, **sem mudar o layout**.

## Como o dossiê é montado

- `dados-AAAA-MM-DD.json` — todo o conteúdo (PT e ES) e os catálogos compartilhados. **É o único arquivo que a rotina edita.**
- `template.html` — layout, CSS e JavaScript. Contém o marcador `__DADOS__`. **Não alterar.**
- `build.py` — valida o JSON mais recente e gera `dossie-reforma-tributaria-AAAA-MM-DD.html`, `dossie-reforma-tributaria-ATUAL.html` e `../docs/index.html` (publicado no GitHub Pages).

## Passo a passo

1. Pegue o `dados-*.json` mais recente desta pasta. Leia `pt.meta.atualizacao` (data da última atualização) e o conteúdo atual.
2. Pesquise com WebSearch/WebFetch o que foi publicado **desde essa data** nas fontes abaixo. Se um site bloquear acesso automatizado, use os resultados de busca e portais oficiais espelho; não tente contornar bloqueios.
3. Se **nada relevante mudou**, não crie arquivos nem commit. Encerre informando "sem novidades".
4. Se houve mudança, copie o JSON para `dados-<HOJE>.json` (data de hoje, fuso America/Sao_Paulo) e edite **somente esse novo arquivo**:
   - `pt.meta.atualizacao` e `es.meta.atualizacao` = hoje (DD/MM/AAAA); atualize também a data em `pt.ui.heroTexto` e `es.ui.heroTexto` e `meta.ultimaPublicacao`.
   - **Novidades**: inclua as novas no topo de `pt.novidades` e `es.novidades` (mesma ordem e quantidade nos dois idiomas), com `novo: true` e `links` (o primeiro link `oficial` deve ser o **texto integral** do ato: PDF do cgibs.gov.br, Planalto, DOU, Receita). Mude para `novo: false` as que tiverem mais de 15 dias. Mantenha no máximo 16 novidades (remova as mais antigas).
   - **Legislação** (`legislacao`): inclua toda norma nova (grupo `ec|lc|mp|dec|res|ac|atc|proj` — `mp` = Medidas Provisórias, `num`, `data` AAAA-MM-DD, `url` do texto integral, `desc.pt` e `desc.es`). Quando uma medida "em tramitação" (`proj`) for publicada, mova-a para o grupo certo com o link oficial.
   - **"A confirmar"**: revise todos os itens marcados como a confirmar (`ok: false`, status `parcial`, textos com "a confirmar"/"por confirmar"). Se a fonte oficial confirmar, atualize o texto, marque `ok: true` e cite a fonte.
   - **Fontes**: todo dado novo precisa de fonte. Cadastre a fonte em `refs` (id curto, `n` nome curto, `u` URL https) e associe em `fontesItens` (chave `secao.indice`, ex.: `isipi.0.2`, `comex.1.0`, `genomma.3`, `impactos.2`).
   - Não use mais a seção `prioridades` (o painel de prioridade/prazo/status foi retirado dos cards).
   - **Prazos** (`checklist`, `meta.marco`, `meta.marcoSecundario`, `cronograma`): ajuste quando houver nova data oficial. Quando um marco passar, aponte para o próximo.
   - **Glossário** (`glossario`): toda sigla nova que aparecer no texto deve ser incluída com explicação em PT e ES.
   - Não invente dados. Parafraseie, não copie textos longos. Mantenha PT e ES equivalentes.
   - Nomes de marca: a bebida hidroeletrolítica da Genomma se chama **Sorox** no Brasil (use em `pt`) e **Suerox** em espanhol (use em `es`). Títulos de matérias externas mantêm o nome original.
5. Rode `python3 dossie-reforma-tributaria/build.py`. Se falhar, corrija o JSON e rode de novo até passar.
6. Faça commit apenas de `dossie-reforma-tributaria/dados-<HOJE>.json`, `dossie-reforma-tributaria/dossie-reforma-tributaria-<HOJE>.html`, `dossie-reforma-tributaria/dossie-reforma-tributaria-ATUAL.html` e `docs/` com a mensagem `Dossiê: atualização de <HOJE>` e um resumo das novidades no corpo. Envie (push) para a branch `main`.
7. Termine com um resumo curto: novidades incluídas, normas novas, itens "a confirmar" resolvidos e prazos alterados.

## Fontes a verificar

Atenção a publicações em **edição extra do DOU à noite** (como a MP 1.399/2026, publicada às 22h de 04/11/2026): sempre confira as notícias da Casa Civil e as medidas provisórias recentes no Planalto (https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2026/mpv/) desde a última atualização.

- Casa Civil — notícias: https://www.gov.br/casacivil/pt-br/assuntos/noticias

- Comitê Gestor do IBS: https://cgibs.gov.br/atos-tecnicos-conjuntos e https://cgibs.gov.br/atos-conjuntos (comparar com `legislacao`; atos novos entram com o PDF)
- Receita Federal — Reforma Tributária do Consumo e notícias: https://www.gov.br/receitafederal/pt-br/assuntos/noticias
- Ministério da Fazenda (reforma tributária), Planalto (leis, decretos, medidas provisórias), Diário Oficial da União
- Portal da NF-e (notas técnicas), Portal Único Siscomex (DUIMP)
- Senado e Câmara (resolução da alíquota da CBS, MP do Imposto Seletivo, PEC do IPI, PLP 42/2026)
- TCU (alíquota de referência da CBS)
- Setoriais: Sindusfarma, ABIHPEC, ACESSA, CMED/Anvisa, Rayes & Fagundes Advogados
- Temas prioritários: Imposto Seletivo (MP, alíquotas, bebidas açucaradas), IPI (decreto com a lista de produtos, ZFM), medicamentos/MIPs (compromisso CMED), HPPC (Anexo VIII), fórmulas infantis, importação/exportação, split payment, prazos do Simples e das cooperativas.
