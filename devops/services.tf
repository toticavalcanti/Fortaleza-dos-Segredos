# Service para a Fortaleza API
resource "kubernetes_service" "fortress_service" {
  metadata {
    name      = "fortress-service"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-service"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "fortress"
    }
    
    annotations = {
      "description"                               = "Service interno da Fortaleza"
      "service.alpha.kubernetes.io/tolerate-unready-endpoints" = "false"
    }
  }

  spec {
    # Seleciona pods da fortaleza
    selector = {
      app  = "fortress"
      tier = "backend"
    }

    type = "ClusterIP"  # Interno apenas
    
    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }

    # Configurações de sessão
    session_affinity = "ClientIP"
    session_affinity_config {
      client_ip {
        timeout_seconds = 10800  # 3 horas
      }
    }
  }
}

# Headless Service para descoberta de serviço (opcional)
resource "kubernetes_service" "fortress_headless" {
  metadata {
    name      = "fortress-headless"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-headless"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "fortress"
    }
    
    annotations = {
      "description" = "Headless service para descoberta direta dos pods"
    }
  }

  spec {
    selector = {
      app  = "fortress"
      tier = "backend"
    }

    cluster_ip = "None"  # Headless
    type       = "ClusterIP"
    
    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }
  }
}

# Service para o Explorador (para testes externos, se necessário)
resource "kubernetes_service" "explorer_service" {
  metadata {
    name      = "explorer-service"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "explorer-service"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "explorer"
    }
    
    annotations = {
      "description" = "Service do explorador (para acesso externo se necessário)"
    }
  }

  spec {
    selector = {
      app  = "explorer"
      tier = "client"
    }

    type = "ClusterIP"
    
    # Não expõe porta HTTP pois é apenas um cliente
    port {
      name        = "debug"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }
}

# Service Monitor para Prometheus (se disponível)
resource "kubernetes_manifest" "fortress_service_monitor" {
  count = 0  # Desabilitado por padrão - habilite se tiver Prometheus Operator
  
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "fortress-monitor"
      namespace = local.namespace
      labels = {
        "app.kubernetes.io/name"       = "fortress-monitor"
        "app.kubernetes.io/component"  = "monitoring"
        "app.kubernetes.io/managed-by" = "terraform"
        "app"                          = "fortress"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "fortress"
        }
      }
      endpoints = [{
        port     = "http"
        path     = "/health"
        interval = "30s"
      }]
    }
  }
}

# Endpoints para monitoramento externo (opcional)
resource "kubernetes_endpoints" "fortress_external_monitoring" {
  count = 0  # Desabilitado por padrão
  
  metadata {
    name      = "fortress-external-monitor"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-external-monitor"
      "app.kubernetes.io/component"  = "monitoring"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  subset {
    address {
      ip = "10.0.0.1"  # IP do sistema de monitoramento externo
    }
    
    port {
      name     = "monitoring"
      port     = 9090
      protocol = "TCP"
    }
  }
}

# Service para exposição externa via LoadBalancer (opcional)
resource "kubernetes_service" "fortress_external" {
  count = 0  # Desabilitado por padrão - habilite apenas se necessário
  
  metadata {
    name      = "fortress-external"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-external"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "fortress"
    }
    
    annotations = {
      "description"                                     = "Service externo da Fortaleza (use com cuidado)"
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"  # Para AWS
      "metallb.universe.tf/address-pool"               = "default"  # Para MetalLB
    }
  }

  spec {
    selector = {
      app  = "fortress"
      tier = "backend"
    }

    type = "LoadBalancer"
    
    port {
      name        = "http"
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }
    
    # Restricções de acesso por IP (se suportado pelo cloud provider)
    load_balancer_source_ranges = [
      "10.0.0.0/8",    # Rede interna
      "172.16.0.0/12", # Rede interna
      "192.168.0.0/16" # Rede interna
    ]
  }
}

# Service para debugging e desenvolvimento (NodePort)
resource "kubernetes_service" "fortress_debug" {
  count = 0  # Desabilitado por padrão - habilite apenas para desenvolvimento
  
  metadata {
    name      = "fortress-debug"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-debug"
      "app.kubernetes.io/component"  = "service"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "fortress"
      "environment"                  = "development"
    }
    
    annotations = {
      "description" = "Service de debug - APENAS PARA DESENVOLVIMENTO"
    }
  }

  spec {
    selector = {
      app  = "fortress"
      tier = "backend"
    }

    type = "NodePort"
    
    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      node_port   = 30080  # Porta específica no nó
      protocol    = "TCP"
    }
  }
}