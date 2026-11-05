#!/usr/bin/env bash
# =============================================================================
# gerar-dossie-reforma-tributaria.sh
# Gera automaticamente o Dossiê Executivo Financeiro da Reforma Tributária
# (IBS / CBS / IS) usando o Claude Code em modo headless (claude -p).
#
# Uso:
#   chmod +x gerar-dossie-reforma-tributaria.sh
#   ./gerar-dossie-reforma-tributaria.sh                 # usa a data de hoje
#   ./gerar-dossie-reforma-tributaria.sh 2026-11-03      # data de referência
#   MODEL=opus ./gerar-dossie-reforma-tributaria.sh      # escolhe o modelo
#
# Agendamento diário (cron, dias úteis às 08:00):
#   0 8 * * 1-5 cd /caminho/do/projeto && ./gerar-dossie-reforma-tributaria.sh >> logs/dossie.log 2>&1
#
# Requisitos: Claude Code instalado e autenticado (comando `claude`).
# =============================================================================
set -euo pipefail

# ---------- Configuração ------------------------------------------------------
DATA_REF="${1:-$(date +%Y-%m-%d)}"
DATA_BR="$(date -d "$DATA_REF" +%d/%m/%Y 2>/dev/null || date -j -f %Y-%m-%d "$DATA_REF" +%d/%m/%Y)"
OUT_DIR="${OUT_DIR:-./dossie-reforma-tributaria}"
OUT_FILE="dossie-reforma-tributaria-${DATA_REF}.html"
MODEL="${MODEL:-sonnet}"
MAX_TURNS="${MAX_TURNS:-60}"

mkdir -p "$OUT_DIR" "$OUT_DIR/logs"

command -v claude >/dev/null 2>&1 || {
  echo "ERRO: Claude Code não encontrado. Instale com: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
}

# ---------- Prompt ------------------------------------------------------------
read -r -d '' PROMPT <<EOF || true
Hoje é ${DATA_BR}. Gere o DOSSIÊ EXECUTIVO FINANCEIRO sobre a REFORMA TRIBUTÁRIA DO CONSUMO (IBS, CBS e Imposto Seletivo), atualizado até a data de hoje, e salve em: ${OUT_DIR}/${OUT_FILE}

==================== ETAPA 1 — PESQUISA ====================
Pesquise com WebSearch (e WebFetch quando permitido) as publicações mais recentes até ${DATA_BR}.
Fontes prioritárias:
  - Receita Federal (gov.br/receitafederal — Reforma Tributária do Consumo / Orientações 2026)
  - Comitê Gestor do IBS — CGIBS (cgibs.gov.br)
  - Ministério da Fazenda (gov.br/fazenda — Reforma Tributária / Regulamentação)
  - Portal Nacional de Tributação (consumo.tributos.gov.br)
  - Portal NF-e (Notas Técnicas), ENCAT, DOU
  - Entidades setoriais e jurídicas: Sindusfarma (sindusfarma.org.br), ABIHPEC (abihpec.org.br), ACESSA (acessa.org.br), Rayes & Fagundes Advogados (rayesfagundes.com.br), CMED/Anvisa
  - Comércio exterior: Portal Único Siscomex (DUIMP), Receita Federal (aduana)
Foco setorial (portfólio Genomma Lab no Brasil): OTC/MIPs (redução de 60%, art. 133 e condição CMED/compromisso do §2º; alíquota zero do art. 146), dermocosméticos (alíquota cheia, fim do monofásico e do ICMS-ST), sabonetes em barra e higiene básica (Anexo VIII), hidroeletrolíticos como Sorox (nome da marca no Brasil; em espanhol use Suerox) (NCM 2202, risco de Imposto Seletivo sobre bebidas açucaradas) e fórmulas infantis como Novamil (Anexo I, alíquota zero). Estime a CBS do ano seguinte por categoria a partir da alíquota de referência vigente.
Importação e exportação: cobrança de IBS/CBS na importação, DUIMP e desligamento da DI, base de cálculo, momento do pagamento, créditos (inclusive presumido sobre PIS/Cofins-Importação), imunidade na exportação e ressarcimento, comercial exportadora (art. 82), regimes aduaneiros especiais (drawback, Recof, ZPE, ZFM).
Regras:
  - Se rfb.gov.br ou cgibs.gov.br bloquearem acesso automatizado (robots), NÃO tente contornar: use os resultados de busca/snippets e portais espelho oficiais (gov.br, Ministério da Fazenda, DOU).
  - Cubra: regulamentos (Decreto da CBS, Resolução CGIBS do IBS, LC 214/2025, LC 227/2026), cronograma 2026–2033, Split Payment, DeRE, FCBF, Cashback, Cesta Básica, Simples Nacional, NF-e/CT-e/BP-e/NFS-e (campos IBS/CBS), prazos e marcos críticos, atos conjuntos RFB/CGIBS, notas técnicas.
  - Confirme datas críticas em mais de uma fonte (ex.: início da obrigatoriedade/rejeição dos campos IBS/CBS em agosto/2026 — verifique se é 01/08 ou 03/08 e use a data confirmada).
  - Não invente dados. Se algo não for confirmado, sinalize como "a confirmar".
  - Não reproduza textos longos das fontes: parafraseie.

==================== ETAPA 2 — DADOS (JSON) ====================
Estruture todo o conteúdo em um objeto JSON (fonte única de verdade) com chaves em duas línguas: { "pt": {...}, "es": {...} }.
Salve também uma cópia em ${OUT_DIR}/dados-${DATA_REF}.json.
Seções do JSON: meta (data de atualização, última publicação), kpis (6), novidades (cards com data, título, resumo, ato/norma e "links": lista de {tipo: "oficial"|"fonte", rotulo, url}; o primeiro link oficial deve apontar para o TEXTO INTEGRAL do ato — PDF no cgibs.gov.br (páginas /atos-tecnicos-conjuntos e /atos-conjuntos), Planalto, DOU ou Receita — e o selo do ato no card deve ser clicável e abrir esse link), cronograma (2026, 2027, 2028, 2029–2032, 2033), aliquotas (tabela), tributos (CBS, IBS, IS), mecanismos (pilares), impactos (Regime Regular, Simples Nacional, Financeiro/Seguros, Agro/ZFM/ICMS), genomma (intro, itens por categoria com enquadramento, base legal, CBS estimada, Imposto Seletivo, status confirmado/parcial e urgência; pontos transversais), comex (blocos Importação, Exportação, Regimes aduaneiros especiais, com itens marcados "a confirmar"), entidades (Sindusfarma, ABIHPEC, ACESSA, Rayes & Fagundes, CMED/Anvisa: papel, última publicação relevante, URL), checklist (itens com prazo), fontes (título + URL).

Inclua também, fora de "pt"/"es" (compartilhados):
  - "refs": catálogo { id: { n: nome curto, u: URL } } de todas as normas e fontes usadas;
  - "fontesItens": { "secao.indice": [ids de refs] } — TODO tópico/bullet (kpis, alíquotas, cronograma, tributos, mecanismos, impactos, genomma, transversais, comex, isipi) deve ter ao menos uma fonte;
  - não usar "prioridades": os cards não exibem painel de prioridade/prazo/status;
  - "legislacao": lista de normas { g: ec|lc|dec|res|ac|atc|proj, num, data, url (texto integral), desc: {pt, es} }.
Seções adicionais em pt/es: "isipi" (blocos Imposto Seletivo e IPI: base legal, MP/alíquotas, noventena, art. 454 da LC 214/2025, decreto da lista, PEC, impacto no portfólio) e novidades específicas de IS e IPI.

==================== ETAPA 3 — HTML/CSS/JS ====================
Gere UM único arquivo HTML autocontido (HTML + CSS + JavaScript + JSON embutido em <script type="application/json" id="dados">), que funcione offline (file://) sem fetch externo, exceto Google Fonts.

LAYOUT (inspirado no site da Genomma Lab Internacional — genommalab.com/pt):
  - Paleta do site genommalab.com: azul #3e8ede (escuro #2f6da4), ciano #45b8ea, azul de títulos #008cc4, hover #1b94d2, texto #231f20, seções alternadas #f3f8fd. Acento rosa #fa2891 só em detalhes (selos, marco crítico, item atual) e bolinhas de marca nas cores #fa2891 / #45b8ea / #ff7313 / #9ad858.
  - Tipografia: 'Montserrat' (Google Fonts) em tudo; títulos em peso 900 e caixa alta, rótulos em 600–700.
  - Cantos arredondados de 8px nos cards, botões e selos em pílula (border-radius 30px), sombras suaves; formas orgânicas (border-radius 250px 0 250px 0) como decoração.
  - Navegação fixa no topo, fundo branco, faixa inferior de 5px em gradiente #45b8ea→#008cc4, logo com 4 bolinhas coloridas + links em caixa alta.
  - Hero com fundo em gradiente claro, faixa inclinada (skew -20deg) em gradiente azul como kicker, título em 3 linhas (fina escura / azul 900 / gradiente ciano→rosa) e onda SVG azul na base.
  - Barra de alertas rolante (marquee) em gradiente azul com marcadores rosa.
  - Grid de KPIs em cards brancos com sombra, borda superior em gradiente animada no hover.
  - Cards de novidades com borda esquerda azul de 5px e selo "NOVO" rosa em pílula.
  - Linha do tempo vertical interativa (2026→2033) com tags em pílula, item atual destacado em rosa.
  - Tabela de alíquotas com cabeçalho em gradiente azul, cards de tributos, pilares com bordas superiores coloridas, barras de urgência em gradiente ciano→rosa.
  - Bloco de citação em gradiente azul com borda rosa; rodapé azul #3e8ede com texto branco.
  - Checklist interativo (clique marca como concluído) com contador "x / N itens concluídos".
  - Rodapé com disclaimer e data de atualização; botão flutuante de impressão em pílula; CSS de @media print.
  - Responsivo (900px e 600px) e animações de entrada (IntersectionObserver).

FUNCIONALIDADES JS:
  - Seletor de idioma 🇧🇷 PT | 🇪🇸 ES na navegação; renderiza TODO o conteúdo a partir do JSON embutido (nada fixo no HTML), inclusive title, lang do <html>, checklist e rodapé.
  - Contagem regressiva calculada em JavaScript até o marco crítico confirmado (usar new Date(), sem número fixo).
  - Persistir idioma e itens do checklist no localStorage (com try/catch).
  - Aba "Legislação": grupos recolhíveis por tipo (EC, LC, Decretos, Resoluções, Atos Conjuntos, Atos Técnicos Conjuntos, Projetos), ordenados por data decrescente, com descrição, link para o texto integral e campo de busca.
  - Links automáticos: toda menção a norma no texto (EC 132/2023, LC 214/2025, LC 227/2026, Decreto 12.955/2026, Resoluções, Atos) vira link para o texto integral.
  - Cada tópico exibe chips "Fontes" com links. Não exibir barra de urgência nem painel de prioridade/prazo/status nos cards (removido a pedido); antes era: substituir a barra de "urgência" por: selo de prioridade, próximo prazo com contagem de dias, barra de proximidade do prazo (janela de 180 dias, cor por faixa) e botões de status (Não iniciado / Em andamento / Concluído) salvos no localStorage, com legenda explicativa.

==================== ETAPA 4 — VERIFICAÇÃO ====================
  - Rode uma checagem (Bash) garantindo: arquivo existe e abre sem erros de sintaxe JS (ex.: node --check em trecho extraído, ou validação do JSON embutido com python -c json.loads); uso apenas da paleta definida (sem #e8005a); presença dos dois idiomas; todos os links de fontes com https.
  - Corrija o que falhar.

==================== SAÍDA FINAL ====================
Ao terminar, responda em português com: caminho dos arquivos gerados, as 5 principais novidades encontradas, o marco crítico confirmado e lista das fontes usadas. Seja breve.
EOF

# ---------- Execução ----------------------------------------------------------
LOG="$OUT_DIR/logs/execucao-${DATA_REF}.log"
echo ">> Gerando dossiê (ref. ${DATA_BR}) com modelo '${MODEL}'..."
echo ">> Log: ${LOG}"

claude -p "$PROMPT" \
  --model "$MODEL" \
  --max-turns "$MAX_TURNS" \
  --permission-mode acceptEdits \
  --allowedTools "WebSearch" "WebFetch" "Read" "Write" "Edit" "Glob" "Grep" \
                 "Bash(mkdir:*)" "Bash(node:*)" "Bash(python3:*)" "Bash(grep:*)" "Bash(ls:*)" "Bash(wc:*)" \
  --output-format text 2>&1 | tee "$LOG"

# ---------- Pós-processamento -------------------------------------------------
if [[ -f "$OUT_DIR/$OUT_FILE" ]]; then
  cp "$OUT_DIR/$OUT_FILE" "$OUT_DIR/dossie-reforma-tributaria-ATUAL.html"
  echo ">> OK: $OUT_DIR/$OUT_FILE"
  echo ">> Cópia estável: $OUT_DIR/dossie-reforma-tributaria-ATUAL.html"
  # Abre automaticamente se estiver em ambiente com interface gráfica
  if   command -v xdg-open >/dev/null 2>&1; then xdg-open "$OUT_DIR/$OUT_FILE" >/dev/null 2>&1 || true
  elif command -v open     >/dev/null 2>&1; then open "$OUT_DIR/$OUT_FILE" || true
  fi
else
  echo "ERRO: o arquivo $OUT_DIR/$OUT_FILE não foi gerado. Veja o log: $LOG" >&2
  exit 2
fi
