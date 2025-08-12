terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33.0"
    }
  }
}

# Provider Kubernetes
provider "kubernetes" {
  # Para clusters locais (kind, minikube)
  config_path    = var.kubeconfig_path
  config_context = var.kube_context

  # Para clusters remotos, use as variáveis comentadas abaixo:
  # host                   = var.kube_host
  # token                  = var.kube_token
  # cluster_ca_certificate = base64decode(var.kube_ca_certificate)
}

# Namespace para o projeto (opcional, pode usar default)
resource "kubernetes_namespace" "fortress_namespace" {
  count = var.create_namespace ? 1 : 0
  
  metadata {
    name = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-security"
      "app.kubernetes.io/component"  = "namespace"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}