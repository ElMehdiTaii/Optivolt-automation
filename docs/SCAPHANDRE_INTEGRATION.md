# 📖 Guide d'Intégration Scaphandre dans OptiVolt

## 🎯 Qu'est-ce que Scaphandre ?

**Scaphandre** est un agent de métrologie open-source dédié à la mesure de la **consommation électrique réelle** (en Watts) de vos services informatiques. Il utilise les compteurs matériels Intel RAPL (Running Average Power Limit) pour fournir des mesures précises de l'énergie consommée.

### Pourquoi l'intégrer dans OptiVolt ?

OptiVolt compare différents environnements de virtualisation (Docker, MicroVM, Unikernel). Scaphandre permet de :
- ✅ Mesurer la **consommation énergétique réelle** en Watts
- ✅ Comparer l'**efficacité énergétique** entre environnements
- ✅ Identifier les **processus les plus énergivores**
- ✅ Prendre des **décisions basées sur des données réelles** d'énergie

---

## 🚀 Installation Rapide

### Option 1 : Via le script automatique (Recommandé)

```bash
cd /home/ubuntu/optivolt-automation
./scripts/setup_scaphandre.sh install
```

### Option 2 : Via OptiVolt CLI

```bash
cd OptiVoltCLI
dotnet run -- scaphandre install
```

### Option 3 : Installation manuelle

```bash
# Télécharger le binaire
wget https://github.com/hubblo-org/scaphandre/releases/download/v1.0.0/scaphandre-v1.0.0-x86_64-unknown-linux-gnu.tar.gz

# Extraire et installer
tar -xzf scaphandre-v1.0.0-x86_64-unknown-linux-gnu.tar.gz
sudo mv scaphandre /usr/local/bin/
sudo chmod +x /usr/local/bin/scaphandre

# Charger le module RAPL
sudo modprobe intel_rapl_common  # ou intel_rapl pour kernels < 5
```

---

## 🔍 Vérification de l'Installation

```bash
# Via le script
./scripts/setup_scaphandre.sh check

# Via OptiVolt CLI
dotnet run -- scaphandre check

# Manuellement
scaphandre --version
scaphandre stdout -t 5  # Test de 5 secondes
```

---

## 📊 Utilisation de Scaphandre

### 1. Collecte Simple (stdout)

Affiche la consommation dans le terminal :

```bash
scaphandre stdout -t 15
```

**Sortie exemple :**
```
Host:   9.39 W    Core    Uncore    DRAM
Socket0 9.39 W    1.50 W
Top 5 consumers:
Power    PID    Exe
4.81 W   642    "/usr/sbin/dockerd"
4.81 W   703    "/usr/bin/docker-containerd"
0 W      1      "/usr/lib/systemd/systemd"
```

### 2. Collecte en JSON

Pour intégration automatique :

```bash
# Via le script (30 secondes)
./scripts/setup_scaphandre.sh run results/power_metrics.json 30

# Via OptiVolt CLI
dotnet run -- scaphandre collect --duration 30 --output results/power_metrics.json

# Manuellement
scaphandre json -t 1 -s > metrics.json
```

**Format JSON généré :**
```json
{
  "available": true,
  "host_power_watts": 9.39,
  "socket_power_watts": 8.45,
  "top_consumers": [
    {"pid": 642, "exe": "/usr/sbin/dockerd", "power_w": 4.81},
    {"pid": 703, "exe": "/usr/bin/docker-containerd", "power_w": 4.81}
  ]
}
```

### 3. Mode Prometheus (HTTP)

Expose les métriques sur un endpoint HTTP :

```bash
# Via le script
./scripts/setup_scaphandre.sh prometheus 8080

# Manuellement
scaphandre prometheus --port 8080
```

Accès aux métriques :
```bash
curl http://localhost:8080/metrics
```

### 4. Mode Docker

```bash
# Via le script
./scripts/setup_scaphandre.sh docker

# Manuellement
docker run --rm \
  -v /sys/class/powercap:/sys/class/powercap:ro \
  -v /proc:/proc:ro \
  -p 8080:8080 \
  hubblo/scaphandre prometheus
```

---

## 🔧 Intégration dans OptiVolt

### A. Via OptiVolt CLI

Le CLI inclut maintenant des commandes Scaphandre :

```bash
cd OptiVoltCLI

# Installation
dotnet run -- scaphandre install

# Vérification
dotnet run -- scaphandre check

# Collecte de métriques
dotnet run -- scaphandre collect --duration 60 --output ../results/power.json
```

### B. Via les Scripts de Collecte

Le script `collect_metrics.sh` intègre automatiquement Scaphandre :

```bash
./scripts/collect_metrics.sh docker 30 results/docker_metrics.json
```

Le JSON généré inclut désormais une section `energy_metrics` avec Scaphandre :

```json
{
  "metadata": { ... },
  "system_metrics": { ... },
  "energy_metrics": {
    "note": "Real power consumption measured by Scaphandre",
    "scaphandre": {
      "available": true,
      "host_power_watts": 12.5,
      "socket_power_watts": 10.2,
      "top_consumers": [...]
    }
  },
  "container_metrics": { ... }
}
```

### C. Via GitLab CI/CD

Le pipeline inclut maintenant un stage `power-monitoring` :

```yaml
# Dans .gitlab-ci.yml
stages:
  - build
  - deploy
  - test
  - metrics
  - power-monitoring  # ⚡ NOUVEAU
  - report
```

**Jobs disponibles :**
- `power:scaphandre-setup` : Vérifie l'installation
- `power:collect-energy` : Collecte les métriques de consommation

---

## 📋 Prérequis Système

### ✅ CPU Supportés
- **Intel** : CPUs avec support RAPL (depuis Sandy Bridge, 2011)
- **AMD** : Certains CPUs récents (Zen 2+)

### ✅ Systèmes d'Exploitation
- Linux (kernel 2.6.32+)
- Windows 10/11, Server 2016/2019/2022

### ✅ Permissions
```bash
# Vérifier l'accès à RAPL
ls -la /sys/class/powercap/intel-rapl:0/

# Si permissions insuffisantes, utiliser sudo
sudo scaphandre stdout -t 10
```

### ✅ Module Kernel
```bash
# Charger le module RAPL
sudo modprobe intel_rapl_common  # Kernel 5+
sudo modprobe intel_rapl         # Kernel < 5

# Vérifier
lsmod | grep rapl
```

---

## 🔄 Workflow Complet avec Scaphandre

### Workflow OptiVolt + Scaphandre

```
┌─────────────────────────────────┐
│ 1. DEPLOY Environments          │
│   ├─ Docker                     │
│   ├─ MicroVM                    │
│   └─ Unikernel                  │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│ 2. RUN Tests                    │
│   ├─ CPU Load                   │
│   ├─ API Stress                 │
│   └─ Database Queries           │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│ 3. COLLECT Metrics              │
│   ├─ System (CPU, RAM, I/O)    │
│   └─ ⚡ Scaphandre (Power)      │ ← NOUVEAU
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│ 4. ANALYZE & COMPARE            │
│   • Docker: 15.2W moyenne       │
│   • MicroVM: 8.7W moyenne       │
│   • Unikernel: 6.1W moyenne     │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│ 5. REPORT & DASHBOARD           │
│   └─ Graphiques énergétiques    │
└─────────────────────────────────┘
```

---

## 📖 Exemples d'Utilisation

### Exemple 1 : Test Docker avec Scaphandre

```bash
# 1. Déployer l'environnement
cd OptiVoltCLI
dotnet run -- deploy --environment docker

# 2. Lancer les tests
dotnet run -- test --environment docker --type all

# 3. Collecter les métriques (inclut Scaphandre)
dotnet run -- metrics --environment docker

# 4. Collecter uniquement l'énergie
dotnet run -- scaphandre collect --duration 60 --output results/docker_power.json

# 5. Générer le rapport
dotnet run -- report
```

### Exemple 2 : Comparaison Multi-Environnements

```bash
#!/bin/bash
# Script de comparaison énergétique

ENVIRONMENTS=("docker" "microvm" "unikernel")

for env in "${ENVIRONMENTS[@]}"; do
  echo "🚀 Déploiement: $env"
  dotnet run -- deploy --environment $env
  
  echo "🧪 Tests: $env"
  dotnet run -- test --environment $env --type all
  
  echo "⚡ Collecte énergie: $env"
  dotnet run -- scaphandre collect --duration 120 --output results/${env}_power.json
  
  sleep 10
done

echo "📊 Génération du rapport comparatif"
dotnet run -- report
```

### Exemple 3 : Monitoring Continu

```bash
# Lancer Scaphandre en mode Prometheus
scaphandre prometheus --port 8080 &

# Dans un autre terminal, collecter pendant 5 minutes
sleep 300

# Analyser avec curl
curl -s http://localhost:8080/metrics | grep scaph_host_power_microwatts
```

---

## 🛠️ Troubleshooting

### Problème 1 : "Module RAPL non trouvé"

```bash
# Solution : Charger le module
sudo modprobe intel_rapl_common

# Vérifier
ls -la /sys/class/powercap/
```

### Problème 2 : "Permission denied"

```bash
# Solution : Utiliser sudo
sudo scaphandre stdout -t 10

# Ou modifier les permissions (permanent)
sudo chmod -R a+r /sys/class/powercap/intel-rapl:0/
```

### Problème 3 : "CPU non supporté"

Si votre CPU ne supporte pas RAPL :
- ❌ Scaphandre ne pourra pas mesurer l'énergie
- ✅ Utilisez les autres métriques OptiVolt (CPU%, RAM, I/O)
- 💡 Envisagez d'utiliser un estimateur (future feature)

### Problème 4 : "Scaphandre not found"

```bash
# Vérifier l'installation
which scaphandre

# Réinstaller
./scripts/setup_scaphandre.sh install

# Ou utiliser Docker
./scripts/setup_scaphandre.sh docker
```

---

## 📊 Interprétation des Métriques

### Unités de Mesure

- **Watts (W)** : Puissance instantanée
- **Joules (J)** : Énergie totale consommée
- **Watt-heures (Wh)** : Énergie sur une période

### Ordres de Grandeur

- **Serveur au repos** : 5-15W
- **Serveur avec charge légère** : 15-50W
- **Serveur avec charge élevée** : 50-150W
- **Processus Docker** : 1-10W typiquement

### Comparaison Environnements

Résultats typiques attendus :
```
Environment    Power (W)    Efficiency
─────────────────────────────────────
Docker         15-25W       Baseline
MicroVM        8-15W        40% plus efficace
Unikernel      5-10W        60% plus efficace
```

---

## 🔗 Ressources Utiles

### Documentation Scaphandre
- [Documentation officielle](https://hubblo-org.github.io/scaphandre-documentation/)
- [GitHub Repository](https://github.com/hubblo-org/scaphandre)
- [Releases](https://github.com/hubblo-org/scaphandre/releases)

### Compatibilité
- [Liste des CPUs supportés](https://hubblo-org.github.io/scaphandre-documentation/compatibility.html)
- [Troubleshooting Guide](https://hubblo-org.github.io/scaphandre-documentation/troubleshooting.html)

### Exporters
- [Prometheus Exporter](https://hubblo-org.github.io/scaphandre-documentation/references/exporter-prometheus.html)
- [JSON Exporter](https://hubblo-org.github.io/scaphandre-documentation/references/exporter-json.html)

---

## 🎓 FAQ

### Q1 : Scaphandre fonctionne-t-il dans une VM ?

**R :** Partiellement. Scaphandre peut fonctionner dans une VM si :
- L'hyperviseur expose les métriques RAPL à la VM
- Vous utilisez QEMU/KVM avec les bonnes configurations
- Référence : [Propagate metrics from hypervisor to VM](https://hubblo-org.github.io/scaphandre-documentation/how-to_guides/propagate-metrics-hypervisor-to-vm_qemu-kvm.html)

### Q2 : Quelle est la précision des mesures ?

**R :** Scaphandre utilise les compteurs matériels Intel RAPL, qui ont une précision de :
- ± 5-10% pour les mesures CPU
- Mise à jour toutes les ~1ms
- Plus précis que les estimations logicielles

### Q3 : Puis-je utiliser Scaphandre avec Kubernetes ?

**R :** Oui ! Scaphandre supporte Kubernetes. Consultez le [Helm Chart](https://github.com/hubblo-org/scaphandre/tree/main/helm/scaphandre).

### Q4 : Scaphandre impacte-t-il les performances ?

**R :** Impact minimal :
- Overhead CPU : < 0.1%
- Overhead RAM : ~5-10 MB
- Pas de dégradation mesurable des performances

### Q5 : Comment intégrer avec Grafana ?

**R :** 
1. Lancer Scaphandre en mode Prometheus
2. Configurer Prometheus pour scraper l'endpoint
3. Créer des dashboards Grafana
4. Exemple : [https://metrics.hubblo.org](https://metrics.hubblo.org)

---

## 🚀 Prochaines Étapes

1. **Installer Scaphandre** sur votre environnement
   ```bash
   ./scripts/setup_scaphandre.sh install
   ```

2. **Vérifier le fonctionnement**
   ```bash
   ./scripts/setup_scaphandre.sh check
   ```

3. **Lancer une première collecte**
   ```bash
   cd OptiVoltCLI
   dotnet run -- scaphandre collect --duration 30
   ```

4. **Intégrer dans vos tests**
   ```bash
   dotnet run -- metrics --environment docker
   ```

5. **Analyser les résultats** dans `results/`

---

## 📝 Notes Importantes

⚠️ **Limitations connues** :
- Nécessite un CPU Intel avec support RAPL (ou AMD récent)
- Peut nécessiter des privilèges root selon la configuration
- Les mesures RAPL ne sont pas disponibles dans tous les conteneurs Docker

✅ **Bonnes pratiques** :
- Collecter pendant au moins 30 secondes pour des moyennes fiables
- Comparer des environnements dans des conditions similaires
- Utiliser le mode JSON pour automatisation
- Monitorer en continu avec Prometheus pour production

🎯 **Cas d'usage OptiVolt** :
- Comparer l'efficacité énergétique Docker vs MicroVM vs Unikernel
- Identifier les workloads les plus énergivores
- Optimiser le placement de charges de travail
- Mesurer l'impact des optimisations

---

**🔌 Bon monitoring énergétique avec Scaphandre et OptiVolt !**
