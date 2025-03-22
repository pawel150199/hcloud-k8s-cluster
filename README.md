# Private K8S cluster

The ideae behing this project is to create own private EKS cluster.

Cluster will be self managed and for the first creation it will be done by `k3s`

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
