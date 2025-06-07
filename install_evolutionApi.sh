#!/bin/bash

# Script para iniciar o serviço evolutionapi usando Docker Compose

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

# Cria o diretório para os dados persistentes da Evolution API se não existir (ajuste o nome do volume se necessário)
mkdir -p ./evolutionapi_data

# Inicia o serviço evolutionapi em modo detached
echo "Iniciando o serviço evolutionapi..."
docker compose up -d evolutionapi

echo "Serviço evolutionapi iniciado. Verifique o status com 'docker compose ps'."