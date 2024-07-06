#!/bin/bash

# Déclaration des variables
RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

# Variables
SMB_SERVER="192.168.1.11"
SMB_SHARE="Antarctique"
SMB_FILE="manchot.txt"
REDIS_SERVER="192.168.1.11"
REDIS_PORT="6379"
WEB_SERVER="192.168.1.11"
WEB_PATH="/shields"
WEB_FILES=("pass" "user")
SSH_USER="carol"
SSH_PASS="archer_mentealeau"
SSH_SERVER="192.168.1.11"
SSH_FILE_PATH="/home/carol/papapingouin.zip"

# Function to check file on Samba share
check_smb_file() {
    smbclient -N "\\\\${SMB_SERVER}\\${SMB_SHARE}" -c "ls" | grep -q "$SMB_FILE"
    return $?
}

# Function to check file on web server
check_web_file() {
    local file=$1
    curl -s -I "http://${WEB_SERVER}${WEB_PATH}/${file}" | grep -q "200 OK"
    return $?
}

# Function to check file on SSH server
check_ssh_file() {
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SSH_SERVER" "test -f $SSH_FILE_PATH"
    return $?
}

# Check SMB file
if check_smb_file; then
    echo -e "${RED}Not Patched : SMB file $SMB_FILE found on $SMB_SHARE.${ENDCOLOR}"
    smbclient -N "\\\\${SMB_SERVER}\\${SMB_SHARE}" -c "get $SMB_FILE"
else
    echo -e "${GREEN}Patched : SMB file $SMB_FILE not found on $SMB_SHARE.${ENDCOLOR}"
fi

# Check Redis connection
echo "Checking Redis connection..."
if redis-cli -h "$REDIS_SERVER" -p "$REDIS_PORT" ping | grep -q "PONG"; then
    echo -e "${RED}Not Patched : Connected to Redis on $REDIS_SERVER:$REDIS_PORT.${ENDCOLOR}"
else
    echo -e "${GREEN}Patched : Failed to connect to Redis on $REDIS_SERVER:$REDIS_PORT.${ENDCOLOR}"
fi

# Check web files
all_web_files_found=true
for file in "${WEB_FILES[@]}"; do
    if check_web_file "$file"; then
        echo -e "${RED}Not Patched : Web file $file found on $WEB_PATH.${ENDCOLOR}"
    else
        echo -e "${GREEN}Patched : Web file $file not found on $WEB_PATH.${ENDCOLOR}"
        all_web_files_found=false
    fi
done

# Check SSH file if all web files are found
if $all_web_files_found; then
    echo "All web files found, checking SSH file..."
    if check_ssh_file; then
        echo -e "${RED}Not Patched : SSH file $SSH_FILE_PATH found.${ENDCOLOR}"
    else
        echo -e "${GREEN} Patched : SSH file $SSH_FILE_PATH not found.${ENDCOLOR}"
    fi
else
    echo "Not all web files found, skipping SSH file check"
fi
