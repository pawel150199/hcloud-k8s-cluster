# hcloud-k8s-cluster — Documentation

Terraform module that provisions a self-managed **[k3s](https://k3s.io/)
Kubernetes cluster on [Hetzner Cloud](https://www.hetzner.com/cloud)**: one (or
more) master nodes and a configurable number of worker nodes, all joined over a
private Hetzner network.

This folder contains the full documentation for the module. Every page renders
Mermaid diagrams natively on GitHub and can also be exported to PDF (see
[Building the PDFs](#building-the-pdfs)).

---

## Table of contents

| # | Document | What's inside |
|---|----------|---------------|
| 1 | [Overview](01-overview.md) | What the module does, goals, and scope |
| 2 | [Architecture](02-architecture.md) | Diagrams: components, network topology, bootstrap sequence |
| 3 | [Getting started](03-getting-started.md) | Prerequisites, providers, remote state, first apply |
| 4 | [Usage example](04-usage-example.md) | A complete, copy-pasteable example |
| 5 | [Inputs & outputs](05-inputs-and-outputs.md) | Full variable and output reference |
| 6 | [Operations](06-operations.md) | kubeconfig, day-2 tasks, scaling, teardown |

---

## Quick start

```hcl
module "hcloud_kubernetes_cluster" {
  source = "github.com/pawel-polski/hcloud-k8s-cluster"

  master_nodes_number = 1
  worker_nodes_number = 2

  ssh_keys                 = ["my-hcloud-ssh-key"]
  master_nodes_ssh_pub_key = file("~/.ssh/master.pub")
  worker_nodes_ssh_pub_key = file("~/.ssh/worker.pub")
  worker_nodes_ssh_priv_key = file("~/.ssh/worker")
}
```

See the [usage example](04-usage-example.md) for the full configuration, and
[getting started](03-getting-started.md) for the provider and backend setup that
must accompany it.

---

## Building the PDFs

The docs use [`md-to-pdf`](https://github.com/simonhaenisch/md-to-pdf) (a
headless-Chromium Markdown→PDF converter) together with a small config that
injects [Mermaid](https://mermaid.js.org/) so diagrams render as vector
graphics.

### Prerequisites

- **Node.js** ≥ 16
- **`md-to-pdf`** — install once: `npm install -g md-to-pdf`
- An **internet connection** at build time (Mermaid is loaded from a CDN)

### Build

```bash
cd docs

# Build every page + a single combined PDF into docs/pdf/
make            # or: ./build-pdf.sh

# Build just one page
make 02-architecture.pdf

# Remove generated PDFs
make clean
```

Output lands in `docs/pdf/`:

- `01-overview.pdf` … `06-operations.pdf` — one PDF per page
- `hcloud-k8s-cluster-documentation.pdf` — the complete manual, combined

> **Note.** If you don't have `md-to-pdf` and don't want a global install, the
> build script falls back to `npx md-to-pdf`, which downloads it on first run.

---

## Diagram tooling

Diagrams are written as fenced ` ```mermaid ` code blocks directly inside the
Markdown. This means:

- **On GitHub / GitLab / VS Code** they render automatically — no tooling.
- **In the PDF** they are rendered by Mermaid via `docs/pdf.config.js`.

No binary image files are committed, so the diagrams stay diffable and reviewable
in pull requests.
