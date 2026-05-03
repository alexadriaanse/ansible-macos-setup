#!/usr/bin/env bash
set -eu

echo "🛠 Mac setup bootstrap"
echo
echo "Choose how this laptop should be configured:"
echo "  1) Admin (advanced tools)"
echo "  2) Family (backups only)"
echo

declare -r SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
declare -r INVENTORY_FILE="$SCRIPT_DIR/inventory.local"
declare -r VARS_FILE="$SCRIPT_DIR/roles/common/vars/kopia.local.yml"

read -p "Enter choice [1/2]: " choice

case "$choice" in
  1)
    echo -e "[admin_laptop]\nlocalhost ansible_connection=local\n\n[family_laptop]" > "$INVENTORY_FILE"
    ;;
  2)
    echo -e "[admin_laptop]\n\n[family_laptop]\nlocalhost ansible_connection=local" > "$INVENTORY_FILE"
    ;;
  *)
    echo "❌ Invalid choice"
    exit 1
    ;;
esac

echo "✅ Role saved to inventory.local"
echo

read -p "Enter name of 1Password item containing credentials for the Backblaze Kopia bucket: " kopia_b2_1p_item
read -p "Enter name of 1Password item containing the Kopia password: " kopia_password_1p_item

cat <<EOF > "$VARS_FILE"
kopia_b2_1p_item: "$kopia_b2_1p_item"
kopia_password_1p_item: "$kopia_password_1p_item"
EOF

echo "✅ Variables saved to kopia.local.yml"

if ! command -v brew >/dev/null; then
  echo "❌ Homebrew must already be installed"
  exit 1
fi

if ! command -v ansible >/dev/null; then
  echo "📦 Installing Ansible"
  brew install ansible
fi

echo "📦 Installing Ansible collections"
ansible-galaxy collection install -r "$SCRIPT_DIR/requirements.yml"

echo
echo "🔐 Make sure 1Password is installed, and Settings > Developer > Integrate with 1Password CLI is enabled"
read -p "Press Enter to continue..."

echo
echo "🧪 Running Ansible in CHECK (dry-run) mode"
ansible-playbook -C playbook.yml

echo
read -p "Apply these changes? (y/N): " confirm
[[ "$confirm" == "y" ]] || {
  echo "❎ Aborted"
  exit 0
}

echo
echo "🚀 Applying configuration"
ansible-playbook playbook.yml

echo "⚙️  Go to System Setting > Privacy & Security > Full Disk Access and add:"
echo "/Applications/KopiaUI.app/Contents/Resources/server/kopia"
read -p "Press Enter to continue..."

echo
echo "✅ Setup complete"
