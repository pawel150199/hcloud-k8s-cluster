// md-to-pdf configuration for the hcloud-k8s-cluster documentation.
//
// This config teaches `md-to-pdf` to render Mermaid diagrams (```mermaid code
// blocks) into real vector graphics inside the PDF. `md-to-pdf` does not bundle
// Mermaid, so we inject it from a CDN at render time:
//
//   1. Rewrite every `<pre><code class="language-mermaid">` block into the
//      `<pre class="mermaid">` element Mermaid expects.
//   2. Load Mermaid from jsDelivr.
//   3. Run Mermaid over the page. Rendering finishes during md-to-pdf's built-in
//      `networkidle0` wait, before the PDF is printed.
//
// An internet connection is therefore required to build the PDFs. The Markdown
// sources render natively on GitHub (which understands ```mermaid) with no such
// dependency.

const { readFileSync } = require('node:fs');
const { join } = require('node:path');

module.exports = {
  stylesheet: [join(__dirname, 'assets', 'pdf.css')],

  // Inline the stylesheet content too, so relative asset paths never matter.
  css: readFileSync(join(__dirname, 'assets', 'pdf.css'), 'utf8'),

  script: [
    // 1. Convert fenced ```mermaid blocks into Mermaid's expected markup.
    {
      content: `
        document.querySelectorAll('pre > code.language-mermaid').forEach((el) => {
          const holder = document.createElement('pre');
          holder.className = 'mermaid';
          holder.textContent = el.textContent;
          el.parentElement.replaceWith(holder);
        });
      `,
    },
    // 2. Load Mermaid.
    { url: 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js' },
    // 3. Render all diagrams.
    {
      content: `
        mermaid.initialize({ startOnLoad: false, theme: 'neutral', securityLevel: 'loose' });
        window.__mermaidRun = mermaid.run();
      `,
    },
  ],

  pdf_options: {
    format: 'A4',
    margin: { top: '22mm', bottom: '20mm', left: '18mm', right: '18mm' },
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: `
      <div style="width:100%; font-size:8px; color:#8a8a8a; padding:0 18mm; font-family:sans-serif;">
        <span>hcloud-k8s-cluster — Terraform module documentation</span>
      </div>`,
    footerTemplate: `
      <div style="width:100%; font-size:8px; color:#8a8a8a; padding:0 18mm; font-family:sans-serif; display:flex; justify-content:space-between;">
        <span>Private Kubernetes cluster on Hetzner Cloud</span>
        <span>Page <span class="pageNumber"></span> / <span class="totalPages"></span></span>
      </div>`,
  },

  // Give diagrams a moment even on slow CDN responses.
  launch_options: { args: ['--no-sandbox', '--disable-setuid-sandbox'] },
};
