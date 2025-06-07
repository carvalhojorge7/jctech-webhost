#!/bin/bash

# Script para inicializar o MinIO e criar o bucket necessário para o Typebot

# Aguardar MinIO inicializar
echo "Aguardando MinIO inicializar..."
while ! curl -s http://localhost:9010/minio/health/live > /dev/null; do
  echo "Aguardando MinIO inicializar..."
  sleep 5
done

echo "MinIO está em execução. Criando bucket..."

# Instalar o cliente mc (MinIO Client) se não estiver instalado
if ! command -v mc &> /dev/null; then
  echo "Instalando o cliente MinIO (mc)..."
  wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
  chmod +x /usr/local/bin/mc
fi

# Configurar cliente MinIO
echo "Configurando cliente MinIO..."
mc alias set myminio http://localhost:9010 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

# Criar o bucket se não existir
mc mb --ignore-existing myminio/${S3_BUCKET}

# Definir política de acesso público para o bucket
mc policy set download myminio/${S3_BUCKET}

echo "Bucket ${S3_BUCKET} criado e configurado com sucesso!"
