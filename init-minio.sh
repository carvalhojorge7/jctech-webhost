#!/bin/bash

# Script para inicializar o MinIO e criar o bucket necessário para o Typebot

# Verificar se o MinIO está rodando
echo "Verificando se o MinIO está em execução..."
until curl -s http://localhost:9000/minio/health/ready; do
  echo "Aguardando o MinIO iniciar..."
  sleep 5
done

echo "MinIO está em execução. Criando bucket..."

# Instalar o cliente mc (MinIO Client) se não estiver instalado
if ! command -v mc &> /dev/null; then
  echo "Instalando o cliente MinIO (mc)..."
  wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
  chmod +x /usr/local/bin/mc
fi

# Configurar o cliente MinIO
mc alias set myminio http://localhost:9000 ${S3_ACCESS_KEY} ${S3_SECRET_KEY}

# Criar o bucket se não existir
mc mb --ignore-existing myminio/${S3_BUCKET}

# Definir política de acesso público para o bucket
mc policy set download myminio/${S3_BUCKET}

echo "Bucket ${S3_BUCKET} criado e configurado com sucesso!"
