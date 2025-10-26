#!/bin/bash

# Prompt for inputs
read -p "Enter the folder(s) to move (space-separated): " SRC
read -p "Enter target VPS IP: " TARGET_IP
read -p "Enter SSH username: " USER
read -p "Enter destination path on target VPS: " DEST
read -s -p "Enter SSH password (leave empty if using key): " SSHPASS
echo ""

# Check if sshpass is installed (used for password auth)
if ! command -v sshpass &> /dev/null; then
  echo "Installing sshpass..."
  if [ -x "$(command -v apt)" ]; then
    sudo apt install -y sshpass
  elif [ -x "$(command -v yum)" ]; then
    sudo yum install -y sshpass
  else
    echo "Please install sshpass manually."
    exit 1
  fi
fi

# Transfer using rsync
if [ -z "$SSHPASS" ]; then
  echo "Transferring with SSH key..."
  rsync -avz -e ssh $SRC $USER@$TARGET_IP:$DEST
else
  echo "Transferring with password..."
  sshpass -p "$SSHPASS" rsync -avz -e ssh $SRC $USER@$TARGET_IP:$DEST
fi

echo "✅ Transfer complete!"
