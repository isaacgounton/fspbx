.PHONY: help build up down restart logs shell migrate fresh optimize clean backup restore

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Docker images
	docker compose build

up: ## Start all containers
	docker compose up -d

down: ## Stop all containers
	docker compose down

restart: ## Restart all containers
	docker compose restart

logs: ## Show logs from all containers
	docker compose logs -f

logs-app: ## Show logs from app container
	docker compose logs -f app

logs-db: ## Show logs from database container
	docker compose logs -f postgres

shell: ## Access app container shell
	docker compose exec app bash

shell-db: ## Access PostgreSQL shell
	docker compose exec postgres psql -U fusionpbx -d fusionpbx

migrate: ## Run database migrations
	docker compose exec app php artisan migrate

migrate-fresh: ## Fresh migration (WARNING: drops all tables)
	docker compose exec app php artisan migrate:fresh

seed: ## Seed the database
	docker compose exec app php artisan db:seed

optimize: ## Optimize the application
	docker compose exec app php artisan config:cache
	docker compose exec app php artisan route:cache
	docker compose exec app php artisan view:cache
	docker compose exec app php artisan optimize

clear-cache: ## Clear all caches
	docker compose exec app php artisan cache:clear
	docker compose exec app php artisan config:clear
	docker compose exec app php artisan route:clear
	docker compose exec app php artisan view:clear

permissions: ## Fix storage permissions
	docker compose exec app chown -R www-data:www-data /var/www/fspbx/storage
	docker compose exec app chmod -R 775 /var/www/fspbx/storage

status: ## Show container status
	docker compose ps

stats: ## Show container resource usage
	docker stats

backup-db: ## Backup database
	docker compose exec postgres pg_dump -U fusionpbx fusionpbx > backup-$(shell date +%Y%m%d-%H%M%S).sql
	@echo "Database backed up to backup-$(shell date +%Y%m%d-%H%M%S).sql"

clean: ## Remove containers and volumes (WARNING: deletes all data)
	docker compose down -v
	@echo "All containers and volumes removed!"

rebuild: down build up ## Rebuild and restart containers

deploy: ## Quick deploy (build, start, migrate, optimize)
	@./docker-deploy.sh

update: ## Update application (pull, build, restart, migrate)
	git pull origin main
	docker compose build
	docker compose down
	docker compose up -d
	docker compose exec app php artisan migrate --force
	docker compose exec app php artisan optimize
	@echo "Application updated successfully!"
