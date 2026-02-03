# Encodes .env values as base64 and prefixes keys with SECRET_
# Also encodes gcp_service_account.json (no line wrapping to keep JSON intact)
# Run from Week_2/ - reads keys/.env and keys/gcp_service_account.json, writes keys/.env_encoded

KEYS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/keys"
ENV_ENCODED="$KEYS_DIR/.env_encoded"

# Encode .env file
while IFS='=' read -r key value; do
    echo "SECRET_$key=$(echo -n "$value" | base64)";
done < "$KEYS_DIR/.env" > "$ENV_ENCODED"

# Encode GCP service account JSON (no line wrapping so whole JSON stays intact)
# tr -d '\n' used for macOS compatibility (base64 -w 0 is Linux-only)
echo "SECRET_GCP_SERVICE_ACCOUNT=$(base64 < "$KEYS_DIR/gcp_service_account.json" | tr -d '\n')" >> "$ENV_ENCODED"

echo "Done. Encoded secrets written to $ENV_ENCODED"
