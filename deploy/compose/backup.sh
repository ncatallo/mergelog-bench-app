#!/usr/bin/env bash
# Nightly backup for the Compose deploy: pg_dump -> local file -> Cloudflare R2 (S3 API).
# Scheduled with: echo '0 3 * * * root /opt/bench/app/deploy/compose/backup.sh' > /etc/cron.d/bench-backup
set -euo pipefail
cd "$(dirname "$0")"
source /root/.bench-r2.env            # ACCESS_KEY, SECRET_KEY, ENDPOINT, BUCKET_NAME (never committed)
FILE=bench-$(date -u +%Y%m%dT%H%M%SZ).dump
mkdir -p /opt/bench/backups

docker compose exec -T db pg_dump -U bench -Fc bench > /opt/bench/backups/$FILE

docker run --rm --quiet -v /opt/bench/backups:/b \
  -e RCLONE_CONFIG_R2_TYPE=s3 -e RCLONE_CONFIG_R2_PROVIDER=Cloudflare \
  -e RCLONE_CONFIG_R2_ACCESS_KEY_ID="$ACCESS_KEY" -e RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$SECRET_KEY" \
  -e RCLONE_CONFIG_R2_ENDPOINT="$ENDPOINT" -e RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true \
  rclone/rclone:1.75.1 copyto /b/$FILE r2:$BUCKET_NAME/compose/$FILE

find /opt/bench/backups -name '*.dump' -mtime +7 -delete   # local retention: 7 days
echo "backed up $FILE ($(stat -c %s /opt/bench/backups/$FILE) bytes)"
