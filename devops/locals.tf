# Valores locais para reutilização
locals {
  # Namespace a ser usado (criado ou existente)
  namespace = var.create_namespace ? kubernetes_namespace.fortress_namespace[0].metadata[0].name : var.namespace

  # Labels comuns para todos os recursos
  common_labels = {
    "app.kubernetes.io/instance"   = "fortress-security"
    "app.kubernetes.io/part-of"    = "security-demo"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/version"    = "1.0.0"
  }

  # Configurações de segurança comuns
  security_context_user = 65534  # nobody user
  
  # Configurações de recursos padrão
  default_resources = {
    fortress = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    explorer = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }

  # Configurações de rede
  network_config = {
    fortress_port = 3000
    dns_policy    = "ClusterFirst"
  }

  # Configurações de probe
  probe_config = {
    readiness = {
      initial_delay = 10
      period        = 5
      timeout       = 3
      success       = 1
      failure       = 3
    }
    liveness = {
      initial_delay = 30
      period        = 10
      timeout       = 3
      success       = 1
      failure       = 3
    }
  }

  # Capabilities a serem removidas (security hardening)
  dropped_capabilities = [
    "ALL"
  ]

  # Anotações padrão para pods
  pod_annotations = {
    "security.alpha.kubernetes.io/sysctls"                = "net.core.somaxconn=1024"
    "container.apparmor.security.beta.kubernetes.io/fortress" = "runtime/default"
    "container.apparmor.security.beta.kubernetes.io/explorer" = "runtime/default"
  }

  # Seletores de nó padrão
  node_selector = {
    "kubernetes.io/os"   = "linux"
    "kubernetes.io/arch" = "amd64"
  }

  # Tolerations para nós específicos (se necessário)
  tolerations = [
    # Exemplo: tolera nós com taint de segurança
    # {
    #   key      = "security"
    #   operator = "Equal"
    #   value    = "restricted"
    #   effect   = "NoSchedule"
    # }
  ]

  # Configurações de volume
  volume_config = {
    tmp_size_limit     = "100Mi"
    var_tmp_size_limit = "50Mi"
  }

  # Configurações de ServiceAccount
  service_account_config = {
    fortress = {
      automount_token = false
      name           = "fortress-service-account"
    }
    explorer = {
      automount_token = true
      name           = "explorer-service-account"
    }
  }

  # Configurações de RBAC
  rbac_config = {
    explorer_permissions = [
      {
        api_groups = [""]
        resources  = ["pods", "services", "configmaps"]
        verbs      = ["get", "list"]
      }
    ]
    fortress_permissions = [
      {
        api_groups = [""]
        resources  = ["endpoints"]
        verbs      = ["get"]
      }
    ]
  }
}