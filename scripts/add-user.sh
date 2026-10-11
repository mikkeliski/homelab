#!/usr/bin/env bash
#
# Create a key-only user account without sudo rights and install an SSH public key.
#
# Usage:
#   sudo bash add-user.sh <username> '<ssh public key line>'
#
# The account gets no password, so it can only log in with the key.
# It is not added to the sudo or docker groups.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run this with sudo." >&2
  exit 1
fi

if [[ $# -ne 2 ]]; then
  echo "Usage: sudo bash $0 <username> '<ssh public key line>'" >&2
  exit 1
fi

user="$1"
key="$2"

# Usernames: lowercase letter first, then lowercase letters, digits or hyphens.
if ! [[ "$user" =~ ^[a-z][a-z0-9-]{0,31}$ ]]; then
  echo "Invalid username: $user" >&2
  exit 1
fi

# Refuse anything that is not a single valid public key line.
if [[ "$key" == *$'\n'* ]] || ! printf '%s\n' "$key" | ssh-keygen -lf - >/dev/null 2>&1; then
  echo "That does not look like a valid SSH public key." >&2
  exit 1
fi

if id "$user" >/dev/null 2>&1; then
  read -r -p "User '$user' already exists. Add this key to that account? [y/N] " answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Nothing changed."
    exit 0
  fi
else
  adduser --disabled-password --gecos "" "$user"
fi

home_dir="$(getent passwd "$user" | cut -d: -f6)"
ssh_dir="$home_dir/.ssh"
auth_file="$ssh_dir/authorized_keys"

install -d -m 700 -o "$user" -g "$user" "$ssh_dir"
touch "$auth_file"

# Add the key only if that exact line is not already there.
if ! grep -qxF "$key" "$auth_file"; then
  printf '%s\n' "$key" >> "$auth_file"
fi

chown "$user:$user" "$auth_file"
chmod 600 "$auth_file"

echo "Done. '$user' can log in with the key with this fingerprint:"
printf '%s\n' "$key" | ssh-keygen -lf -
echo "Remember to share the machine with them in Tailscale."
