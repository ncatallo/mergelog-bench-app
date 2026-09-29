#!/usr/bin/env bash
# Restore the newest R2 backup into the database:  ./restore.sh
set -euo pipefail
cd "$(dirname "$0")"
source /root/.bench-r2.env
R2="-e RCLONE_CONFIG_R2_TYPE=s3 -e RCLONE_CONFIG_R2_PROVIDER=Cloudflare
    -e RCLONE_CONFIG_R2_ACCESS_KEY_ID=$ACCESS_KEY -e RCLONE_CONFIG_R2_SECRET_ACCESS_KEY=$SECRET_KEY
    -e RCLONE_CONFIG_R2_ENDPOINT=$ENDPOINT"
mkdir -p /tmp/restore

LATEST=$(docker run --rm $R2 rclone/rclone:1.75.1 lsf r2:$BUCKET_NAME/compose/ | sort | tail -1)
docker run --rm $R2 -v /tmp/restore:/r rclone/rclone:1.75.1 copyto r2:$BUCKET_NAME/compose/$LATEST /r/$LATEST

docker compose up -d --wait db
docker compose exec -T db pg_restore -U bench -d bench --clean --if-exists < /tmp/restore/$LATEST
docker compose restart api
echo "restored $LATEST"
