#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  13proof.sh — Proofreader Audit v5.0.0 (standalone)
#  Audit documentazione a 6 fasi — compatibile Claude CLI e Gemini CLI
#  Uso: ./13proof.sh <file> [--engine claude|gemini] [--model <id>]
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

VERSION="5.0.0"

usage() {
  echo -e "${BOLD}13proof.sh${RESET} v${VERSION} — Audit documentazione a 6 fasi"
  echo ""
  echo -e "  Uso: ${CYAN}./13proof.sh <file>${RESET} [opzioni]"
  echo ""
  echo -e "  ${BOLD}Motore AI:${RESET}"
  echo -e "    ${BOLD}--engine${RESET} <name>  ${DIM}claude${RESET} o ${DIM}gemini${RESET} (default: auto-detect)"
  echo -e "    ${BOLD}--model${RESET} <id>     Modello specifico (default: dipende dal motore)"
  echo ""
  echo -e "  ${BOLD}Output:${RESET}"
  echo -e "    ${BOLD}--output${RESET} <dir>   Directory output (default: stessa del file)"
  echo -e "    ${BOLD}--format${RESET} <fmt>   Formati report: md, json, html, all (default: md)"
  echo ""
  echo -e "  ${BOLD}Altro:${RESET}"
  echo -e "    ${BOLD}--help${RESET}           Mostra questo messaggio"
  echo -e "    ${BOLD}--version${RESET}        Mostra versione"
  echo ""
  echo -e "  ${BOLD}Esempi:${RESET}"
  echo -e "    ./13proof.sh docs/README.md"
  echo -e "    ./13proof.sh docs/README.md --engine gemini"
  echo -e "    ./13proof.sh docs/API.md --engine claude --model claude-sonnet-4-6"
  echo -e "    ./13proof.sh docs/API.md --engine gemini --model gemini-2.5-pro"
  echo -e "    ./13proof.sh docs/API.md --format all --output ./reports"
  exit 0
}

# ── Auto-detect engine ──────────────────────────────────────────────────────

detect_engine() {
  if command -v claude &>/dev/null; then
    echo "claude"
  elif command -v gemini &>/dev/null; then
    echo "gemini"
  else
    echo "none"
  fi
}

default_model_for() {
  case "$1" in
    claude) echo "claude-opus-4-6" ;;
    gemini) echo "gemini-2.5-pro" ;;
    *)      echo "" ;;
  esac
}

# ── Parse argomenti ──────────────────────────────────────────────────────────

TARGET_FILE=""
ENGINE=""
MODEL=""
OUTPUT_DIR=""
FORMAT="md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)    ENGINE="$2"; shift 2 ;;
    --model)     MODEL="$2"; shift 2 ;;
    --output)    OUTPUT_DIR="$2"; shift 2 ;;
    --format)    FORMAT="$2"; shift 2 ;;
    --version)   echo "13proof.sh v${VERSION}"; exit 0 ;;
    --help|-h)   usage ;;
    -*)          echo -e "${RED}Flag sconosciuto: $1${RESET}"; usage ;;
    *)           TARGET_FILE="$1"; shift ;;
  esac
done

# ── Validazione ─────────────────────────────────────────────────────────────

if [[ -z "${TARGET_FILE}" ]]; then
  echo -e "${RED}Errore:${RESET} specificare il file da revisionare."
  echo ""
  usage
fi

if [[ ! -f "${TARGET_FILE}" ]]; then
  echo -e "${RED}Errore:${RESET} file '${TARGET_FILE}' non trovato."
  exit 1
fi

# Engine: se non specificato, auto-detect
if [[ -z "${ENGINE}" ]]; then
  ENGINE=$(detect_engine)
  if [[ "${ENGINE}" == "none" ]]; then
    echo -e "${RED}Errore:${RESET} nessun motore AI trovato."
    echo -e "  Installa uno dei seguenti:"
    echo -e "    ${BOLD}Claude Code:${RESET}  npm install -g @anthropic-ai/claude-code"
    echo -e "    ${BOLD}Gemini CLI:${RESET}   npm install -g @anthropic-ai/gemini-cli  ${DIM}(o vedi docs.google.com)${RESET}"
    exit 1
  fi
fi

# Validazione engine
case "${ENGINE}" in
  claude)
    if ! command -v claude &>/dev/null; then
      echo -e "${RED}Errore:${RESET} 'claude' CLI non trovato."
      echo -e "  Installa: ${BOLD}npm install -g @anthropic-ai/claude-code${RESET}"
      exit 1
    fi
    ;;
  gemini)
    if ! command -v gemini &>/dev/null; then
      echo -e "${RED}Errore:${RESET} 'gemini' CLI non trovato."
      echo -e "  Installa: ${BOLD}npm install -g @anthropic-ai/gemini-cli${RESET} o segui le istruzioni Google"
      exit 1
    fi
    ;;
  *)
    echo -e "${RED}Errore:${RESET} engine '${ENGINE}' non supportato. Usa 'claude' o 'gemini'."
    exit 1
    ;;
esac

# Model: se non specificato, usa default per engine
[[ -z "${MODEL}" ]] && MODEL=$(default_model_for "${ENGINE}")

# ── Percorsi output ──────────────────────────────────────────────────────────

BASENAME=$(basename "${TARGET_FILE}")
NAME="${BASENAME%.*}"
EXT="${BASENAME##*.}"
DIR=$(dirname "$(realpath "${TARGET_FILE}")")

[[ -n "${OUTPUT_DIR}" ]] && DIR="${OUTPUT_DIR}"
mkdir -p "${DIR}"

CORRECTED="${DIR}/${NAME}_proofread.${EXT}"
REPORT_MD="${DIR}/${NAME}_audit_report.md"
REPORT_JSON="${DIR}/${NAME}_audit_report.json"
REPORT_HTML="${DIR}/${NAME}_audit_report.html"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Proofreader Audit v${VERSION}                          ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}File:${RESET}     ${TARGET_FILE}"
echo -e "  ${CYAN}Engine:${RESET}   ${ENGINE}"
echo -e "  ${CYAN}Model:${RESET}    ${MODEL}"
echo -e "  ${CYAN}Format:${RESET}   ${FORMAT}"
echo -e "  ${CYAN}Output:${RESET}   ${DIR}/"
echo ""

# ── Prompt strutturato per le 6 fasi ────────────────────────────────────────

build_prompt() {
  local target="$1" corrected="$2" report="$3" fmt="$4"

  local output_instruction=""
  case "${fmt}" in
    json)
      output_instruction="Salva il report di audit SOLO in formato JSON come: ${REPORT_JSON}
Il JSON deve avere questa struttura: {\"file\": \"...\", \"date\": \"...\", \"score\": N, \"critical\": N, \"major\": N, \"minor\": N, \"findings\": [{\"id\": \"F001\", \"stage\": N, \"category\": \"...\", \"severity\": \"...\", \"line\": N, \"description\": \"...\", \"correction\": \"...\"}], \"strengths\": [...], \"improvements\": [...]}" ;;
    html)
      output_instruction="Salva il report di audit come pagina HTML self-contained: ${REPORT_HTML}
Includi: gauge score colorato, tabella finding ordinabile, breakdown per categoria, stile dark mode professionale." ;;
    all)
      output_instruction="Salva il report in TRE formati:
1. Markdown: ${REPORT_MD}
2. JSON: ${REPORT_JSON} (struttura: {file, date, score, critical, major, minor, findings[], strengths[], improvements[]})
3. HTML: ${REPORT_HTML} (dashboard self-contained con gauge, tabella, grafici)" ;;
    *)
      output_instruction="Salva il report di audit come: ${report}" ;;
  esac

  cat <<PROMPT_EOF
Sei un auditor tecnico di documentazione. Esegui una revisione strutturata in 6 fasi del file che ti indico.

## Pipeline a 6 fasi

### Fase 0 — Evidence Gathering
Leggi il file target e indicizza: struttura (headings, sezioni, lunghezza), terminologia tecnica, blocchi di codice, riferimenti a file esterni. Ogni finding successivo DEVE citare la riga o sezione di origine.

### Fase 1 — Trasparenza e Sicurezza
Controlla: (1) Trasparenza AI — il documento dichiara se generato/assistito da AI? (2) Sicurezza — nessun dato sensibile esposto (API key, password, path privati). (3) Bias — esempi tecnici neutri e inclusivi. Severità: Critico/Maggiore/Minore.

### Fase 2 — Sincronizzazione Codice
Per ogni blocco di codice: verifica sintassi, confronta affermazioni con codice reale nel progetto, segnala codice obsoleto o API cambiate.

### Fase 3 — Audit Qualità (MQM)
Valutazione analitica: Accuratezza, Fluenza (grammatica/ortografia), Terminologia (consistenza), Stile (tono appropriato), Completezza (sezioni mancanti). Per ogni errore: categoria, severità, riga, descrizione.

### Fase 4 — Revisione Multi-Prospettiva
Simula tre punti di vista per finding Critico e Maggiore: (1) Architetto Senior — correttezza tecnica, (2) Technical Writer — chiarezza per il pubblico target, (3) Revisore Compliance — rischi sicurezza/privacy/licenze. Solo finding confermati da almeno 2/3 prospettive vanno nel report.

### Fase 5 — Output Finale

Revisiona il seguente file: ${target}

Salva il documento corretto come: ${corrected}
${output_instruction}

## Regole
- Ogni modifica DEVE essere tracciabile (riga + motivo)
- Lingua del report = lingua del documento
- Non inventare problemi: se il documento è buono, dillo
PROMPT_EOF
}

FULL_PROMPT=$(build_prompt "${TARGET_FILE}" "${CORRECTED}" "${REPORT_MD}" "${FORMAT}")

# ── Esecuzione ───────────────────────────────────────────────────────────────

echo -e "${CYAN}[13proof]${RESET} Avvio audit 6 fasi con ${BOLD}${ENGINE}/${MODEL}${RESET}..."
echo -e "${DIM}  Questo può richiedere qualche minuto per documenti lunghi.${RESET}"
echo ""

case "${ENGINE}" in
  claude)
    claude --model "${MODEL}" --print "${FULL_PROMPT}" 2>&1
    ;;
  gemini)
    gemini --model "${MODEL}" --print "${FULL_PROMPT}" 2>&1
    ;;
esac

# ── Verifica output ─────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}─── Risultato ───${RESET}"

if [[ -f "${CORRECTED}" ]]; then
  echo -e "  ${GREEN}✔${RESET}  Documento corretto: ${CORRECTED}"
else
  echo -e "  ${YELLOW}⚠${RESET}  Documento corretto non generato (il file potrebbe non aver bisogno di correzioni)"
fi

check_report() {
  local path="$1" label="$2"
  if [[ -f "${path}" ]]; then
    echo -e "  ${GREEN}✔${RESET}  ${label}: ${path}"
  fi
}

case "${FORMAT}" in
  md)   check_report "${REPORT_MD}" "Report MD" ;;
  json) check_report "${REPORT_JSON}" "Report JSON" ;;
  html) check_report "${REPORT_HTML}" "Report HTML" ;;
  all)
    check_report "${REPORT_MD}" "Report MD"
    check_report "${REPORT_JSON}" "Report JSON"
    check_report "${REPORT_HTML}" "Report HTML"
    ;;
esac

echo ""
