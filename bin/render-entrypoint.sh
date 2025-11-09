#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] Rails env: ${RAILS_ENV:-unset}"

# --- 1) Regular migrations
echo "[entrypoint] Running db:migrate…"
bundle exec rails db:migrate

# --- 2) Ensure Solid schemas are loaded (this is what fixes solid_cache_entries)
echo "[entrypoint] Loading Solid schemas…"
bundle exec rails db:schema:load:cache  || echo "[entrypoint] cache schema already applied or task missing"
bundle exec rails db:schema:load:queue  || echo "[entrypoint] queue schema already applied or task missing"
bundle exec rails db:schema:load:cable  || echo "[entrypoint] cable schema already applied or task missing"

# --- 3) (Optional) Danger: prod reset + reseed if explicitly requested
if [[ "${RUN_PROD_RESET:-0}" == "1" ]]; then
  echo "[entrypoint] RUN_PROD_RESET=1 -> invoking data:reset_and_seed (FORCE=${FORCE:-0})"
  FORCE="${FORCE:-0}" bundle exec rails data:reset_and_seed
else
  echo "[entrypoint] Seeding if empty…"
  bundle exec rails data:seed_if_empty
fi

# --- 4) Sanity check
echo "[entrypoint] Verifying solid_cache_entries exists..."
bundle exec rails runner 'puts "[entrypoint] solid_cache_entries? => #{ActiveRecord::Base.connection.table_exists?("solid_cache_entries")}"'

echo "[entrypoint] Starting Puma…"
exec bundle exec puma -C config/puma.rb
