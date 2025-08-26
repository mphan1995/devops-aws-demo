#!/usr/bin/env bash
set -euo pipefail
REGION=${REGION:-ap-southeast-1}
ALARM_NAME=${ALARM_NAME:-devsecops-demo-5xx}

# Lấy URL từ Terraform
RAW_URL=$(terraform -chdir=terraform output -raw apprunner_service_url)
# Chuẩn hoá: thêm https:// nếu thiếu
if [[ "$RAW_URL" != http* ]]; then
  APP_URL="https://$RAW_URL"
else
  APP_URL="$RAW_URL"
fi
echo "Using APP_URL=$APP_URL"

echo "Hitting /error 10x to generate 5xx..."
for i in {1..10}; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 5 "$APP_URL/error")
  echo "$code"
done

echo "Waiting for alarm '$ALARM_NAME' to enter ALARM..."
while true; do
  state=$(aws cloudwatch describe-alarms \
            --alarm-names "$ALARM_NAME" --region "$REGION" \
            --query 'MetricAlarms[0].StateValue' --output text || echo "UNKNOWN")
  echo "Alarm state: $state"
  [[ "$state" == "ALARM" ]] && break
  sleep 10
done
echo "✅ Alarm is ALARM; check your email (SNS)."
