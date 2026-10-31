.DEFAULT_GOAL := help
.PHONY: help setup up down restart reload ps logs validate test lint clean

COMPOSE := docker compose

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Create .env with a random Grafana password
	@./scripts/setup.sh

up: ## Start the stack and wait until every service is healthy
	@./scripts/start.sh

down: ## Stop the stack (keeps data volumes)
	@./scripts/stop.sh

restart: down up ## Restart the stack

reload: ## Validate and hot-reload Prometheus + Alertmanager config
	@./scripts/reload.sh

ps: ## Show service status and health
	@$(COMPOSE) ps

logs: ## Follow logs (make logs s=prometheus for one service)
	@$(COMPOSE) logs -f --tail=100 $(s)

validate: ## Validate compose, Prometheus, Alertmanager and dashboards
	@./scripts/validate.sh

test: validate ## Alias for validate (includes promtool rule unit tests)

lint: ## Lint shell scripts and YAML (runs in containers)
	docker run --rm -v "$(CURDIR):/mnt" -w /mnt koalaman/shellcheck:stable scripts/*.sh
	docker run --rm -v "$(CURDIR):/data" -w /data cytopia/yamllint:latest -s .

clean: ## Stop the stack and DELETE all data volumes
	$(COMPOSE) down -v
