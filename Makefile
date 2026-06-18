.PHONY: dev

dev:
	@set -eu; \
	trap 'docker compose -f docker-compose.dev.yml stop' EXIT; \
	trap 'exit 130' INT; \
	trap 'exit 143' TERM; \
	docker compose -f docker-compose.dev.yml up --build -d; \
	(cd seanime-web && npm run dev)
