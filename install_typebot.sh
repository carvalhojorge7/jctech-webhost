#!/bin/bash

# Script para iniciar o serviço typebot usando Docker Compose

# Verifica se o arquivo .env existe
if [ ! -f .env ]; then
    echo "Erro: O arquivo .env não foi encontrado. Crie-o e preencha as variáveis de ambiente."
    exit 1
fi

# Verifica se o arquivo docker-compose.yml existe
if [ ! -f docker-compose.yml ]; then
    echo "Erro: O arquivo docker-compose.yml não foi encontrado."
    exit 1
fi

# Cria os diretórios para os dados persistentes do Typebot se não existirem
mkdir -p ./typebot_builder_data
mkdir -p ./typebot_viewer_data

# Inicia os serviços typebot-builder e typebot-viewer em modo detached
echo "Iniciando os serviços typebot-builder e typebot-viewer..."
docker compose up -d typebot-builder typebot-viewer

echo "Serviço typebot iniciado. Verifique o status com 'docker compose ps'."