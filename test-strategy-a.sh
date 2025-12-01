#!/bin/bash

set -e

echo "Testing Strategy A - Cloud-init Only"

cd strategy-a

if [ ! -f user-data.yml ]; then
    echo "Error: user-data.yml not found"
    exit 1
fi

echo "Validating cloud-init syntax..."
cloud-init schema --config-file user-data.yml

echo "Strategy A user-data file is valid!"
echo "To test on a VM, copy user-data.yml to your cloud-init instance"
