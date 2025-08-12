# Outputs principais
output "namespace" {
  description = "Namespace onde os recursos foram criados"
  value       = local.namespace
}

output "fortress_service_name" {
  description = "Nome do service da fortaleza"
  value       = kubernetes_service.fortress_service.metadata[0].name
}

output "fortress_service_url" {
  description = "URL interna do service da fortaleza"
  value       = "http://${kubernetes_service.fortress_service.metadata[0].name}.${local.namespace}.svc.cluster.local:3000"
}

output "explorer_deployment_name" {
  description = "Nome do deployment do explorador"
  value       = kubernetes_deployment.explorer.metadata[0].name
}

output "fortress_deployment_name" {
  description = "Nome do deployment da fortaleza"
  value       = kubernetes_deployment.fortress_api.metadata[0].name
}

# Service Accounts
output "explorer_service_account" {
  description = "ServiceAccount do explorador"
  value       = kubernetes_service_account.explorer_sa.metadata[0].name
}

output "fortress_service_account" {
  description = "ServiceAccount da fortaleza"
  value       = kubernetes_service_account.fortress_sa.metadata[0].name
}

# Secrets
output "fortress_secret_name" {
  description = "Nome do secret da fortaleza"
  value       = kubernetes_secret.fortress_secret.metadata[0].name
  sensitive   = false
}

# ConfigMaps
output "fortress_config_name" {
  description = "Nome do ConfigMap da fortaleza"
  value       = kubernetes_config_map.fortress_config.metadata[0].name
}

# Network Policies
output "network_policies" {
  description = "Lista das Network Policies criadas"
  value = [
    kubernetes_network_policy.fortress_wall.metadata[0].name,
    kubernetes_network_policy.explorer_access.metadata[0].name,
    kubernetes_network_policy.default_deny_all.metadata[0].name,
    kubernetes_network_policy.allow_system_traffic.metadata[0].name
  ]
}

# RBAC Resources
output "rbac_resources" {
  description = "Recursos RBAC criados"
  value = {
    explorer_role         = kubernetes_role.explorer_role.metadata[0].name
    fortress_role         = kubernetes_role.fortress_role.metadata[0].name
    explorer_role_binding = kubernetes_role_binding.explorer_binding.metadata[0].name
    fortress_role_binding = kubernetes_role_binding.fortress_binding.metadata[0].name
    security_auditor_role = kubernetes_cluster_role.security_auditor.metadata[0].name
  }
}

# Comandos úteis para teste
output "test_commands" {
  description = "Comandos para testar a aplicação"
  value = {
    # Verificar pods
    check_pods = "kubectl get pods -n ${local.namespace} -o wide"
    
    # Verificar services
    check_services = "kubectl get services -n ${local.namespace}"
    
    # Verificar network policies
    check_network_policies = "kubectl get networkpolicies -n ${local.namespace}"
    
    # Testar acesso do explorador (autorizado)
    test_authorized_access = "kubectl exec -n ${local.namespace} deployment/${kubernetes_deployment.explorer.metadata[0].name} -- wget -qO- http://${kubernetes_service.fortress_service.metadata[0].name}:3000/secret"
    
    # Testar health check
    test_health_check = "kubectl exec -n ${local.namespace} deployment/${kubernetes_deployment.explorer.metadata[0].name} -- wget -qO- http://${kubernetes_service.fortress_service.metadata[0].name}:3000/health"
    
    # Testar acesso negado (pod não autorizado)
    test_unauthorized_access = "kubectl run unauthorized-pod --image=busybox:1.36 --restart=Never -n ${local.namespace} -- sh -c 'wget -qO- http://${kubernetes_service.fortress_service.metadata[0].name}:3000/secret || echo BLOCKED'"
    
    # Entrar no pod do explorador
    exec_explorer = "kubectl exec -it -n ${local.namespace} deployment/${kubernetes_deployment.explorer.metadata[0].name} -- sh"
    
    # Ver logs da fortaleza
    logs_fortress = "kubectl logs -n ${local.namespace} deployment/${kubernetes_deployment.fortress_api.metadata[0].name} -f"
    
    # Ver logs do explorador
    logs_explorer = "kubectl logs -n ${local.namespace} deployment/${kubernetes_deployment.explorer.metadata[0].name} -f"
  }
}

# Informações de debug
output "debug_info" {
  description = "Informações para debug e troubleshooting"
  value = {
    namespace_labels = var.create_namespace ? kubernetes_namespace.fortress_namespace[0].metadata[0].labels : {}
    
    fortress_selector = {
      app  = "fortress"
      tier = "backend"
    }
    
    explorer_selector = {
      app  = "explorer"
      tier = "client"
    }
    
    security_contexts = {
      user_id  = local.security_context_user
      group_id = local.security_context_user
    }
    
    ports = {
      fortress_port = local.network_config.fortress_port
    }
  }
}

# Status da aplicação
output "application_status" {
  description = "URLs e endpoints da aplicação"
  value = {
    health_endpoint = "http://${kubernetes_service.fortress_service.metadata[0].name}.${local.namespace}.svc.cluster.local:3000/health"
    secret_endpoint = "http://${kubernetes_service.fortress_service.metadata[0].name}.${local.namespace}.svc.cluster.local:3000/secret"
    fortress_service_ip = kubernetes_service.fortress_service.spec[0].cluster_ip
  }
}