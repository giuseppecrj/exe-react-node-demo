#!/usr/bin/env bash
set -euo pipefail

VM_NAME="${1:-exe-react-node-demo}"

if [[ ! "$VM_NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Invalid VM name: $VM_NAME" >&2
  echo "Use lowercase letters, numbers, and hyphens, starting with a letter or number." >&2
  exit 1
fi

cat <<'MSG'
This creates an exe.dev VM using the exe.dev SSH control plane.
Prereqs: an exe.dev account, your SSH public key added to exe.dev, and Docker-capable exeuntu image/default VM.
MSG

ssh exe.dev "new --name=$VM_NAME --comment='React + Node demo deployed from GitHub Actions' --tag=demo,react,node"

echo
cat <<MSG
VM requested: $VM_NAME
Next steps:
  1. Confirm it exists: ssh exe.dev ls
  2. SSH in once:       ssh $VM_NAME.exe.xyz
  3. Ensure Docker works: docker run --rm alpine:latest echo hello
  4. In GitHub repo settings, add secrets:
       EXE_VM_HOST=$VM_NAME.exe.xyz
       EXE_SSH_PRIVATE_KEY=<private key matching an SSH key registered in exe.dev>
  5. Push to main or run the Deploy to exe.dev workflow manually.
  6. If exe.dev does not auto-pick port 3000: ssh exe.dev share port $VM_NAME 3000
  7. To make it public: ssh exe.dev share set-public $VM_NAME
MSG
