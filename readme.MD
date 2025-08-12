# 🏰 Fortaleza dos Segredos - Kubernetes Security Demo

Este projeto demonstra as melhores práticas de segurança no Kubernetes através de um cenário lúdico onde uma "fortaleza" protege um segredo que só pode ser acessado por um "explorador" autorizado.

## 🎯 Objetivos de Aprendizado

- **RBAC (Role-Based Access Control)**: Implementar o princípio do menor privilégio
- **ServiceAccounts**: Dar identidade específica aos pods
- **NetworkPolicies**: Isolar tráfego entre serviços
- **SecurityContext**: Endurecer contêineres (sem root, readonly filesystem)
- **Secrets**: Proteger dados sensíveis
- **Resource Limits**: Controlar uso de recursos

## 🏗️ Arquitetura

```
┌─────────────────┐    NetworkPolicy    ┌─────────────────┐
│   Explorador    │ ──────────────────> │   Fortaleza     │
│  (Autorizado)   │      PERMITE        │    (API)        │
│                 │                     │                 │
│ ServiceAccount  │                     │ ServiceAccount  │
│ + RBAC Role     │                     │ + Minimal RBAC  │
└─────────────────┘                     └─────────────────┘
                                                │
                                                │ lê
                                                ▼
                                        ┌─────────────────┐
                                        │     Secret      │
                                        │ (mensagem       │
                                        │  protegida)     │
                                        └─────────────────┘

┌─────────────────┐    NetworkPolicy
│   Pod Intruso   │ ──────X──────────> Fortaleza (BLOQUEADO)
│ (Não autorizado)│
└─────────────────┘
```

## 📁 Estrutura do Projeto

```
terraform-k8s-security/
├── main.tf                 # Provider e configuração principal
├── variables.tf            # Variáveis do projeto
├── locals.tf              # Valores locais e utilitários
├── secrets.tf             # Secrets e ConfigMaps
├── rbac.tf                # ServiceAccounts, Roles e RoleBindings
├── deployments.tf         # Deployments com SecurityContext
├── services.tf            # Services e exposição
├── network_policy.tf      # Políticas de rede
├── outputs.tf             # Outputs e comandos úteis
├── terraform.tfvars.example  # Exemplo de configuração
└── README.md              # Esta documentação
```

## 🚀 Como Usar

### 1. Pré-requisitos

- Terraform >= 1.0
- Cluster Kubernetes funcionando
- kubectl configurado
- CNI que suporte NetworkPolicies (Calico, Cilium, etc.)

### 2. Configuração

```bash
# Clone ou baixe os arquivos do projeto
cd terraform-k8s-security

# Copie o arquivo de exemplo e configure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Ajuste conforme seu ambiente
```

### 3. Deploy

```bash
# Inicializar Terraform
terraform init

# Planejar mudanças
terraform plan

# Aplicar configurações
terraform apply
```

### 4. Teste da Segurança

#### ✅ Teste Autorizado (deve funcionar)

```bash
# Pegar nome do pod explorador
kubectl get pods -n fortress-security -l app=explorer

# Acessar o segredo do explorador (autorizado)
kubectl exec -n fortress-security deployment/explorer -- \
  wget -qO- http://fortress-service:3000/secret

# Resultado esperado: Mensagem secreta é exibida
```

#### ❌ Teste Não Autorizado (deve ser bloqueado)

```bash
# Criar pod intruso
kubectl run intruso --image=busybox:1.36 --restart=Never -n fortress-security -- \
  sh -c "wget -qO- http://fortress-service:3000/secret || echo 'ACESSO BLOQUEADO'"

# Verificar logs
kubectl logs intruso -n fortress-security

# Resultado esperado: Timeout ou erro de conexão (bloqueado pela NetworkPolicy)

# Limpar
kubectl delete pod intruso -n fortress-security
```

#### 🔍 Verificações Adicionais

```bash
# Verificar todos os recursos criados
terraform output

# Ver pods em execução
kubectl get pods -n fortress-security -o wide

# Ver network policies
kubectl get networkpolicies -n fortress-security

# Ver RBAC
kubectl get serviceaccounts,roles,rolebindings -n fortress-security

# Entrar no explorador para testes manuais
kubectl exec -it -n fortress-security deployment/explorer -- sh
```

## 🛡️ Recursos de Segurança Implementados

### 1. **RBAC (Role-Based Access Control)**

- **ServiceAccount específico** para cada componente
- **Roles com permissões mínimas** (princípio do menor privilégio)
- **RoleBindings** conectando SAs às Roles apropriadas

### 2. **NetworkPolicies**

- **Fortaleza**: Aceita conexões apenas do explorador
- **Explorador**: Pode acessar apenas a fortaleza
- **Default Deny**: Bloqueia todo tráfego não especificado
- **System Traffic**: Permite tráfego necessário do Kubernetes

### 3. **SecurityContext**

- **Non-root user**: Todos os containers rodam como usuário não-root
- **Read-only filesystem**: Sistema de arquivos somente leitura
- **No privilege escalation**: Impede escalação de privilégios
- **Dropped capabilities**: Remove todas as capabilities desnecessárias
- **Seccomp profile**: Usa perfil de segurança padrão

### 4. **Secrets Management**

- **Dados sensíveis** armazenados em Secrets
- **Injeção via variáveis** de ambiente
- **Base64 encoding** automático
- **Separação** entre dados sensíveis e configurações

### 5. **Resource Limits**

- **CPU e Memory limits** definidos
- **Requests appropriados** para scheduling
- **Prevent resource abuse** e DoS

## 🔧 Personalização

### Variáveis Principais

```hcl
# terraform.tfvars
namespace = "meu-namespace"
secret_message = "Minha mensagem secreta personalizada"
fortress_replicas = 2
explorer_replicas = 1

fortress_resources = {
  requests = { cpu = "200m", memory = "256Mi" }
  limits   = { cpu = "500m", memory = "512Mi" }
}
```

### Adicionando Novos Recursos

1. **Mais aplicações**: Adicione novos deployments seguindo o padrão
2. **Ingress**: Configure exposição externa se necessário
3. **Monitoring**: Habilite ServiceMonitor para Prometheus
4. **Certificados**: Configure cert-manager para TLS

## 🧪 Cenários de Teste

### Teste 1: Acesso Autorizado
```bash
kubectl exec -n fortress-security deployment/explorer -- \
  curl -s http://fortress-service:3000/secret
```

### Teste 2: Health Check
```bash
kubectl exec -n fortress-security deployment/explorer -- \
  curl -s http://fortress-service:3000/health
```

### Teste 3: Verificar Logs
```bash
kubectl logs -n fortress-security deployment/fortress-api
kubectl logs -n fortress-security deployment/explorer
```

### Teste 4: Pod Não Autorizado
```bash
kubectl run test-unauthorized --image=alpine:latest --rm -it -n fortress-security -- \
  sh -c "apk add curl && curl -m 5 http://fortress-service:3000/secret || echo 'BLOCKED'"
```

## 🧹 Limpeza

```bash
# Remover todos os recursos
terraform destroy

# Confirmar limpeza
kubectl get all -n fortress-security
```

## 📚 Próximos Passos

1. **Pod Security Standards**: Implement PSS/PSA
2. **OPA Gatekeeper**: Políticas de compliance automatizadas
3. **Falco**: Runtime security monitoring
4. **cert-manager**: Certificados TLS automáticos
5. **Istio Service Mesh**: mTLS automático entre serviços

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📝 Licença

Este projeto é para fins educacionais e demonstração de conceitos de segurança no Kubernetes.

---

**⚠️ Aviso**: Este é um projeto educacional. Em ambiente de produção, sempre revise e teste as configurações de segurança conforme suas necessidades específicas.