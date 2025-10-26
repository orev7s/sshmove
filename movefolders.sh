#!/bin/bash
# auto-move folders between VPS using a shared SSH key
# fully automated - no password or prompt required

# Prompt user
read -p "Enter the folder(s) to move (space-separated): " SRC
read -p "Enter target VPS IP: " TARGET_IP
read -p "Enter SSH username [default: root]: " USER
USER=${USER:-root}
read -p "Enter destination path on target VPS [default: /root/]: " DEST
DEST=${DEST:-/root/}

# Variables
SSH_KEY="/root/.ssh/id_rsa"
RSYNC_OPTS="-avz --progress"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Check if key exists
if [ ! -f "$SSH_KEY" ]; then
  echo "❌ SSH key not found at $SSH_KEY"
  echo "Please place your private key there and run again."
  exit 1
fi

# Make sure rsync is installed
if ! command -v rsync >/dev/null 2>&1; then
  echo "Installing rsync..."
  if [ -x "$(command -v apt)" ]; then
    apt install -y rsync
  elif [ -x "$(command -v yum)" ]; then
    yum install -y rsync
  fi
fi

# Execute transfer
echo ""
echo "🚀 Starting transfer from $(hostname) → $USER@$TARGET_IP:$DEST"
echo ""

rsync $RSYNC_OPTS -e "ssh $SSH_OPTS" $SRC $USER@$TARGET_IP:$DEST

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Transfer complete!"
else
  echo ""
  echo "❌ Transfer failed! Check SSH key or destination path."
fi
