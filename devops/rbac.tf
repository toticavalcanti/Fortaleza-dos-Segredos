# ServiceAccount para o explorador (com permissões limitadas)
resource "kubernetes_service_account" "explorer_sa" {
  metadata {
    name      = "explorer-service-account"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "explorer-sa"
      "app.kubernetes.io/component"  = "rbac"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "explorer"
    }
    
    annotations = {
      "description" = "ServiceAccount para o pod explorador com permissões mínimas"
    }
  }
  
  automount_service_account_token = true
}

# ServiceAccount para a fortaleza (ainda mais restrito)
resource "kubernetes_service_account" "fortress_sa" {
  metadata {
    name      = "fortress-service-account"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-sa"
      "app.kubernetes.io/component"  = "rbac"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "fortress"
    }
    
    annotations = {
      "description" = "ServiceAccount para o pod da fortaleza (sem permissões especiais)"
    }
  }
  
  automount_service_account_token = false
}

# Role para o explorador - permissões mínimas necessárias
resource "kubernetes_role" "explorer_role" {
  metadata {
    name      = "explorer-role"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "explorer-role"
      "app.kubernetes.io/component"  = "rbac"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Permite apenas listar e obter informações de pods (para debugging)
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list"]
  }
  
  # Permite ler configmaps (se necessário para configuração)
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list"]
  }
  
  # Permite verificar status de services (para descoberta)
  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list"]
  }
}

# Role mais restritiva para a fortaleza (quase nenhuma permissão)
resource "kubernetes_role" "fortress_role" {
  metadata {
    name      = "fortress-role"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-role"
      "app.kubernetes.io/component"  = "rbac"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Apenas permissões de leitura para endpoints (para health checks)
  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get"]
  }
}

# RoleBinding conectando o explorador à sua role
resource "kubernetes_role_binding" "explorer_binding" {
  metadata {
    name      = "explorer-role-binding"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "explorer-binding"
      "app.kubernetes.io/component"  = "rbac"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.explorer_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.explorer_sa.metadata[0].name
    namespace = local.namespace
  }
}

# RoleBinding para a fortaleza
resource "kubernetes_role_binding" "fortress_binding" {
  metadata {
    name      = "fortress-role-binding"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-binding"
      "app.kubernetes.io/component"  = "rbac"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.fortress_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.fortress_sa.metadata[0].name
    namespace = local.namespace
  }
}

# ClusterRole para demonstrar permissões em nível de cluster (opcional)
resource "kubernetes_cluster_role" "security_auditor" {
  metadata {
    name = "security-auditor"
    
    labels = {
      "app.kubernetes.io/name"       = "security-auditor"
      "app.kubernetes.io/component"  = "rbac"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Permissões de auditoria (apenas leitura)
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }
}