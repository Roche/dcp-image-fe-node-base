#!/bin/sh
set -e

HTML_DIR="/usr/share/nginx/html"
TEMPLATE="$HTML_DIR/config.js.template"

# Each app ships its own config.js.template; substitute all exported env vars present in it
if [ -f "$TEMPLATE" ]; then
  MAIN_FILE=$(find "$HTML_DIR" -type f -name 'main.*.js' | sort | head -n 1)
  if [ -z "$MAIN_FILE" ]; then
    echo "No main.{hash}.js file found; cannot determine runtime config filename." >&2
    exit 1
  fi

  MAIN_NAME=${MAIN_FILE##*/}
  HASH=${MAIN_NAME#main.}
  HASH=${HASH%.js}
  OUT="$HTML_DIR/config.$HASH.js"

  envsubst < "$TEMPLATE" > "$OUT"
else
  echo "No config.js.template found, skipping runtime config generation."
fi

# Start nginx in foreground
exec nginx -g "daemon off;"
