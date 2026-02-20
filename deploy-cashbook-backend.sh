#!/bin/bash
# Deploy Cashbook backend files to staging via SCP.
# Uses custom SSH port and host (same format as your working command).
# Usage:
#   SCP_PASS='Korat@2511' ./deploy-cashbook-backend.sh

set -e
REMOTE_USER_HOST="u816973857@145.79.211.86"
REMOTE_PATH="~/domains/nutanvij.com/public_html/staging/backend"
SSH_PORT=65002
BASE="/Users/rutvikkorat/StudioProjects/smart_attendance_tracker"

# Same options as your working command: custom port + no host key prompt
SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=120 -o ServerAliveInterval=30 -o ServerAliveCountMax=6)

cd "$BASE"

if [ -n "$SCP_PASS" ] && command -v sshpass &>/dev/null; then
  SCP() { sshpass -p "$SCP_PASS" scp -P "$SSH_PORT" "${SSH_OPTS[@]}" "$@"; }
else
  echo "Set SCP_PASS and ensure sshpass is installed. Example: SCP_PASS='Korat@2511' $0"
  exit 1
fi

echo "Deploying CashbookController..."
SCP backend/app/Http/Controllers/Api/CashbookController.php "$REMOTE_USER_HOST:$REMOTE_PATH/app/Http/Controllers/Api/"

echo "Deploying api.php..."
SCP backend/routes/api.php "$REMOTE_USER_HOST:$REMOTE_PATH/routes/"

echo "Deploying CashbookIncome model..."
SCP backend/app/Models/CashbookIncome.php "$REMOTE_USER_HOST:$REMOTE_PATH/app/Models/"

echo "Deploying CashbookExpense model..."
SCP backend/app/Models/CashbookExpense.php "$REMOTE_USER_HOST:$REMOTE_PATH/app/Models/"

echo "Deploying cashbook_income migration..."
SCP backend/database/migrations/2026_02_20_100000_create_cashbook_income_table.php "$REMOTE_USER_HOST:$REMOTE_PATH/database/migrations/"

echo "Deploying cashbook_expense migration..."
SCP backend/database/migrations/2026_02_20_100001_create_cashbook_expense_table.php "$REMOTE_USER_HOST:$REMOTE_PATH/database/migrations/"

echo "Done. SSH to server (ssh -p $SSH_PORT $REMOTE_USER_HOST) and run: cd domains/nutanvij.com/public_html/staging/backend && php artisan migrate"
