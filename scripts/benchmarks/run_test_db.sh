#!/bin/bash

DURATION=${1:-30}

echo "[TEST DB] Démarrage du test DB pour ${DURATION}s"

# Test de charge mémoire/IO simple
python3 -c "
import time
import random

end_time = time.time() + $DURATION
data = []

print('[TEST DB] Simulation de charges DB...')
while time.time() < end_time:
    # Simuler des écritures
    data.append({'id': len(data), 'value': random.random()})
    
    # Simuler des lectures
    if len(data) > 100:
        _ = [d for d in data if d['value'] > 0.5]
    
    # Limiter la taille
    if len(data) > 10000:
        data = data[-5000:]
    
    time.sleep(0.01)

print(f'[TEST DB] ✓ Test terminé - {len(data)} opérations')
"

exit 0
