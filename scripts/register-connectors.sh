#!/usr/bin/env bash
# Registers the Debezium source and Snowflake sink connectors with Kafka Connect.
# Requires: curl, envsubst (gettext). Reads secrets from .env in the project root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"

if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
else
  echo "No .env found - copy .env.example to .env and fill it in first." >&2
  exit 1
fi

echo "Waiting for Kafka Connect at $CONNECT_URL ..."
until curl -s -o /dev/null "$CONNECT_URL/connectors"; do sleep 2; done

echo "Registering Postgres source connector (Debezium CDC)..."
envsubst < "$ROOT_DIR/kafka-connect/connectors/postgres-source-connector.json" \
  | curl -s -X POST -H "Content-Type: application/json" --data @- "$CONNECT_URL/connectors" | python3 -m json.tool

echo "Registering Snowflake sink connector..."
envsubst < "$ROOT_DIR/kafka-connect/connectors/snowflake-sink-connector.json" \
  | curl -s -X POST -H "Content-Type: application/json" --data @- "$CONNECT_URL/connectors" | python3 -m json.tool

echo "Connector status:"
curl -s "$CONNECT_URL/connectors?expand=status" | python3 -m json.tool
