# Secret contendo a mensagem secreta da fortaleza
resource "kubernetes_secret" "fortress_secret" {
  metadata {
    name      = "fortress-secret"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-secret"
      "app.kubernetes.io/component"  = "secret"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "fortress"
    }
    
    annotations = {
      "description" = "Secret contendo a mensagem protegida da fortaleza"
    }
  }

  type = "Opaque"

  data = {
    message = var.secret_message
    api_key = base64encode("fortress-api-key-${random_password.api_key.result}")
  }
}

# Gera uma chave API aleatória para demonstrar uso de secrets
resource "random_password" "api_key" {
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# ConfigMap com configurações não sensíveis
resource "kubernetes_config_map" "fortress_config" {
  metadata {
    name      = "fortress-config"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-config"
      "app.kubernetes.io/component"  = "config"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "fortress"
    }
  }

  data = {
    port                = "3000"
    log_level          = "INFO"
    fortress_name      = "🏰 Fortaleza dos Segredos"
    welcome_message    = "Bem-vindo à área segura!"
    max_connections    = "100"
    timeout_seconds    = "30"
    health_check_path  = "/health"
    secret_path        = "/secret"
  }
}

# Secret adicional para demonstrar TLS (simulado)
resource "kubernetes_secret" "fortress_tls" {
  metadata {
    name      = "fortress-tls"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-tls"
      "app.kubernetes.io/component"  = "tls"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "kubernetes.io/tls"

  data = {
    # Em produção, use certificados reais
    "tls.crt" = base64encode("-----BEGIN CERTIFICATE-----\nSIMULATED CERTIFICATE\n-----END CERTIFICATE-----")
    "tls.key" = base64encode("-----BEGIN PRIVATE KEY-----\nSIMULATED PRIVATE KEY\n-----END PRIVATE KEY-----")
  }
}