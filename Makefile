.PHONY: up down logs register-connectors dbt-deps dbt-run dbt-test dbt-docs psql

up:
	docker compose up -d --build

down:
	docker compose down -v

logs:
	docker compose logs -f kafka-connect data-generator

register-connectors:
	bash scripts/register-connectors.sh

dbt-deps:
	cd dbt/customer_pipeline && dbt deps

dbt-run:
	cd dbt/customer_pipeline && dbt run

dbt-test:
	cd dbt/customer_pipeline && dbt test

dbt-docs:
	cd dbt/customer_pipeline && dbt docs generate && dbt docs serve

psql:
	docker exec -it pg_customer_db psql -U pipeline_user -d customer_db
