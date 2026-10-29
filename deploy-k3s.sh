#!/bin/bash
set -euo pipefail

IMAGE="ghcr.io/prokhorovalexey1/devops-lab:latest"
DEPLOYMENT="devops-lab"
NAMESPACE="default"
STATE_FILE="$HOME/.devops-lab-digest"

REMOTE_DIGEST=$(docker buildx imagetools inspect "$IMAGE" \
  --format '{{.Manifest.Digest}}')

if [[ -z "$REMOTE_DIGEST" ]]; then
  echo "Не удалось получить digest из GHCR"
  exit 1
fi

PREVIOUS_DIGEST=""
if [[ -f "$STATE_FILE" ]]; then
  PREVIOUS_DIGEST=$(cat "$STATE_FILE")
fi

if [[ "$REMOTE_DIGEST" == "$PREVIOUS_DIGEST" ]]; then
  echo "Образ не изменился. Обновление не требуется."
  exit 0
fi

echo "Обнаружен новый образ: $REMOTE_DIGEST"

sudo k3s kubectl rollout restart deployment/"$DEPLOYMENT" \
  -n "$NAMESPACE"

sudo k3s kubectl rollout status deployment/"$DEPLOYMENT" \
  -n "$NAMESPACE" --timeout=120s

echo "$REMOTE_DIGEST" > "$STATE_FILE"
echo "Обновление завершено."
