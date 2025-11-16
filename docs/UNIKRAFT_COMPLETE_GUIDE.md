# 🚀 Guide Complet Unikraft - Unikernels pour OptiVolt

## 📚 Table des Matières

1. [Introduction aux Unikernels](#introduction)
2. [Installation Unikraft](#installation)
3. [Premier Unikernel "Hello World"](#hello-world)
4. [Unikernel Python pour OptiVolt](#python-unikernel)
5. [Benchmarks et Comparaisons](#benchmarks)
6. [Ressources et Liens](#ressources)

---

## 🎯 Introduction aux Unikernels {#introduction}

### Qu'est-ce qu'un Unikernel ?

Un **unikernel** est une image exécutable spécialisée qui compile **une seule application avec uniquement les composants OS nécessaires** dans un espace d'adressage unique protégé.

```
┌─────────────────────────────────────────────────────────────┐
│ ARCHITECTURE TRADITIONNELLE                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Application                                               │
│   ─────────────────────────────────────────                 │
│   Runtime (Python, Node, JVM...)                           │
│   ─────────────────────────────────────────                 │
│   Librairies Système (glibc, openssl...)                   │
│   ─────────────────────────────────────────                 │
│   OS Complet (Linux, BSD...)                               │
│   • Scheduler                                               │
│   • Memory management                                       │
│   • File system                                             │
│   • Network stack                                           │
│   • Device drivers (100+ non utilisés)                     │
│   • Security modules                                        │
│   • ... (95% non utilisé par l'app)                        │
│   ─────────────────────────────────────────                 │
│   Hardware (CPU, RAM, Network)                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
Taille: 500 MB - 2 GB  |  Boot: 1-5 secondes


┌─────────────────────────────────────────────────────────────┐
│ ARCHITECTURE UNIKERNEL (Unikraft)                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Application + LibOS (fusionnés)                          │
│   ─────────────────────────────────────────                 │
│   UNIQUEMENT les composants nécessaires:                   │
│   • Minimal scheduler                                       │
│   • Basic memory allocator                                 │
│   • Network stack (si besoin réseau)                       │
│   • FS minimal (si besoin disque)                          │
│   • PAS de drivers inutiles                                │
│   • PAS de services système                                │
│   ─────────────────────────────────────────                 │
│   Hardware (CPU, RAM, Network)                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
Taille: 1-10 MB  |  Boot: 10-50 ms  |  Sécurité: Surface minimale
```

### Unikraft : Plateforme Unikernel Modulaire

**Unikraft** est un projet open-source qui permet de construire des unikernels **efficaces et spécialisés** en sélectionnant uniquement les composants nécessaires.

**Caractéristiques** :
- 📦 **Modulaire** : Librairies micro (scheduler, allocator, FS, network...)
- 🚀 **Performance** : Boot <10ms, overhead minimal
- 🔒 **Sécurité** : Surface d'attaque réduite de 90%
- 🌍 **Multi-langages** : C, C++, Python, Go, Rust...
- ☁️ **Multi-plateformes** : KVM, Xen, LinuxBoot, bare-metal

---

## 🛠️ Installation Unikraft {#installation}

### Prérequis

```bash
# Ubuntu/Debian/Codespaces
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    libncurses-dev \
    libyaml-dev \
    flex \
    bison \
    git \
    wget \
    socat \
    xz-utils \
    unzip \
    uuid-runtime \
    qemu-system-x86

# Python 3.8+
sudo apt-get install -y python3 python3-pip
```

### Installation de Kraft (Unikraft CLI)

```bash
# Installer kraft via pip
pip3 install git+https://github.com/unikraft/kraft.git

# Vérifier l'installation
kraft --version

# Initialiser l'environnement
kraft list update
```

### Structure de Projet Unikraft

```
my-unikernel/
├── kraft.yaml          # Configuration du projet
├── Makefile           # Build configuration
├── main.c             # Code source de l'application
└── .config            # Configuration du kernel (auto-généré)
```

---

## 👋 Premier Unikernel "Hello World" {#hello-world}

### 1. Créer le Projet

```bash
# Créer un nouveau projet
mkdir hello-unikraft && cd hello-unikraft

# Initialiser avec kraft
kraft init -t helloworld
```

### 2. Fichier kraft.yaml

```yaml
specification: '0.6'

name: hello-unikraft
unikraft:
  version: stable
  kconfig:
    - CONFIG_LIBUKDEBUG_PRINTK=y

targets:
  - platform: kvm
    architecture: x86_64
```

### 3. Code Source (main.c)

```c
#include <stdio.h>
#include <uk/essentials.h>

int main(int argc __unused, char *argv[] __unused)
{
    printf("🚀 Hello from Unikraft Unikernel!\n");
    printf("   This is a LibOS running directly on KVM\n");
    printf("   No full Linux kernel needed!\n");
    
    // Boucle infinie avec charge CPU minimale
    int iteration = 0;
    while (1) {
        for (int i = 0; i < 10000; i++) {
            volatile int result = i * i;
        }
        
        iteration++;
        if (iteration % 100 == 0) {
            printf("[UNIKRAFT] %d iterations\n", iteration);
        }
        
        // Sleep 1 seconde
        uk_pr_info("Iteration %d complete\n", iteration);
        /* Note: sleep nécessite CONFIG_LIBUKSCHED */
    }
    
    return 0;
}
```

### 4. Compiler

```bash
# Configurer (menu interactif)
kraft menuconfig

# OU configuration automatique
kraft configure

# Compiler l'unikernel
kraft build

# Résultat: build/hello-unikraft_kvm-x86_64
# Taille typique: 1-5 MB
```

### 5. Exécuter

```bash
# Lancer avec kraft
kraft run

# OU directement avec QEMU
qemu-system-x86_64 \
    -kernel build/hello-unikraft_kvm-x86_64 \
    -nographic \
    -m 64M \
    -cpu host \
    -enable-kvm

# Boot time: ~10-30ms !
```

---

## 🐍 Unikernel Python pour OptiVolt {#python-unikernel}

### 1. Créer Projet Python Unikernel

```bash
mkdir optivolt-python-unikernel && cd optivolt-python-unikernel

# Initialiser avec template Python
kraft init -t python3
```

### 2. Configuration kraft.yaml

```yaml
specification: '0.6'

name: optivolt-python-unikernel

unikraft:
  version: stable
  kconfig:
    - CONFIG_LIBPYTHON3=y
    - CONFIG_LIBVFSCORE=y
    - CONFIG_LIBUKSCHED=y
    - CONFIG_LIBUKNETDEV=y

libraries:
  python3:
    version: stable

targets:
  - platform: kvm
    architecture: x86_64

volumes:
  app:
    driver: 9pfs
```

### 3. Application Python (app.py)

```python
#!/usr/bin/env python3
"""
OptiVolt Python Unikernel
Simulation de workload minimal pour monitoring énergétique
"""

import time
import sys

def cpu_workload_minimal():
    """Workload CPU ultra-léger pour unikernel"""
    iteration = 0
    
    print("🚀 [PYTHON-UNIKERNEL] OptiVolt Démarré")
    print(f"   Python {sys.version}")
    print("   Running in Unikraft LibOS")
    print("   RAM: ~10-20 MB | CPU: Minimal")
    
    while True:
        # Calculs légers
        for i in range(5000):
            result = i ** 2
        
        iteration += 1
        
        if iteration % 100 == 0:
            print(f"[PYTHON-UNIKERNEL] {iteration} iterations | Unikraft")
        
        time.sleep(0.5)

if __name__ == "__main__":
    try:
        cpu_workload_minimal()
    except KeyboardInterrupt:
        print("\n[PYTHON-UNIKERNEL] Arrêt gracieux")
        sys.exit(0)
```

### 4. Compiler et Exécuter

```bash
# Configurer
kraft configure

# Compiler (peut prendre 10-30 min la première fois)
kraft build

# Exécuter
kraft run -M 64M

# Taille finale: ~10-15 MB (vs 200 MB Docker Python)
# Boot time: ~20-50 ms (vs 1-2s Docker)
# RAM: ~10-20 MB (vs 200 MB Docker)
```

---

## 📊 Benchmarks et Comparaisons {#benchmarks}

### Boot Time Comparison

```
╔═══════════════════╦══════════════╦═══════════════╦════════════════╗
║ Environment       ║ Boot Time    ║ Ready Time    ║ Total          ║
╠═══════════════════╬══════════════╬═══════════════╬════════════════╣
║ Docker Standard   ║ 800-1200 ms  ║ +500 ms       ║ ~1.5 seconds   ║
║ Docker Alpine     ║ 500-800 ms   ║ +300 ms       ║ ~1.0 second    ║
║ Firecracker µVM   ║ 100-150 ms   ║ +50 ms        ║ ~200 ms        ║
║ Unikraft Python   ║ 20-50 ms     ║ +10 ms        ║ ~60 ms         ║
║ Unikraft C        ║ 5-10 ms      ║ instant       ║ ~10 ms         ║
╚═══════════════════╩══════════════╩═══════════════╩════════════════╝
```

### Memory Footprint

```
╔═══════════════════╦═══════════════╦═══════════════╦════════════════╗
║ Environment       ║ Base Image    ║ Runtime RAM   ║ Total          ║
╠═══════════════════╬═══════════════╬═══════════════╬════════════════╣
║ Docker Python     ║ 150 MB        ║ 50-100 MB     ║ 200-250 MB     ║
║ Docker Alpine+Py  ║ 50 MB         ║ 30-80 MB      ║ 80-130 MB      ║
║ Firecracker       ║ 5 MB kernel   ║ 10-20 MB      ║ 15-25 MB       ║
║ Unikraft Python   ║ 10 MB         ║ 5-15 MB       ║ 15-25 MB       ║
║ Unikraft C        ║ 1-2 MB        ║ 1-5 MB        ║ 2-7 MB         ║
╚═══════════════════╩═══════════════╩═══════════════╩════════════════╝
```

### CPU Efficiency (OptiVolt Workload)

```bash
# Script de test
#!/bin/bash

echo "Testing CPU efficiency for 60 seconds..."

# Docker Python
echo "1. Docker Python..."
docker run --rm python:3.11-slim python -c '
import time
for _ in range(60): 
    [i**2 for i in range(100000)]
    time.sleep(1)
' &
DOCKER_PID=$!

# Unikraft C
echo "2. Unikraft C..."
qemu-system-x86_64 -kernel optivolt-unikernel.bin -m 16M -nographic &
UNIKRAFT_PID=$!

# Mesurer CPU avec top
top -b -n 60 -d 1 -p $DOCKER_PID,$UNIKRAFT_PID > cpu_comparison.log

wait

echo "Results in cpu_comparison.log"
```

**Résultats typiques** :
- Docker Python: 15-25% CPU (1 core)
- Unikraft: 5-10% CPU (1 core)
- **Économie: ~60% CPU**

---

## 🔧 Configuration Avancée

### Optimiser pour Minimum RAM

```yaml
# kraft.yaml - Configuration ultra-minimale
unikraft:
  kconfig:
    # Désactiver features inutiles
    - CONFIG_LIBUKDEBUG_PRINTD=n
    - CONFIG_LIBUKDEBUG_PRINTK_CRIT=n
    - CONFIG_LIBUKDEBUG_PRINTK_ERR=n
    - CONFIG_LIBUKDEBUG_PRINTK_WARN=n
    
    # Allocateur minimal
    - CONFIG_LIBUKALLOCBBUDDY=y
    - CONFIG_LIBUKALLOCBBUDDY_SIZE_MAX=134217728  # 128 MB max
    
    # Pas de réseau si pas nécessaire
    - CONFIG_LIBUKNETDEV=n
    
    # Scheduler minimal
    - CONFIG_LIBUKSCHED=y
    - CONFIG_LIBUKSCHED_FCFS=y  # First-Come-First-Serve
```

### Ajouter Support Réseau (Prometheus Exporter)

```yaml
unikraft:
  kconfig:
    - CONFIG_LIBUKNETDEV=y
    - CONFIG_LWIP_SOCKET=y
    - CONFIG_LWIP_TCP=y
    - CONFIG_LWIP_UDP=y

networks:
  - driver: bridge
    ip: 172.44.0.2
```

```python
# app.py avec exporter Prometheus
from prometheus_client import start_http_server, Gauge
import time

cpu_gauge = Gauge('optivolt_cpu_usage', 'CPU usage')
mem_gauge = Gauge('optivolt_memory_mb', 'Memory MB')

start_http_server(8000)  # Exporter sur port 8000

while True:
    # Métriques
    cpu_gauge.set(calculate_cpu())
    mem_gauge.set(get_memory_mb())
    time.sleep(1)
```

---

## 📚 Ressources et Liens {#ressources}

### Documentation Officielle

- **Unikraft** : https://unikraft.org
- **Kraft CLI** : https://github.com/unikraft/kraft
- **Exemples** : https://github.com/unikraft/app-python3

### Papiers de Recherche

1. **"Unikraft: Fast, Specialized Unikernels the Easy Way"** (EuroSys'21)
   - https://dl.acm.org/doi/10.1145/3447786.3456248

2. **"Performance Analysis of Unikernels"** (IEEE CLOUD 2020)

3. **"A Performance Survey of Lightweight Virtualization Techniques"** (2019)

### Communauté

- Discord : https://unikraft.org/community
- GitHub Discussions : https://github.com/unikraft/unikraft/discussions

---

## 🎯 Intégration OptiVolt

### Script de Benchmark Complet

```bash
#!/bin/bash
# compare-all-environments.sh

echo "OptiVolt - Benchmark Docker vs Firecracker vs Unikraft"

# 1. Docker Standard
docker run -d --name optivolt-docker python:3.11-slim \
    python -c 'import time; [print(i) or time.sleep(1) for i in range(60)]'

# 2. Firecracker MicroVM
./launch-firecracker-microvm.sh &

# 3. Unikraft
qemu-system-x86_64 \
    -kernel build/optivolt-unikernel_kvm-x86_64 \
    -m 16M -nographic &

# Monitoring avec Prometheus
curl http://localhost:9090/api/v1/query?query=container_memory_usage_bytes

# Résultats attendus:
# Docker:      ~200 MB RAM, 15% CPU
# Firecracker: ~20 MB RAM,  8% CPU
# Unikraft:    ~10 MB RAM,  5% CPU
```

---

## ✅ Checklist OptiVolt - Unikraft

- [ ] Installer Unikraft et kraft CLI
- [ ] Compiler premier unikernel "Hello World"
- [ ] Mesurer boot time (<50ms)
- [ ] Créer unikernel Python OptiVolt
- [ ] Intégrer avec monitoring Prometheus
- [ ] Comparer avec Docker et Firecracker
- [ ] Documenter réduction RAM (90%)
- [ ] Documenter réduction CPU (60%)
- [ ] Présenter résultats dans rapport

---

**🎉 Fin du Guide Unikraft pour OptiVolt**

Pour plus d'informations : https://unikraft.org/docs/getting-started
