# Docker Web Stack

Este repositório contém uma configuração Docker para implantar uma stack completa de aplicações web, incluindo:

- **Docker / Portainer / Nginx Proxy Manager**: Para gerenciamento de contêineres e proxy reverso
- **PostgreSQL**: Banco de dados relacional
- **Evolution API**: API para integração com WhatsApp
- **Typebot / MinIO**: Plataforma de chatbots com armazenamento de objetos

## Requisitos

- Ubuntu Server 24.04 (recomendado) ou outra distribuição Linux compatível
- Docker e Docker Compose instalados
- Domínios configurados para cada serviço (opcional, mas recomendado)

## Estrutura do Projeto

```
docker-web/
├── docker-compose.yml      # Configuração principal dos serviços
├── .env                    # Variáveis de ambiente (não incluído no repositório)
├── .env.example            # Exemplo de variáveis de ambiente
├── deploy_all.sh           # Script para implantar todos os serviços
├── init-databases.sh       # Script para inicializar bancos de dados
├── init-minio.sh           # Script para inicializar MinIO
├── install_docker.sh       # Script para instalar Docker, Portainer e Nginx Proxy Manager
├── install_postgres16.sh   # Script para iniciar PostgreSQL
├── install_typebot.sh      # Script para iniciar Typebot
└── install_evolutionApi.sh # Script para iniciar Evolution API
```

## Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/docker-web.git
cd docker-web
```

### 2. Configure as variáveis de ambiente

```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas configurações específicas.

### 3. Instale o Docker e ferramentas de gerenciamento

```bash
sudo chmod +x install_docker.sh
sudo ./install_docker.sh
```

### 4. Implante todos os serviços

```bash
sudo chmod +x deploy_all.sh
sudo ./deploy_all.sh
```

## Serviços Disponíveis

Após a implantação, os seguintes serviços estarão disponíveis:

- **Portainer**: http://seu-ip:9000 (gerenciamento de contêineres)
- **Nginx Proxy Manager**: http://seu-ip:81 (gerenciamento de proxy)
- **Typebot Builder**: https://typebot.seu-dominio.com (configurado no .env)
- **Typebot Viewer**: https://bot.seu-dominio.com (configurado no .env)
- **MinIO Console**: https://minios3.seu-dominio.com (configurado no .env)
- **Evolution API**: https://evolutionapi.seu-dominio.com (configurado no .env)

## Configuração do Nginx Proxy Manager

Para acessar os serviços através dos domínios configurados, você precisa configurar o Nginx Proxy Manager:

1. Acesse http://seu-ip:81
2. Faça login com as credenciais padrão:
   - Email: admin@example.com
   - Senha: changeme
3. Adicione um novo proxy host para cada serviço:
   - Typebot Builder: porta 3000
   - MinIO Console: porta 9001
   - Evolution API: porta 8080

## Segurança

- Todas as senhas e chaves de API devem ser alteradas no arquivo `.env`
- O arquivo `.env` não deve ser incluído no repositório
- Recomenda-se usar o firewall UFW para limitar o acesso às portas

## Scripts Disponíveis

- `install_docker.sh`: Instala Docker, Docker Compose, Portainer e Nginx Proxy Manager
- `install_postgres16.sh`: Inicia o serviço PostgreSQL
- `install_typebot.sh`: Inicia o serviço Typebot
- `install_evolutionApi.sh`: Inicia o serviço Evolution API
- `deploy_all.sh`: Implanta todos os serviços em sequência
- `init-databases.sh`: Inicializa os bancos de dados necessários
- `init-minio.sh`: Inicializa o MinIO e cria o bucket necessário

## Manutenção

Para gerenciar os serviços, você pode usar os seguintes comandos:

```bash
# Iniciar todos os serviços
docker compose up -d

# Parar todos os serviços
docker compose down

# Verificar status dos serviços
docker compose ps

# Ver logs de um serviço específico
docker compose logs -f [serviço]
```

## Contribuição

Contribuições são bem-vindas! Por favor, abra uma issue ou pull request para sugerir melhorias.

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para detalhes.
