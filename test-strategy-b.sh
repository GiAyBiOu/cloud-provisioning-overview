#!/bin/bash

set -e

echo "Testing Strategy B - Cloud-init + Ansible"

cd strategy-b

if [ ! -f user-data.yml ]; then
    echo "Error: user-data.yml not found"
    exit 1
fi

echo "Validating cloud-init syntax..."
cloud-init schema --config-file user-data.yml

echo ""
echo "Validating Ansible playbook syntax..."
cd ansible

if command -v ansible-playbook &> /dev/null; then
    ansible-playbook --syntax-check site.yml
    echo "Ansible playbook syntax is valid!"
else
    echo "Warning: ansible-playbook not found, skipping syntax check"
fi

echo ""
echo "Strategy B files are validated!"
echo "To test:"
echo "1. Deploy VM with user-data.yml"
echo "2. After cloud-init completes, run: cd /opt/ansible-playbooks && ansible-playbook site.yml"
