# Build PDF documentation for the hcloud-k8s-cluster Terraform module.
#
#   make            # build every page + the combined manual into pdf/
#   make 02-architecture.pdf   # build a single page
#   make combined   # build only the combined manual
#   make clean      # remove generated PDFs

CONFIG      := pdf.config.js
OUT_DIR     := pdf
PAGES       := $(wildcard 0*-*.md)
PDFS        := $(addprefix $(OUT_DIR)/,$(PAGES:.md=.pdf))
COMBINED    := $(OUT_DIR)/hcloud-k8s-cluster-documentation.pdf

# Use a global md-to-pdf if available, else npx.
MDPDF := $(shell command -v md-to-pdf 2>/dev/null || echo "npx --yes md-to-pdf")

.PHONY: all combined clean
all: $(PDFS) combined

# One PDF per Markdown page.
$(OUT_DIR)/%.pdf: %.md $(CONFIG) assets/pdf.css | $(OUT_DIR)
	$(MDPDF) --config-file $(CONFIG) $<
	@mv $*.pdf $(OUT_DIR)/

# Convenience aliases so `make 02-architecture.pdf` works.
%.pdf: $(OUT_DIR)/%.pdf
	@:

combined: $(COMBINED)

$(COMBINED): $(PAGES) $(CONFIG) assets/pdf.css | $(OUT_DIR)
	@./build-pdf.sh >/dev/null

$(OUT_DIR):
	@mkdir -p $(OUT_DIR)

clean:
	rm -rf $(OUT_DIR)
