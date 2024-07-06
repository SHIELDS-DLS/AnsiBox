#!/bin/bash

# Variables
USERNAME="admin"
PASSWORD="your_secure_password"
HOME_DIR="/home/$USERNAME"

# List of IP ranges
IP_RANGES=("192.168.1.{2..11}" "192.168.2.{1..11}")

# Function to add admin user
add_admin_user() {
   IP=$1
   echo "Connecting to $IP"
   
   ssh -o StrictHostKeyChecking=no root@$IP <<EOF
   useradd -m -d $HOME_DIR -s /bin/bash $USERNAME
   echo "$USERNAME:$PASSWORD" | chpasswd
   usermod -aG sudo $USERNAME
   echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOF
}

# Loop through IP ranges and add admin user
for RANGE in "${IP_RANGES[@]}"; do
   for IP in $(eval echo $RANGE); do
       add_admin_user $IP
   done
done
