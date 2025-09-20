module "kubernetes_cluster" {
    source = "../"

    ssh_keys             = "TODO"
    master_nodes_ssh_key = "TODO"
    worker_nodes_ssh_key = "TODO"
}