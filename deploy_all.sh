#!/bin/bash

# Script para implantar todos os serviços
# Autor: Cascade AI
# Data: $(date +%Y-%m-%d)

# Cores para output
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
SEM_COR='\033[0m'

# Função para logging
log() {
    echo -e "${VERDE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${SEM_COR}"
}

erro() {
    echo -e "${VERMELHO}[ERRO] $1${SEM_COR}"
}

aviso() {
    echo -e "${AMARELO}[AVISO] $1${SEM_COR}"
}

info() {
    echo -e "${AZUL}[INFO] $1${SEM_COR}"
}

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    aviso "Este script deve ser executado como root (sudo). Tentando continuar mesmo assim..."
fi

# Verificar se o Docker está instalado
if ! command -v docker &> /dev/null; then
    erro "Docker não encontrado. Por favor, execute o script install_docker.sh primeiro."
    exit 1
fi

# Verificar se o Docker Compose está instalado
if ! command -v docker compose &> /dev/null; then
    erro "Docker Compose não encontrado. Por favor, execute o script install_docker.sh primeiro."
    exit 1
fi

# Verificar se os arquivos necessários existem
if [ ! -f .env ]; then
    erro "Arquivo .env não encontrado. Por favor, crie-o antes de continuar."
    exit 1
fi

if [ ! -f docker-compose.yml ]; then
    erro "Arquivo docker-compose.yml não encontrado. Por favor, crie-o antes de continuar."
    exit 1
fi

# Criar diretórios para volumes se não existirem
log "Criando diretórios para volumes..."
mkdir -p ./postgres_data
mkdir -p ./minio_data
mkdir -p ./typebot_data
mkdir -p ./evolutionapi_data

# Iniciar PostgreSQL primeiro
log "Iniciando PostgreSQL..."
docker compose up -d postgres16

# Aguardar PostgreSQL inicializar
info "Aguardando PostgreSQL inicializar..."
sleep 10

# Criar bancos de dados necessários
log "Criando bancos de dados..."
docker compose exec postgres16 psql -U postgres -c "CREATE DATABASE typebot;" || true
docker compose exec postgres16 psql -U postgres -c "CREATE DATABASE evolutionapi;" || true

# Iniciar MinIO
log "Iniciando MinIO..."
docker compose up -d minio

# Aguardar MinIO inicializar
info "Aguardando MinIO inicializar..."
sleep 5

# Configurar bucket do MinIO
log "Configurando bucket do MinIO..."
# Extrair variáveis do arquivo .env
S3_ACCESS_KEY=$(grep S3_ACCESS_KEY .env | cut -d '=' -f2)
S3_SECRET_KEY=$(grep S3_SECRET_KEY .env | cut -d '=' -f2)
S3_BUCKET=$(grep S3_BUCKET .env | cut -d '=' -f2)

# Usar o cliente mc dentro de um container temporário para configurar o MinIO
docker run --rm --network host -e MC_HOST_local=http://$S3_ACCESS_KEY:$S3_SECRET_KEY@localhost:9000 minio/mc mb local/$S3_BUCKET --ignore-existing || true
docker run --rm --network host -e MC_HOST_local=http://$S3_ACCESS_KEY:$S3_SECRET_KEY@localhost:9000 minio/mc policy set download local/$S3_BUCKET || true

# Iniciar Typebot
log "Iniciando Typebot..."
docker compose up -d typebot

# Iniciar Evolution API
log "Iniciando Evolution API..."
docker compose up -d evolutionapi

# Verificar status dos serviços
log "Verificando status dos serviços..."
docker compose ps

log "Implantação concluída com sucesso!"
log "URLs de acesso:"
info "- Typebot Builder: ${NEXTAUTH_URL:-https://typebot.jctech.digital}"
info "- Typebot Viewer: ${NEXT_PUBLIC_VIEWER_URL:-https://bot.jctech.digital}"
info "- MinIO Console: ${MINIO_BROWSER_REDIRECT_URL:-https://minios3.jctech.digital}"
info "- Evolution API: ${WEBHOOK_URL:-https://evolutionapi.jctech.digital}"

aviso "Lembre-se de configurar o Nginx Proxy Manager para acessar esses serviços através dos domínios configurados."
