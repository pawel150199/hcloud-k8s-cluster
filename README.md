# Private K8S cluster

The ideae behind this project is to create own private EKS cluster.

Cluster will be self managed and for the first creation it will be done by `k3s`

In hetzner community I found similar topic: https://community.hetzner.com/tutorials/setup-your-own-scalable-kubernetes-cluster

## Usefull links
1. https://github.com/solidnerd/terraform-k8s-hcloud -> setup cluster using terraform and kubeadm
2. https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner -> module for terraform to set up a scalable k8s in hcloud
3. https://alexslubsky.medium.com/setup-highly-available-kubernetus-cluster-with-hetzner-cloud-and-terraform-941a9e25ddf6 -> nice article about setting up k8s in hcloud.
4. https://registry.terraform.io/providers/hetznercloud/hcloud/latest -> terraform provider for hetzner cloud
5. https://community.hetzner.com/tutorials/setup-your-own-scalable-kubernetes-cluster -> tutorial how to setup your own scalable kubernetes cluster


## Requirements
1. Infrastructure have to be wrote in code - terraform.
2. Kubernetes cluster have to be set up automatically.
3. Kubernetes cluster will have one master node and 2 worker nodes.
4. Kubernetes will be set up using k3s.
5. Deployments to the cluster will be done using GitOps.
6. In K8S cluster will be deployed the full monitoring.


## Thoughts
1. In Hetzner cloud there is no native solution for storing terraform state file so I am storing it in AWS S3 service.
2. The same with locks, I am using dynamodb for that.


## Command for copying the kubeconfig from master node
```bash
scp -i <your_private_ssh_key> cluster@<master_node_public_ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```
