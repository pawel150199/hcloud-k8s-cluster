module "hcloud_kubernetes_cluster" {
    source = "../../"

    worker_nodes_number = 2
    master_nodes_number = 1

    node_image    = "ubuntu-24.04"
    node_type     = "cax11"
    node_location = "fsn1"

    node_enable_ipv4 = true
    node_enable_ipv6 = true

    ssh_keys = [ "you_ssh_key" ]

    master_nodes_ssh_pub_key  = "master_ssh_pub_key"
    worker_nodes_ssh_priv_key = "worker_ssh_priv_key"
    worker_nodes_ssh_pub_key  = "worker_ssh_pub_key"

    private_network_ip_range        = "10.0.0.0/16"
    private_network_zone            = "eu-central"
    private_network_type            = "cloud"
    private_network_subnet_ip_range = "10.0.1.0/24"
    master_node_ip                  = "10.0.1.1"
}