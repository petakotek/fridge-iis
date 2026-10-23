.DEFAULT_GOAL := help
.PHONY: help start stop up down lint lint-php lint-templates

COMPOSE := docker compose -f .development/compose.yaml

help:
	@printf 'Použití:\n  make start  Spustí aplikaci a vypíše její adresu\n  make stop   Zastaví aplikaci (data zůstanou zachována)\n  make lint   Spustí PHPStan a kontrolu Latte šablon\n'

start up:
	@$(COMPOSE) up -d
	@port="$$( $(COMPOSE) port web 80 | sed -n '1s/.*://p' )"; \
		if [ -z "$$port" ]; then echo 'Nepodařilo se zjistit port aplikace.' >&2; exit 1; fi; \
		printf 'Aplikace běží na: http://localhost:%s/~xvoldrv00/\n' "$$port"

stop down:
	@$(COMPOSE) stop

lint: lint-php lint-templates

lint-php:
	@$(COMPOSE) run --rm --no-deps php php vendor/bin/phpstan analyse app --no-progress

lint-templates:
	@$(COMPOSE) run --rm --no-deps php php latte-lint app/Presentation
