# 6. Operations

Day-2 tasks for a running cluster.

## 6.1 Accessing the cluster

Copy the kubeconfig off the master and repoint it at the master's reachable IP:

```bash
scp -i ./master cluster@<master_public_ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i '' "s/127.0.0.1/<master_public_ip>/" ~/.kube/config   # macOS sed
kubectl get nodes -o wide
```

For a private-only setup, tunnel to the API server instead of exposing it:

```bash
ssh -i ./master -L 6443:10.0.1.1:6443 cluster@<master_public_ip>
# then use a kubeconfig pointing at https://127.0.0.1:6443
```

## 6.2 Verifying bootstrap

```bash
# on the master
sudo systemctl status k3s
sudo journalctl -u k3s -f

# on a worker
sudo systemctl status k3s-agent
sudo journalctl -u k3s-agent -f
```

Expected end state: `kubectl get nodes` shows the master plus
`worker_nodes_number` agents in `Ready`.

## 6.3 Scaling

The cluster size is parameterised — change the count and re-apply.

```mermaid
flowchart LR
  A["edit worker_nodes_number<br/>2 → 4"] --> B["terraform plan"]
  B --> C["terraform apply"]
  C --> D["2 new servers boot"]
  D --> E["cloud-init joins them<br/>to 10.0.1.1:6443"]
  E --> F["kubectl get nodes<br/>shows 4 workers"]
```

```bash
# scale workers up (or down)
terraform apply -var 'worker_nodes_number=4'
```

Scaling **down** removes the highest-indexed servers. Drain them first so
workloads reschedule cleanly:

```bash
kubectl drain worker-node-3 --ignore-daemonsets --delete-emptydir-data
terraform apply -var 'worker_nodes_number=3'
kubectl delete node worker-node-3     # remove the stale Node object
```

## 6.4 What to deploy next

The module deliberately ships a bare cluster (Traefik and the built-in cloud
controller are disabled). Typical next steps, ideally via GitOps:

| Concern | Options |
| --- | --- |
| Cloud controller | [hcloud-cloud-controller-manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager) (nodes already run `cloud-provider=external`) |
| CNI / networking | k3s ships Flannel by default; swap for Cilium/Calico if needed |
| Ingress | ingress-nginx, Traefik (re-enabled), or Gateway API |
| Storage | [hcloud-csi-driver](https://github.com/hetznercloud/csi-driver) for Hetzner Volumes |
| GitOps | Argo CD or Flux |
| Monitoring | kube-prometheus-stack (Prometheus + Grafana + Alertmanager) |

## 6.5 Teardown

```bash
terraform destroy
```

This removes the servers, subnet, and network. **State lives in S3** and is
unaffected — delete the state object separately if you're retiring the workspace.

> **Before destroying:** back up anything you need (PersistentVolumes, etc.).
> Hetzner Volumes and Load Balancers created *inside* the cluster by controllers
> are **not** managed by this module and may need separate cleanup.

Back to the [documentation index](README.md).
