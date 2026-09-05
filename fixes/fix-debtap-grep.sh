#!/bin/bash
# Fix for debtap grep 3.8+ compatibility bug
# Debtap uses an invalid regex that fails on newer grep versions, making it think the database is empty.
# This patches the /usr/bin/debtap script to use a valid regex.

echo "Applying debtap grep compatibility fix..."

if [ -f /usr/bin/debtap ]; then
    # We use sudo because /usr/bin/debtap is owned by root
    sudo sed -i "s/grep -E '\*\.files?(\.\[\[:digit:\]\]{3})'/grep -E '\\\.files'/g" /usr/bin/debtap
    echo "debtap has been patched!"
else
    echo "Error: /usr/bin/debtap not found. Is debtap installed?"
    exit 1
fi
