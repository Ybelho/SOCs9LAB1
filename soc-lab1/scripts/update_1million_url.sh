#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="$ROOT/data"
mkdir -p "$DATA"

PERMA_URL="https://tranco-list.eu/top-1m.csv.zip"
ZIP="$DATA/top1m.csv.zip"
CSV="$DATA/top1m.csv"
OUT_LIST="$DATA/top1m_domains.txt"
OUT_META="$DATA/top1m_meta.txt"

command -v curl >/dev/null || { echo "curl manquant"; exit 1; }
command -v unzip >/dev/null || { echo "unzip manquant (sudo apt-get install unzip)"; exit 1; }

echo "[*] Checking Last-Modified..."
LAST_REMOTE=$(curl -fsI "$PERMA_URL" | awk -F': ' 'tolower($1)=="last-modified"{print $2}' | tr -d '\r')
if [[ -z "${LAST_REMOTE:-}" ]]; then
  echo "[-] Impossible de lire Last-Modified. Téléchargement par défaut."
fi

if [[ -f "$OUT_META" ]] && [[ -n "${LAST_REMOTE:-}" ]] && grep -q "LAST_MODIFIED=$LAST_REMOTE" "$OUT_META"; then
  echo "[*] Déjà à jour ($LAST_REMOTE)."
  exit 0
fi

echo "[*] Téléchargement de la liste Tranco (1M)..."
curl -fSL "$PERMA_URL" -o "$ZIP"

echo "[*] Décompression..."
rm -f "$CSV"
unzip -p "$ZIP" > "$CSV"

# Format attendu: rank,domain  -> on garde la 2e colonne
echo "[*] Extraction des domaines..."
tail -n +2 "$CSV" | cut -d',' -f2 > "$OUT_LIST"

{
  echo "SOURCE=$PERMA_URL"
  if [[ -n "${LAST_REMOTE:-}" ]]; then
    echo "LAST_MODIFIED=$LAST_REMOTE"
  fi
  echo "DOWNLOADED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
} > "$OUT_META"

echo "[+] Mis à jour : $OUT_LIST"
