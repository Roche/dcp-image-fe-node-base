#!/bin/sh
set -e

HTML_DIR="/usr/share/nginx/html"
JS_TEMPLATE="$HTML_DIR/config.js.template"
JSON_TEMPLATE="/etc/nginx/config.json.template"

if [ -f "$JS_TEMPLATE" ]; then
  MAIN_FILE=$(find "$HTML_DIR" -type f -name 'main.*.js' | sort | head -n 1)
  if [ -z "$MAIN_FILE" ]; then
    echo "No main.{hash}.js file found; cannot determine runtime config filename." >&2
    exit 1
  fi

  MAIN_NAME=${MAIN_FILE##*/}
  HASH=${MAIN_NAME#main.}
  HASH=${HASH%.js}
  OUT="$HTML_DIR/config.$HASH.js"

  envsubst < "$JS_TEMPLATE" > "$OUT"
fi

if [ -f "$JSON_TEMPLATE" ]; then
  (
    TMP=$(mktemp "$HTML_DIR/.config.json.XXXXXX")
    trap 'rm -f "$TMP"' EXIT

    if ! jq -e -s '
      if length != 1 or (.[0] | type) != "object" then
        error("expected a single JSON object")
      else
        .[0] | walk(
          if type == "string" then
            (capture("\\A\\$\\{(?<name>[A-Za-z_][A-Za-z0-9_]*)\\}\\z") // null) as $ref
            | if $ref == null then .
              else env[$ref.name]
              | if . == null or . == "" then
                  error("required environment variable \($ref.name) is unset or empty")
                else . end
              end
          else . end
        )
      end
    ' "$JSON_TEMPLATE" > "$TMP"; then
      echo "Failed to render $JSON_TEMPLATE; not starting nginx." >&2
      exit 1
    fi

    mv -f "$TMP" "$HTML_DIR/config.json"
  )
fi

if [ ! -f "$JS_TEMPLATE" ] && [ ! -f "$JSON_TEMPLATE" ]; then
  echo "No runtime config template found, skipping runtime config generation."
fi

# Start nginx in foreground
exec nginx -g "daemon off;"
