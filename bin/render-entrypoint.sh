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

echo "[entrypoint] Running db:migrate (with retries)..."
if ! retry 6 3 bundle exec rails db:migrate; then
  if [ "${ALLOW_BOOT_WITHOUT_MIGRATIONS:-0}" = "1" ]; then
    echo "[entrypoint] WARNING: proceeding to boot without successful migration."
  else
    echo "[entrypoint] ERROR: db:migrate failed and ALLOW_BOOT_WITHOUT_MIGRATIONS!=1"
    exit 1
  fi
fi

echo "[entrypoint] Loading Solid schemas..."
retry 3 3 bundle exec rails db:schema:load:cache  || echo "[entrypoint] cache schema load skipped/ok"
retry 3 3 bundle exec rails db:schema:load:queue || echo "[entrypoint] queue schema load skipped/ok"
retry 3 3 bundle exec rails db:schema:load:cable  || echo "[entrypoint] cable schema load skipped/ok"

prod reset + reseed if explicitly requested
if [[ "${RUN_PROD_RESET:-0}" == "1" ]]; then
  echo "[entrypoint] RUN_PROD_RESET=1 -> invoking data:reset_and_seed (FORCE=${FORCE:-0})"
  FORCE="${FORCE:-0}" bundle exec rails data:reset_and_seed
else
  echo "[entrypoint] Seeding if empty..."
  bundle exec rails data:seed_if_empty
fi

echo "[entrypoint] Verifying solid_cache_entries..."
bundle exec rails runner 'puts "[entrypoint] solid_cache_entries? => #{ActiveRecord::Base.connection.table_exists?("solid_cache_entries")}"' || true

echo "[entrypoint] Starting Puma..."
exec bundle exec puma -C config/puma.rb
