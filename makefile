# Build all services
build:
	docker-compose build

# Start all services in detached mode
up:
	docker-compose up -d

# Stop and remove containers, networks, volumes
down:
	docker-compose down

# Rebuild images without using cache, then restart services
rebuild:
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d

# Restart services without rebuilding
restart:
	docker-compose down
	docker-compose up -d

# Show logs from all services
logs:
	docker-compose logs -f

# Show logs from the backend container
logs-backend:
	docker logs -f perinatal-mental-health-app

# Open a shell in the backend container
shell:
	docker exec -it perinatal-mental-health-app /bin/sh

# Prune unused Docker data
clean:
	docker system prune -f
	docker volume prune -f

ENV_FILE=backend/cfg/.local.env

define build_db_url
"postgres://$${DB_USER}:$${DB_PASSWORD}@$${DB_HOST}:$${DB_PORT}/$${DB_NAME}?sslmode=$${DB_SSLMODE}"
endef

.PHONY: migrate-up migrate-down migrate-create build run fmt tidy docker-up docker-down

migrate-up:
	@set -o allexport; source $(ENV_FILE); \
	migrate -path ./backend/internal/migrations -database $(call build_db_url) up

migrate-down:
	@set -o allexport; source $(ENV_FILE); \
	migrate -path ./backend/internal/migrations -database $(call build_db_url) down

migrate-create:
	@read -p "Enter migration name: " name; \
	migrate create -ext sql -dir ./backend/internal/migrations -seq $$name

migrate-version:
	@set -o allexport; source cfg/.env; \
	migrate -path ./backend/internal/migrations -database $(call build_db_url) version

migrate-force:
	@set -o allexport; source cfg/.env; \
	migrate -path ./internal/internal/migrations -database $(call build_db_url) force