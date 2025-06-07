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

# Cria o diretório para os dados persistentes do Typebot se não existir
mkdir -p ./typebot_data

# Inicia o serviço typebot em modo detached
echo "Iniciando o serviço typebot..."
docker compose up -d typebot

echo "Serviço typebot iniciado. Verifique o status com 'docker compose ps'."