#!/bin/bash

# Script para inicializar os bancos de dados para Typebot e Evolution API

# Verificar se o PostgreSQL está rodando
echo "Verificando se o PostgreSQL está em execução..."
until pg_isready -h postgres16 -p 5432 -U ${POSTGRES_USER}; do
  echo "Aguardando o PostgreSQL iniciar..."
  sleep 5
done

echo "PostgreSQL está em execução. Criando bancos de dados..."

# Criar banco de dados para o Typebot se não existir
PGPASSWORD=${POSTGRES_PASSWORD} psql -h postgres16 -U ${POSTGRES_USER} -c "SELECT 1 FROM pg_database WHERE datname = 'typebot'" | grep -q 1 || \
PGPASSWORD=${POSTGRES_PASSWORD} psql -h postgres16 -U ${POSTGRES_USER} -c "CREATE DATABASE typebot"

# Criar banco de dados para o Evolution API se não existir
PGPASSWORD=${POSTGRES_PASSWORD} psql -h postgres16 -U ${POSTGRES_USER} -c "SELECT 1 FROM pg_database WHERE datname = 'evolutionapi'" | grep -q 1 || \
PGPASSWORD=${POSTGRES_PASSWORD} psql -h postgres16 -U ${POSTGRES_USER} -c "CREATE DATABASE evolutionapi"

echo "Bancos de dados criados com sucesso!"
