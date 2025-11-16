#!/bin/bash

RESULTS_DIR="$HOME/optivolt-automation/results"

echo "=== VALIDATION DES MÉTRIQUES ==="
echo ""

VALID=0
INVALID=0

for file in $RESULTS_DIR/*_metrics_*.json; do
    if [ -f "$file" ]; then
        if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
            echo "✓ $(basename $file)"
            VALID=$((VALID + 1))
        else
            echo "✗ $(basename $file) - JSON INVALIDE"
            INVALID=$((INVALID + 1))
        fi
    fi
done

echo ""
echo "Résumé: $VALID valides, $INVALID invalides"

if [ $INVALID -gt 0 ]; then
    exit 1
else
    exit 0
fi
