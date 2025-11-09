#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] Rails env: ${RAILS_ENV:-unset}"
echo "[entrypoint] Preparing databases (migrations + cache/queue schema load)…"
bundle exec rails db:prepare 

echo "[entrypoint] Seeding if empty…"
bundle exec rails data:seed_if_empty

echo "[entrypoint] Starting Puma…"
exec bundle exec puma -C config/puma.rb
