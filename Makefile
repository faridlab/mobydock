.PHONY: help up down build clean logs shell db-backup db-restore install uninstall

# Default target
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Docker commands
up: ## Start all services
	docker-compose up -d

up-dev: ## Start development services with profile
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

up-%: ## Start services with specific profile (e.g., make up-node, make up-monitoring)
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile $* up -d

down: ## Stop all services
	docker-compose down

down-dev: ## Stop development services
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

build: ## Build all services
	docker-compose build

build-no-cache: ## Build all services without cache
	docker-compose build --no-cache

clean: ## Remove all containers, networks, and volumes
	docker-compose down -v --remove-orphans
	docker system prune -f

logs: ## Show logs for all services
	docker-compose logs -f

logs-%: ## Show logs for specific service (e.g., make logs-mariadb)
	docker-compose logs -f $*

# Shell access
shell: ## Access shell in running service
	@read -p "Enter service name: " service; \
	docker-compose exec $$service sh

shell-mariadb: ## Access MariaDB shell
	docker-compose exec mariadb mysql -u root -ppassword

shell-postgres: ## Access PostgreSQL shell
	docker-compose exec postgres psql -U dev -d app_db

shell-mongo: ## Access MongoDB shell
	docker-compose exec mongo mongosh -u root -p password

shell-redis: ## Access Redis CLI
	docker-compose exec redis redis-cli

# Database operations
db-backup: ## Backup all databases
	@echo "Creating database backups..."
	mkdir -p ./backups

	# MariaDB backup
	docker-compose exec mariadb mysqldump -u root -ppassword --all-databases > ./backups/mariadb_$(shell date +%Y%m%d_%H%M%S).sql

	# PostgreSQL backup
	docker-compose exec postgres pg_dump -U dev -d app_db > ./backups/postgres_$(shell date +%Y%m%d_%H%M%S).sql

	# MongoDB backup
	docker-compose exec mongo mongodump --uri="mongodb://root:password@localhost:27017" --out=/tmp/mongo_$(shell date +%Y%m%d_%H%M%S)
	docker cp mongo:/tmp/mongo_$(shell date +%Y%m%d_%H%M%S) ./backups/

	@echo "Backups created in ./backups directory"

db-restore: ## Restore databases from backups
	@echo "Available backups:"
	@ls -la ./backups/
	@read -p "Enter backup file name (relative to ./backups/): " backup; \
	if [ -f "./backups/$$backup" ]; then \
		read -p "Enter service name (mariadb/postgres/mongo): " service; \
		case $$service in \
			mariadb) docker-compose exec -T mariadb mysql -u root -ppassword < ./backups/$$backup ;; \
			postgres) docker-compose exec -T postgres psql -U dev -d app_db < ./backups/$$backup ;; \
			*) echo "Invalid service name" ;; \
		esac; \
	else \
		echo "Backup file not found"; \
	fi

# Development tools
install: ## Install project dependencies and setup environment
	@echo "Setting up development environment..."

	# Create necessary directories
	mkdir -p data logs backups init-scripts

	# Copy environment file if it doesn't exist
	if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from example. Please review and update values."; \
	fi

	# Create network if it doesn't exist
	docker network create dev-network 2>/dev/null || true

	# Start services
	make up

	@echo "Development environment setup complete!"
	@echo "Access URLs:"
	@echo "  Adminer: http://localhost:8080"
	@echo "  pgAdmin: http://localhost:5050"
	@echo "  MongoDB Express: http://localhost:8081"
	@echo "  Redis Commander: http://localhost:8082"
	@echo "  MailHog: http://localhost:8025"
	@echo "  Portainer: http://localhost:9000"

uninstall: ## Clean up and remove development environment
	@echo "Cleaning up development environment..."
	make clean
	docker network rm dev-network 2>/dev/null || true
	@echo "Development environment removed!"

# Health checks
health: ## Check health of all services
	@echo "Checking service health..."
	@docker-compose ps

status: ## Show detailed status of all services
	@echo "Service status:"
	@docker-compose ps
	@echo ""
	@echo "Resource usage:"
	@docker stats --no-stream

# Utility commands
restart: ## Restart all services
	docker-compose restart

restart-%: ## Restart specific service
	docker-compose restart $*

pull: ## Pull latest images
	docker-compose pull

update: ## Update all services (pull and recreate)
	docker-compose pull
	docker-compose up -d --force-recreate

# Quick access commands
adminer: ## Open Adminer in browser
	@open http://localhost:8080 || echo "Adminer available at http://localhost:8080"

pgadmin: ## Open pgAdmin in browser
	@open http://localhost:5050 || echo "pgAdmin available at http://localhost:5050"

mongo-express: ## Open MongoDB Express in browser
	@open http://localhost:8081 || echo "MongoDB Express available at http://localhost:8081"

redis-commander: ## Open Redis Commander in browser
	@open http://localhost:8082 || echo "Redis Commander available at http://localhost:8082"

mailhog: ## Open MailHog in browser
	@open http://localhost:8025 || echo "MailHog available at http://localhost:8025"

portainer: ## Open Portainer in browser
	@open http://localhost:9000 || echo "Portainer available at http://localhost:9000"

# Export/Import configuration
export-config: ## Export current configuration
	tar -czf mobydock-config-$(shell date +%Y%m%d_%H%M%S).tar.gz \
		docker-compose.yml \
		docker-compose.dev.yml \
		redis.conf \
		init-scripts/ \
		Makefile \
		README.md \
		.env.example

import-config: ## Import configuration from tar.gz
	@read -p "Enter config file path: " config; \
	if [ -f "$$config" ]; then \
		tar -xzf "$$config"; \
		echo "Configuration imported successfully"; \
	else \
		echo "Config file not found"; \
	fi