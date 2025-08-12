variable "namespace" {
  description = "Namespace onde os recursos serão criados"
  type        = string
  default     = "fortress-security"
}

variable "create_namespace" {
  description = "Se deve criar o namespace ou usar um existente"
  type        = bool
  default     = true
}

variable "secret_message" {
  description = "Mensagem secreta que será protegida pela fortaleza"
  type        = string
  default     = "🏰 Bem-vindo à Fortaleza dos Segredos! O DevOps seguro é nossa missão! 🔐"
  sensitive   = true
}

# Configuração do cluster Kubernetes (para conexão local)
variable "kubeconfig_path" {
  description = "Caminho para o arquivo kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Contexto do kubectl a ser usado"
  type        = string
  default     = null
}

# Configuração para clusters remotos (descomente se necessário)
# variable "kube_host" {
#   description = "Endpoint do cluster Kubernetes"
#   type        = string
# }

# variable "kube_token" {
#   description = "Token de acesso ao cluster Kubernetes"
#   type        = string
#   sensitive   = true
# }

# variable "kube_ca_certificate" {
#   description = "Certificado CA do cluster em base64"
#   type        = string
# }

# Configurações da aplicação
variable "fortress_image" {
  description = "Imagem Docker para a API da fortaleza"
  type        = string
  default     = "python:3.11-alpine"
}

variable "explorer_image" {
  description = "Imagem Docker para o explorador"
  type        = string
  default     = "busybox:1.36"
}

variable "fortress_replicas" {
  description = "Número de réplicas da fortaleza"
  type        = number
  default     = 1
  validation {
    condition     = var.fortress_replicas >= 1 && var.fortress_replicas <= 5
    error_message = "O número de réplicas deve estar entre 1 e 5."
  }
}

variable "explorer_replicas" {
  description = "Número de réplicas do explorador"
  type        = number
  default     = 1
  validation {
    condition     = var.explorer_replicas >= 1 && var.explorer_replicas <= 3
    error_message = "O número de réplicas deve estar entre 1 e 3."
  }
}

# Configurações de recursos
variable "fortress_resources" {
  description = "Recursos para os pods da fortaleza"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}

variable "explorer_resources" {
  description = "Recursos para os pods do explorador"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
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