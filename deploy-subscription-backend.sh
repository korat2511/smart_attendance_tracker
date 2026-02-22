#!/bin/bash
# Deploy subscription cancel fix (and related backend files) to staging via SCP.
# Usage:
#   SCP_PASS='your_password' ./deploy-subscription-backend.sh

set -e
REMOTE_USER_HOST="u816973857@145.79.211.86"
REMOTE_PATH="~/domains/nutanvij.com/public_html/staging/backend"
SSH_PORT=65002
BASE="/Users/rutvikkorat/StudioProjects/smart_attendance_tracker"

SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=120 -o ServerAliveInterval=30 -o ServerAliveCountMax=6)

cd "$BASE"

if [ -n "$SCP_PASS" ] && command -v sshpass &>/dev/null; then
  SCP() { sshpass -p "$SCP_PASS" scp -P "$SSH_PORT" "${SSH_OPTS[@]}" "$@"; }
else
  echo "Set SCP_PASS and ensure sshpass is installed. Example: SCP_PASS='Korat@2511' $0"
  exit 1
fi

echo "Deploying SubscriptionController..."
SCP backend/app/Http/Controllers/Api/SubscriptionController.php "$REMOTE_USER_HOST:$REMOTE_PATH/app/Http/Controllers/Api/"

echo "Deploying Subscription model..."
SCP backend/app/Models/Subscription.php "$REMOTE_USER_HOST:$REMOTE_PATH/app/Models/"

echo "Deploying cancel_at_period_end migration..."
SCP backend/database/migrations/2026_02_22_100000_add_cancel_at_period_end_to_subscriptions.php "$REMOTE_USER_HOST:$REMOTE_PATH/database/migrations/"

echo "Done. Run migration on server if not already run:"
echo "  ssh -p $SSH_PORT $REMOTE_USER_HOST 'cd domains/nutanvij.com/public_html/staging/backend && php artisan migrate'"
