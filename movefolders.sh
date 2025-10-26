#!/bin/bash

# transfer_folders.sh
# A simple shell script to transfer one or more folders from the current VPS to a destination VPS using rsync over SSH.
# Assumptions:
# - SSH key-based authentication is set up between the VPSes (same private key installed in ~/.ssh/id_rsa or equivalent on destination).
# - This script embeds the provided RSA private key and uses it temporarily for the transfer.
# - Rsync is installed on both VPSes (if not, install with sudo apt install rsync or equivalent).
# - Run as a user with read access to source folders and SSH access to dest VPS.
#
# Usage:
#   ./transfer_folders.sh
#
# This will prompt for username, dest host, dest path, and source folders interactively.
# It will sync the contents of each source folder to <dest_path>/<source_folder_name>/ on the dest host.

# Interactive prompts
read -p "Enter username for destination VPS: " USERNAME
read -p "Enter destination host (IP or hostname): " DEST_HOST
read -p "Enter destination path (e.g., /backups/): " DEST_PATH

# Ensure trailing slash on dest path for rsync directory syncing
if [[ $DEST_PATH != */ ]]; then
    DEST_PATH="${DEST_PATH}/"
fi

# Prompt for source folders until user enters an empty line
echo "Enter source folder paths (one per line). Press Enter twice when done:"
SOURCES=()
while IFS= read -r line; do
    if [[ -z "$line" ]]; then
        break
    fi
    SOURCES+=("$line")
done

if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "No source folders provided. Exiting."
    exit 1
fi

# Create temporary directory for SSH key
TEMP_DIR=$(mktemp -d)
KEY_FILE="$TEMP_DIR/id_rsa"
trap "rm -rf $TEMP_DIR" EXIT  # Clean up on exit

# Embed the provided RSA private key
cat > "$KEY_FILE" << 'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAw0snsBw7bdvY+TPT5fVM0nyqXFeV/YubhCDVOuzJbt6kUm7v
PVDzzPPzoIth7zFVyLJ3SQlQ7uw2HH4E3EY1UHIc5oLhaqzjRF+HknV8ouuGJ18v
4MCoFLOvV088bZh1LtTK7doI+DAMOljXlxKqe1nYhMG1gvtZ6uSGC5BffV4m9Lhh
7HeokWoxEHfVSo7Er24/G3lUuClJsgRtn3A3dj/oc0dV1RPMxej1kRtGv3uWogWD
TZ/f+7G//QSl2Cj4s7Te/N18yFBt1x3EY5U5s3W97BCA9f25zjkl/l1VWBiH/QRB
ZINEWN5/ODYd4rJPYvd6MfW7EdRnhFySNSPobQIDAQABAoIBAGagsBKUQ4bP6Y3L
9qb56Y0ThlNQk7nSC7+7oVJ97L0esyu+sGqAiB5EdNsBZE3Wl0YIwzbWdnmYGDeQ
4ez/2DSWQym/zcXJZQUhTpVguEbFjpJSK07o72sxogs30IGnhK0/lgS4d841MbfX
yDPT01NPO8FIKqLSg8Y0oVyiWgv+6l8TP4bBZ6p30MSonNsZ8Arepn//MATCfJQw
hemLLtf5QOLLQd+Cx9pziUOMbLKfqcrL1MQ+CiNwthdjaZlbf1Qyl6xwoD9MWq4Z
vMw22K3UgOiJYpDOwuDGnr2bCtI55gYa6s1MXzimc8boWPUikV895Fryy0dUx531
0QqHeAECgYEA9ZzicSm4GwWHodZXLQ8ygjhTWsWRRJkTpRDZfs6C1npGiaz8OBeS
eDVbmFZIsqMOr1dOWcFeR4XLk3t7ssFkcsLT7FyrT6l24y1D+OWZhUP6L5ko3907
QZfomd4HHr7jBma0NLJ9ri+cNzdgNM4QA3Ff+vCsu7qxW8E+tcH0n0ECgYEAy419
0pjCLl9ZWRR5ub8lOv8NriweiJHVtRyFbJIfkKb/MQPtuGPbEaB2vVVNUGL6k9fY
aCotJsBFAqQxOvKTGiG+ySA5N8PzsR6bz19kB+P/OPP6/fdFRE1RFg4vvFty0EKj
LQsMVQJERSslADtCr9UsMbSYdPKjrZuIEwlzai0CgYEAv4iXYY4aHyBh08fVdbML
PVd1US0OisMg+bE5GtUqXN0/0q9OhOOE+i8J/bMTwBK+KehYlk/gGMByr9E09oIv
tfrOzty5T0clCiXLgvZxkOYg3SuAH4tjYVR4ND1bqhNL8Tr4PrwOnF5OYRTS9nrX
LAgmxAcZfNAq7RW2tIDLJcECgYBinCAZVwGzP2PkgMPblVsu8oKpHxyHosa6H6AP
kdaS2CQGldWjH1TwfCEp5do3mEu2NbnT9KK9BCYqemqTGRLkdPadLuwpNNeotaBb
3OVz4SMybxfn0tOOnDotCiBcCp1bgPzWBGUsBZYXQCiDrTHIRuhLCCdXeHiM0S0h
s9Fi3QKBgQCSTEOFfz7YQYrxt7KZzF8zEu7YFCjZbxy1aqcSpRbPBDunLqq7Ts/2
kiGBLEK5PCTedHiHcknK9yx/oSTUelHeQtQhCMamRROdXbyAsqqAOC55MIl8MVml
F32TNuerk+kYbOC8pYcFuh2IriKaGy/6Qhyb9J2i/BpXPPOsXMNXpw==
-----END RSA PRIVATE KEY-----
EOF

# Set proper permissions for the key file
chmod 600 "$KEY_FILE"

# Dry run option (uncomment the next line to enable dry-run by default)
# DRY_RUN="--dry-run"

for SOURCE in "${SOURCES[@]}"; do
    if [ ! -d "$SOURCE" ]; then
        echo "Error: Source folder '$SOURCE' does not exist or is not a directory."
        continue
    fi

    SOURCE_PATH="${SOURCE}/"
    RELATIVE_NAME=$(basename "$SOURCE")

    echo "Transferring '$SOURCE' to $USERNAME@$DEST_HOST${DEST_PATH}${RELATIVE_NAME}/"

    rsync -avz \
          --delete \
          -e "ssh -i $KEY_FILE" \
          $DRY_RUN \
          "$SOURCE_PATH" \
          "$USERNAME@$DEST_HOST:${DEST_PATH}${RELATIVE_NAME}/"

    if [ $? -eq 0 ]; then
        echo "Successfully transferred '$SOURCE'."
    else
        echo "Error transferring '$SOURCE'. Check SSH connectivity and permissions."
    fi
    echo "---"
done

echo "Transfer process completed."
