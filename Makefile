.PHONY: help build up down logs status clean test cli

# Variáveis
DOCKER_COMPOSE = docker-compose
APP_NAME = confirmacao-consultas

# Comandos padrão
help: ## Mostra esta ajuda
	@echo "Comandos disponíveis para $(APP_NAME):"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Docker commands
build: ## Constrói as imagens Docker
	$(DOCKER_COMPOSE) build

up: ## Inicia os serviços (usa o banco configurado no .env)
	$(DOCKER_COMPOSE) --profile $(DOCKER_DATABASE_TYPE:-postgresql) up -d

down: ## Para os serviços
	$(DOCKER_COMPOSE) down

logs: ## Mostra logs dos serviços
	$(DOCKER_COMPOSE) logs -f

status: ## Mostra status dos serviços
	$(DOCKER_COMPOSE) ps

# Desenvolvimento com bancos específicos
dev-oracle: ## Setup completo com Oracle
	$(DOCKER_COMPOSE) --profile oracle up -d
	@echo "✅ Serviços Oracle iniciados! Acesse http://localhost:5001"

dev-postgresql: ## Setup completo com PostgreSQL
	$(DOCKER_COMPOSE) --profile postgresql up -d
	@echo "✅ Serviços PostgreSQL iniciados! Acesse http://localhost:5001"

dev-firebird: ## Setup completo com Firebird
	$(DOCKER_COMPOSE) --profile firebird up -d
	@echo "✅ Serviços Firebird iniciados! Acesse http://localhost:5001"

dev: dev-postgresql ## Setup padrão com PostgreSQL

dev-build: ## Rebuild e reinicia serviços
	$(DOCKER_COMPOSE) down
	$(DOCKER_COMPOSE) build --no-cache
	$(DOCKER_COMPOSE) --profile $(DOCKER_DATABASE_TYPE:-postgresql) up -d

# Banco de dados
db-shell-oracle: ## Acessa shell do Oracle
	$(DOCKER_COMPOSE) exec db-oracle sqlplus system/$(ORACLE_DOCKER_PASSWORD:-oracle)@//localhost:$(ORACLE_DOCKER_PORT:-1521)/$(ORACLE_DOCKER_SERVICE:-XE)

db-shell-postgresql: ## Acessa shell do PostgreSQL
	$(DOCKER_COMPOSE) exec db-postgresql psql -U $(POSTGRESQL_DOCKER_USER:-postgres) -d $(POSTGRESQL_DOCKER_DB:-santaCasa)

db-shell-firebird: ## Acessa shell do Firebird
	$(DOCKER_COMPOSE) exec db-firebird isql -u $(FIREBIRD_DOCKER_USER:-SYSDBA) -p $(FIREBIRD_DOCKER_PASSWORD:-masterkey) localhost:$(FIREBIRD_DOCKER_PORT:-3050)/$(FIREBIRD_DOCKER_DB:-hospital_db)

db-shell: db-shell-postgresql ## Shell padrão (PostgreSQL)

db-reset: ## Reseta banco de dados
	$(DOCKER_COMPOSE) down -v
	$(DOCKER_COMPOSE) --profile $(DOCKER_DATABASE_TYPE:-postgresql) up -d
	@echo "⏳ Aguardando banco inicializar..."
	@sleep 15
	$(DOCKER_COMPOSE) up -d app

# Testes e CLI
test: ## Executa testes
	$(DOCKER_COMPOSE) exec app python -m pytest

cli: ## Executa CLI da aplicação
	$(DOCKER_COMPOSE) exec app python -m cli

# Monitoramento
health: ## Verifica saúde da aplicação
	curl -f http://localhost:5001/health || echo "❌ Aplicação não está respondendo"

scheduler-status: ## Verifica status do scheduler
	curl -f http://localhost:5001/scheduler/status || echo "❌ Scheduler não está respondendo"

# Limpeza
clean: ## Limpa containers, volumes e imagens
	$(DOCKER_COMPOSE) down -v --rmi all
	docker system prune -f

clean-logs: ## Limpa logs locais
	rm -rf logs/*.log

# Produção
prod: ## Inicia serviços de produção (com Nginx)
	$(DOCKER_COMPOSE) --profile production --profile $(DOCKER_DATABASE_TYPE:-postgresql) up -d

prod-down: ## Para serviços de produção
	$(DOCKER_COMPOSE) --profile production down

# Utilitários
restart: down up ## Reinicia todos os serviços
	@echo "🔄 Serviços reiniciados!"

shell: ## Acessa shell do container da aplicação
	$(DOCKER_COMPOSE) exec app bash

# Comandos de desenvolvimento
dev-setup: dev ## Setup completo para desenvolvimento
	@echo "✅ Setup de desenvolvimento concluído!"
	@echo "📱 Aplicação: http://localhost:5001"
	@echo "🗄️  Banco: $(DOCKER_DATABASE_TYPE:-postgresql)"
	@echo "📊 Status: make status"
	@echo "📝 Logs: make logs"

# Comandos específicos por banco
oracle-setup: dev-oracle ## Setup com Oracle
	@echo "✅ Oracle configurado e rodando!"

postgresql-setup: dev-postgresql ## Setup com PostgreSQL
	@echo "✅ PostgreSQL configurado e rodando!"

firebird-setup: dev-firebird ## Setup com Firebird
	@echo "✅ Firebird configurado e rodando!"
