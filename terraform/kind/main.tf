terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4.0"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "aegis" {
  name           = "aegis-cluster"
  node_image     = "kindest/node:v1.30.0"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # Control Plane Node (Handles Ingress)
    node {
      role = "control-plane"
      
      kubeadm_config_patches = [
        <<-EOF
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        EOF
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }
      
      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }

    # Worker Node 1 (Handles Database Persistence)
    node {
      role = "worker"
      
      extra_mounts {
        host_path      = "/opt/gmao-database"
        container_path = "/var/lib/mysql-data"
      }
    }

    # Worker Node 2 (High Availability)
    node {
      role = "worker"
      
      extra_mounts {
        host_path      = "/opt/gmao-database"
        container_path = "/var/lib/mysql-data"
      }
    }
  }
}
