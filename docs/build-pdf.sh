#!/usr/bin/env bash
#
# Build PDF documentation for the hcloud-k8s-cluster Terraform module.
#
# Renders every Markdown page in this directory to its own PDF and also
# concatenates them into a single combined manual. Mermaid diagrams are rendered
# to vector graphics via docs/pdf.config.js (needs an internet connection).
#
# Usage:
#   ./build-pdf.sh            # build everything into docs/pdf/
#
# Requires: Node.js. Uses a global `md-to-pdf` if present, else `npx md-to-pdf`.

set -euo pipefail

cd "$(dirname "$0")"

OUT_DIR="pdf"
CONFIG="pdf.config.js"
COMBINED_MD="$OUT_DIR/_combined.md"
COMBINED_PDF="$OUT_DIR/hcloud-k8s-cluster-documentation.pdf"

# Ordered list of pages that make up the manual.
PAGES=(
  01-overview.md
  02-architecture.md
  03-getting-started.md
  04-usage-example.md
  05-inputs-and-outputs.md
  06-operations.md
)

# Resolve how to invoke md-to-pdf.
if command -v md-to-pdf >/dev/null 2>&1; then
  MDPDF=(md-to-pdf)
else
  echo "md-to-pdf not found on PATH — falling back to 'npx md-to-pdf'." >&2
  MDPDF=(npx --yes md-to-pdf)
fi

mkdir -p "$OUT_DIR"

echo "==> Rendering individual pages"
for page in "${PAGES[@]}"; do
  echo "    - $page"
  "${MDPDF[@]}" --config-file "$CONFIG" "$page"
  mv "${page%.md}.pdf" "$OUT_DIR/"
done

echo "==> Assembling combined manual"
: > "$COMBINED_MD"
{
  echo "# hcloud-k8s-cluster — Complete documentation"
  echo
  echo "> Private Kubernetes (k3s) cluster on Hetzner Cloud — Terraform module."
  echo
  echo '<div class="page-break"></div>'
  echo
} >> "$COMBINED_MD"

for page in "${PAGES[@]}"; do
  cat "$page" >> "$COMBINED_MD"
  printf '\n\n<div class="page-break"></div>\n\n' >> "$COMBINED_MD"
done

"${MDPDF[@]}" --config-file "$CONFIG" "$COMBINED_MD"
mv "${COMBINED_MD%.md}.pdf" "$COMBINED_PDF"
rm -f "$COMBINED_MD"

echo "==> Done. PDFs are in $OUT_DIR/"
ls -1 "$OUT_DIR"
