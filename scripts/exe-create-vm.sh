#!/usr/bin/env bash
set -euo pipefail

VM_NAME="${1:-exe-react-node-demo}"
TAGS="${TAGS:-app,prod,bun,agent}"
COMMENT="${COMMENT:-Bun monorepo deployed from GitHub Actions}"

if [[ ! "$VM_NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Invalid VM name: $VM_NAME" >&2
  echo "Use lowercase letters, numbers, and hyphens, starting with a letter or number." >&2
  exit 1
fi

cat <<'MSG'
This creates an exe.dev VM using the exe.dev SSH control plane.
Prereqs: an exe.dev account, your SSH public key added to exe.dev, and Docker-capable exeuntu image/default VM.
MSG

ssh exe.dev "new --name=$VM_NAME --comment='$COMMENT' --tag=$TAGS"

echo
cat <<MSG
VM requested: $VM_NAME
Next steps:
  1. Confirm it exists: ssh exe.dev ls
  2. Verify Docker:      ssh $VM_NAME.exe.xyz 'docker version && docker compose version'
  3. Attach GitHub integration if this VM will clone/pull a private repo.
  4. Clone the repo on the VM, usually under /home/exedev/<repo>.
  5. Point the HTTPS proxy at production: ssh exe.dev 'share port $VM_NAME 3000'
  6. Keep private by default. To make public: ssh exe.dev 'share set-public $VM_NAME'
MSG
