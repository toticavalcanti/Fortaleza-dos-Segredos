# Deployment da Fortaleza (API que expõe o segredo)
resource "kubernetes_deployment" "fortress_api" {
  metadata {
    name      = "fortress-api"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "fortress-api"
      "app.kubernetes.io/component"  = "backend"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "fortress"
      "tier"                         = "backend"
    }
  }

  spec {
    replicas = var.fortress_replicas
    
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = 1
        max_surge       = 1
      }
    }

    selector {
      match_labels = {
        app  = "fortress"
        tier = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app  = "fortress"
          tier = "backend"
        }
        
        annotations = {
          "prometheus.io/scrape" = "false"
          "description"          = "Pod da API da Fortaleza com configurações de segurança"
        }
      }

      spec {
        # Usa ServiceAccount específico
        service_account_name            = kubernetes_service_account.fortress_sa.metadata[0].name
        automount_service_account_token = false

        # Security Context do Pod - aplicado a todos os containers
        security_context {
          # Executa como usuário não-root
          run_as_non_root = true
          run_as_user     = 65534  # nobody
          run_as_group    = 65534  # nobody
          fs_group        = 65534
          
          # Política seccomp padrão do runtime
          seccomp_profile {
            type = "RuntimeDefault"
          }
          
          # Suplementary groups
          supplemental_groups = [65534]
        }

        # Configurações de DNS para segurança
        dns_policy = "ClusterFirst"
        
        container {
          name  = "fortress"
          image = var.fortress_image
          
          # Comando que cria um servidor HTTP simples
          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
            set -e
            echo "🏰 Iniciando Fortaleza dos Segredos..."
            
            # Cria diretório de trabalho
            mkdir -p /tmp/fortress
            
            # Cria endpoint de saúde
            echo "OK" > /tmp/fortress/health
            
            # Cria endpoint com mensagem secreta
            echo "$SECRET_MESSAGE" > /tmp/fortress/secret
            
            # Cria um index simples
            cat > /tmp/fortress/index.html << 'EOF'
            <!DOCTYPE html>
            <html>
            <head><title>🏰 Fortaleza dos Segredos</title></head>
            <body>
            <h1>🏰 Fortaleza dos Segredos</h1>
            <p>Endpoints disponíveis:</p>
            <ul>
            <li><a href="/health">Health Check</a></li>
            <li><a href="/secret">Segredo (apenas para exploradores autorizados)</a></li>
            </ul>
            </body>
            </html>
            EOF
            
            echo "🚀 Servidor iniciado na porta 3000"
            cd /tmp/fortress && python -m http.server 3000
            EOT
          ]

          # Variáveis de ambiente
          env {
            name = "SECRET_MESSAGE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.fortress_secret.metadata[0].name
                key  = "message"
              }
            }
          }
          
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.fortress_secret.metadata[0].name
                key  = "api_key"
              }
            }
          }
          
          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.fortress_config.metadata[0].name
                key  = "port"
              }
            }
          }
          
          env {
            name = "LOG_LEVEL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.fortress_config.metadata[0].name
                key  = "log_level"
              }
            }
          }

          port {
            container_port = 3000
            name           = "http"
            protocol       = "TCP"
          }

          # Security Context específico do container
          security_context {
            # Não permite escalação de privilégios
            allow_privilege_escalation = false
            
            # Sistema de arquivos somente leitura
            read_only_root_filesystem = true
            
            # Remove todas as capabilities
            capabilities {
              drop = ["ALL"]
            }
            
            # Força usuário não-root (redundante, mas explícito)
            run_as_non_root = true
            run_as_user     = 65534
          }

          # Probes de saúde
          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            success_threshold     = 1
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 3
            success_threshold     = 1
            failure_threshold     = 3
          }

          # Recursos computacionais
          resources {
            limits = {
              cpu    = var.fortress_resources.limits.cpu
              memory = var.fortress_resources.limits.memory
            }
            requests = {
              cpu    = var.fortress_resources.requests.cpu
              memory = var.fortress_resources.requests.memory
            }
          }

          # Volume mounts (para contornar read-only filesystem)
          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
            read_only  = false
          }
          
          volume_mount {
            name       = "var-tmp"
            mount_path = "/var/tmp"
            read_only  = false
          }
        }

        # Volumes temporários
        volume {
          name = "tmp-volume"
          empty_dir {
            size_limit = "100Mi"
          }
        }
        
        volume {
          name = "var-tmp"
          empty_dir {
            size_limit = "50Mi"
          }
        }

        # Configurações adicionais de segurança
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        
        # Impede agendamento em nós não confiáveis
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
        
        # Tolerations e affinity podem ser configuradas aqui se necessário
      }
    }
  }
}

# Deployment do Explorador (cliente que pode acessar o segredo)
resource "kubernetes_deployment" "explorer" {
  metadata {
    name      = "explorer"
    namespace = local.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "explorer"
      "app.kubernetes.io/component"  = "client"
      "app.kubernetes.io/managed-by" = "terraform"
      "app"                          = "explorer"
      "tier"                         = "client"
    }
  }

  spec {
    replicas = var.explorer_replicas

    selector {
      match_labels = {
        app  = "explorer"
        tier = "client"
      }
    }

    template {
      metadata {
        labels = {
          app  = "explorer"
          tier = "client"
        }
        
        annotations = {
          "description" = "Pod explorador autorizado a acessar a fortaleza"
        }
      }

      spec {
        # Usa ServiceAccount com permissões limitadas
        service_account_name            = kubernetes_service_account.explorer_sa.metadata[0].name
        automount_service_account_token = true

        # Security Context do Pod
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          run_as_group    = 1000
          fs_group        = 1000
          
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "toolbox"
          image = var.explorer_image

          # Mantém o container rodando para testes manuais
          command = ["sh", "-c"]
          args = [
            <<-EOT
            echo "🔍 Explorador iniciado!"
            echo "Use 'kubectl exec' para acessar este pod"
            echo "Exemplo: wget -qO- http://fortress-service:3000/secret"
            
            # Instala ferramentas úteis (se disponível)
            which apk > /dev/null && apk add --no-cache curl wget || echo "apk não disponível"
            
            # Loop infinito para manter container ativo
            while true; do
              echo "🕐 $(date): Explorador aguardando comandos..."
              sleep 300
            done
            EOT
          ]

          # Security Context do container
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
            run_as_non_root = true
            run_as_user     = 1000
          }

          # Recursos mínimos
          resources {
            limits = {
              cpu    = var.explorer_resources.limits.cpu
              memory = var.explorer_resources.limits.memory
            }
            requests = {
              cpu    = var.explorer_resources.requests.cpu
              memory = var.explorer_resources.requests.memory
            }
          }

          # Volumes para contornar read-only filesystem
          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
            read_only  = false
          }
        }

        volume {
          name = "tmp-volume"
          empty_dir {
            size_limit = "50Mi"
          }
        }

        restart_policy = "Always"
        
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
      }
    }
  }
}