#!/bin/bash

# Script de instalação para Ubuntu Server 24.04
# Instala: Docker, Docker Compose, Portainer e Nginx Proxy Manager
# Autor: Assistente Claude
# Data: $(date +%Y-%m-%d)

set -e  # Para o script se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERRO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    error "Este script deve ser executado como root (sudo)"
    exit 1
fi

# Verificar versão do Ubuntu
if ! grep -q "24.04" /etc/os-release; then
    warning "Este script foi testado no Ubuntu 24.04. Continuando mesmo assim..."
fi

log "Iniciando instalação dos componentes..."

# 1. ATUALIZAR SISTEMA
log "Atualizando sistema..."
apt update && apt upgrade -y

# 2. INSTALAR DEPENDÊNCIAS
log "Instalando dependências..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    git \
    ufw

# 3. INSTALAR DOCKER
log "Instalando Docker..."

# Remover versões antigas se existirem
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Adicionar chave GPG oficial do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adicionar repositório do Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualizar e instalar Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Iniciar e habilitar Docker
systemctl start docker
systemctl enable docker

# Adicionar usuário atual ao grupo docker (se não for root)
if [ "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    info "Usuário $SUDO_USER adicionado ao grupo docker"
fi

log "Docker instalado com sucesso!"

# 4. INSTALAR DOCKER COMPOSE (Plugin)
log "Docker Compose já está incluído como plugin do Docker"

# Verificar instalação
docker --version
docker compose version

# 5. CRIAR DIRETÓRIOS
log "Criando estrutura de diretórios..."
mkdir -p /opt/docker/{portainer,nginx-proxy-manager}
mkdir -p /opt/docker/nginx-proxy-manager/{data,letsencrypt}

# 6. INSTALAR PORTAINER
log "Instalando Portainer..."

# Criar volume para Portainer
docker volume create portainer_data

# Criar docker-compose.yml para Portainer
cat > /opt/docker/portainer/docker-compose.yml << 'EOF'
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    environment:
      - PUID=1000
      - PGID=1000

volumes:
  portainer_data:
    external: true
EOF

# Iniciar Portainer
cd /opt/docker/portainer
docker compose up -d

log "Portainer instalado e rodando na porta 9000 (HTTP) e 9443 (HTTPS)"

# 7. INSTALAR NGINX PROXY MANAGER
log "Instalando Nginx Proxy Manager..."

cat > /opt/docker/nginx-proxy-manager/docker-compose.yml << 'EOF'
version: '3.8'

services:
  nginx-proxy-manager:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    environment:
      - PUID=1000
      - PGID=1000
    healthcheck:
      test: ["CMD", "/usr/bin/check-health"]
      interval: 10s
      timeout: 3s
EOF

# Iniciar Nginx Proxy Manager
cd /opt/docker/nginx-proxy-manager
docker compose up -d

log "Nginx Proxy Manager instalado e rodando na porta 81"

# 8. CONFIGURAR FIREWALL (OPCIONAL)
read -p "Deseja configurar o firewall UFW? (y/N): " configure_ufw
if [[ $configure_ufw =~ ^[Yy]$ ]]; then
    log "Configurando firewall UFW..."
    
    # Configurações básicas do UFW
    ufw default deny incoming
    ufw default allow outgoing
    
    # Permitir SSH
    ufw allow ssh
    
    # Permitir portas dos serviços
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw allow 81/tcp    # Nginx Proxy Manager
    ufw allow 9000/tcp  # Portainer HTTP
    ufw allow 9443/tcp  # Portainer HTTPS
    
    # Ativar UFW
    ufw --force enable
    
    log "Firewall configurado!"
else
    info "Firewall não configurado. Lembre-se de abrir as portas necessárias manualmente."
fi

# 9. CRIAR SCRIPT DE GERENCIAMENTO
log "Criando script de gerenciamento..."

cat > /usr/local/bin/docker-services << 'EOF'
#!/bin/bash

PORTAINER_PATH="/opt/docker/portainer"
NPM_PATH="/opt/docker/nginx-proxy-manager"

case "$1" in
    start)
        echo "Iniciando serviços..."
        cd $PORTAINER_PATH && docker compose up -d
        cd $NPM_PATH && docker compose up -d
        echo "Serviços iniciados!"
        ;;
    stop)
        echo "Parando serviços..."
        cd $PORTAINER_PATH && docker compose down
        cd $NPM_PATH && docker compose down
        echo "Serviços parados!"
        ;;
    restart)
        echo "Reiniciando serviços..."
        cd $PORTAINER_PATH && docker compose restart
        cd $NPM_PATH && docker compose restart
        echo "Serviços reiniciados!"
        ;;
    status)
        echo "Status dos serviços:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    logs)
        if [ -z "$2" ]; then
            echo "Uso: docker-services logs [portainer|nginx-proxy-manager]"
            exit 1
        fi
        case "$2" in
            portainer)
                cd $PORTAINER_PATH && docker compose logs -f
                ;;
            nginx-proxy-manager|npm)
                cd $NPM_PATH && docker compose logs -f
                ;;
            *)
                echo "Serviço inválido. Use: portainer ou nginx-proxy-manager"
                ;;
        esac
        ;;
    update)
        echo "Atualizando imagens..."
        cd $PORTAINER_PATH && docker compose pull && docker compose up -d
        cd $NPM_PATH && docker compose pull && docker compose up -d
        echo "Imagens atualizadas!"
        ;;
    *)
        echo "Uso: docker-services {start|stop|restart|status|logs|update}"
        echo ""
        echo "Comandos disponíveis:"
        echo "  start    - Iniciar todos os serviços"
        echo "  stop     - Parar todos os serviços"
        echo "  restart  - Reiniciar todos os serviços"
        echo "  status   - Mostrar status dos containers"
        echo "  logs     - Mostrar logs (especifique o serviço)"
        echo "  update   - Atualizar imagens dos containers"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/docker-services

# 10. MOSTRAR INFORMAÇÕES FINAIS
log "Instalação concluída com sucesso!"

echo ""
echo "================================================================"
echo -e "${GREEN}INSTALAÇÃO CONCLUÍDA!${NC}"
echo "================================================================"
echo ""
echo -e "${BLUE}Serviços instalados:${NC}"
echo "• Docker: $(docker --version)"
echo "• Docker Compose: $(docker compose version --short)"
echo "• Portainer: http://$(hostname -I | awk '{print $1}'):9000"
echo "• Nginx Proxy Manager: http://$(hostname -I | awk '{print $1}'):81"
echo ""
echo -e "${BLUE}Credenciais padrão do Nginx Proxy Manager:${NC}"
echo "Email: admin@example.com"
echo "Senha: changeme"
echo ""
echo -e "${BLUE}Comandos úteis:${NC}"
echo "• docker-services start|stop|restart|status|logs|update"
echo "• docker ps (listar containers)"
echo "• docker logs <container_name> (ver logs)"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "• Altere as credenciais padrão do Nginx Proxy Manager após o primeiro login"
echo "• Configure seu domínio e SSL no Nginx Proxy Manager"
echo "• Se configurou UFW, as portas necessárias já estão abertas"
if [ "$SUDO_USER" ]; then
    echo "• Faça logout e login novamente para usar Docker sem sudo"
fi
echo ""
echo -e "${GREEN}Arquivos de configuração em:${NC}"
echo "• Portainer: /opt/docker/portainer/"
echo "• Nginx Proxy Manager: /opt/docker/nginx-proxy-manager/"
echo ""
echo "================================================================"