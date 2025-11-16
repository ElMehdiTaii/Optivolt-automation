#!/bin/bash

DURATION=${1:-30}

echo "[TEST CPU] Démarrage du test CPU pour ${DURATION}s"

# Test de charge CPU simple
python3 -c "
import time
import multiprocessing

def cpu_stress():
    end_time = time.time() + $DURATION
    while time.time() < end_time:
        _ = sum(i*i for i in range(10000))

# Utiliser tous les coeurs disponibles
processes = []
for _ in range(multiprocessing.cpu_count()):
    p = multiprocessing.Process(target=cpu_stress)
    p.start()
    processes.append(p)

# Attendre la fin
for p in processes:
    p.join()

print('[TEST CPU] ✓ Test terminé')
"

exit 0
