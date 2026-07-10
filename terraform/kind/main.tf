terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
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

provider "helm" {
  kubernetes {
    config_path = kind_cluster.aegis.kubeconfig_path
  }
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.10.1"

  # Specific settings required for Ingress to work with Kind port mapping
  set {
    name  = "controller.hostPort.enabled"
    value = "true"
  }
  set {
    name  = "controller.service.type"
    value = "NodePort"
  }
  set {
    name  = "controller.updateStrategy.type"
    value = "RollingUpdate"
  }

  depends_on = [kind_cluster.aegis]
}
