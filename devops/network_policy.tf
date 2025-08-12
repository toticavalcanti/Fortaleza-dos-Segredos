# Network Policy - Muralha da Fortaleza
# Permite acesso à fortaleza apenas do explorador autorizado
resource "kubernetes_network_policy" "fortress_wall" {
  metadata {
    name      = "fortress-wall"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-wall"
      "app.kubernetes.io/component"  = "network-policy"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    
    annotations = {
      "description" = "Permite acesso à fortaleza apenas do explorador autorizado"
    }
  }

  spec {
    # Aplica a policy aos pods da fortaleza
    pod_selector {
      match_labels = {
        app  = "fortress"
        tier = "backend"
      }
    }

    # Define tipos de tráfego controlados
    policy_types = ["Ingress", "Egress"]

    # REGRAS DE ENTRADA (Ingress)
    ingress {
      # Permite acesso do explorador
      from {
        pod_selector {
          match_labels = {
            app  = "explorer"
            tier = "client"
          }
        }
      }

      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }

    # Permite health checks do sistema (kube-system)
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }

      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }

    # REGRAS DE SAÍDA (Egress)
    # Permite DNS
    egress {
      to {}
      
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    # Permite acesso ao Kubernetes API (para health checks)
    egress {
      to {}
      
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}

# Network Policy para o Explorador
# Define o que o explorador pode acessar
resource "kubernetes_network_policy" "explorer_access" {
  metadata {
    name      = "explorer-access"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "explorer-access"
      "app.kubernetes.io/component"  = "network-policy"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    
    annotations = {
      "description" = "Define acessos permitidos para o explorador"
    }
  }

  spec {
    # Aplica aos pods do explorador
    pod_selector {
      match_labels = {
        app  = "explorer"
        tier = "client"
      }
    }

    policy_types = ["Egress"]

    # REGRAS DE SAÍDA (Egress)
    # Permite acesso à fortaleza
    egress {
      to {
        pod_selector {
          match_labels = {
            app  = "fortress"
            tier = "backend"
          }
        }
      }

      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }

    # Permite DNS
    egress {
      to {}
      
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    # Permite HTTPS para downloads (se necessário)
    egress {
      to {}
      
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }

    # Permite HTTP para repositórios de pacotes
    egress {
      to {}
      
      ports {
        port     = "80"
        protocol = "TCP"
      }
    }
  }
}

# Network Policy padrão - DENY ALL (aplicada a todos os pods não especificados)
resource "kubernetes_network_policy" "default_deny_all" {
  metadata {
    name      = "default-deny-all"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "default-deny-all"
      "app.kubernetes.io/component"  = "network-policy"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    
    annotations = {
      "description" = "Política padrão que nega todo tráfego para pods não especificados"
    }
  }

  spec {
    # Aplica a todos os pods do namespace (exceto os que têm policies específicas)
    pod_selector {}

    # Nega tanto entrada quanto saída por padrão
    policy_types = ["Ingress", "Egress"]

    # Nenhuma regra = deny all
  }
}

# Network Policy para permitir tráfego interno do sistema
resource "kubernetes_network_policy" "allow_system_traffic" {
  metadata {
    name      = "allow-system-traffic"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "allow-system-traffic"
      "app.kubernetes.io/component"  = "network-policy"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    
    annotations = {
      "description" = "Permite tráfego necessário do sistema Kubernetes"
    }
  }

  spec {
    # Aplica a todos os pods
    pod_selector {}

    policy_types = ["Ingress", "Egress"]

    # Permite tráfego do kube-system para health checks
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }

    # Permite tráfego para o próprio namespace (comunicação interna)
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.namespace
          }
        }
      }
    }

    # Permite saída para DNS
    egress {
      to {}
      
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

# Network Policy avançada - Rate Limiting simulado via anotações
resource "kubernetes_network_policy" "rate_limiting" {
  count = 0  # Desabilitado por padrão - habilite se tiver CNI com suporte

  metadata {
    name      = "rate-limiting"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "rate-limiting"
      "app.kubernetes.io/component"  = "network-policy"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    
    annotations = {
      "description"                    = "Rate limiting para proteção contra DoS"
      "cilium.io/ingress-rate-limit"  = "100/s"  # Exemplo para Cilium CNI
      "calico.projectcalico.org/rate" = "100pps"  # Exemplo para Calico CNI
    }
  }

  spec {
    pod_selector {
      match_labels = {
        app = "fortress"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "explorer"
          }
        }
      }

      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }
  }
}