#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] Rails env: ${RAILS_ENV:-unset}"

retry() {
  local tries=${1:-5}
  local delay=${2:-2}
  local i=1
  shift 2
  until "$@"; do
    exit_code=$?
    echo "[entrypoint] Command failed (exit ${exit_code}), attempt ${i}/${tries}..."
    if [ "${i}" -ge "${tries}" ]; then
      return ${exit_code}
    fi
    sleep ${delay}
    i=$((i+1))
  done
}

if [ "${RUN_MIGRATIONS:-0}" = "1" ]; then
  echo "[entrypoint] Running db:migrate (with retries)..."
  retry 6 3 bundle exec rails db:migrate || {
    if [ "${ALLOW_BOOT_WITHOUT_MIGRATIONS:-0}" = "1" ]; then
      echo "[entrypoint] WARNING: proceeding to boot without successful migration."
    else
      echo "[entrypoint] ERROR: db:migrate failed and ALLOW_BOOT_WITHOUT_MIGRATIONS!=1"
      exit 1
    fi
  }

  echo "[entrypoint] Ensuring Solid schemas (non-destructive)..."
  bundle exec rails runner 'c=ActiveRecord::Base.connection; unless c.table_exists?("solid_cache_entries");  puts("[entrypoint] Creating solid_cache_entries...");  load Rails.root.join("db/cache_schema.rb"); end' || true
  bundle exec rails runner 'c=ActiveRecord::Base.connection; unless c.table_exists?("solid_queue_jobs");    puts("[entrypoint] Creating solid_queue tables...");   load Rails.root.join("db/queue_schema.rb"); end'   || true
  bundle exec rails runner 'c=ActiveRecord::Base.connection; unless c.table_exists?("solid_cable_messages"); puts("[entrypoint] Creating solid_cable tables...");  load Rails.root.join("db/cable_schema.rb"); end'    || true

  # reset + reseed only when explicitly requested
  if [[ "${RUN_PROD_RESET:-0}" == "1" ]]; then
    echo "[entrypoint] RUN_PROD_RESET=1 -> invoking data:reset_and_seed (FORCE=${FORCE:-0})"
    FORCE="${FORCE:-0}" bundle exec rails data:reset_and_seed || true
  else
    echo "[entrypoint] Seeding if empty..."
    bundle exec rails data:seed_if_empty || true
  fi

  echo "[entrypoint] Verifying solid_cache_entries..."
  bundle exec rails runner 'puts "[entrypoint] solid_cache_entries? => #{ActiveRecord::Base.connection.table_exists?("solid_cache_entries")}"' || true
else
  echo "[entrypoint] RUN_MIGRATIONS=0 -> skipping migrate/solid/seed/verify"
fi

echo "[entrypoint] Launching Puma on tcp://0.0.0.0:${PORT:-10000}"
exec bundle exec puma -C config/puma.rb
