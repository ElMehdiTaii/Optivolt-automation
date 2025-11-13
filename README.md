# OptiVolt - Analyse de Performance Énergétique

Projet d'automatisation pour comparer la consommation énergétique entre Docker, MicroVM et Unikernel.

## 🎯 Objectif

Créer un pipeline automatisé pour :
- Déployer des environnements (Docker, MicroVM, Unikernel)
- Exécuter des tests de charge
- Collecter des métriques de performance et d'énergie
- Visualiser les résultats dans un tableau de bord

## 🏗️ Architecture

```
OptiVolt
├── OptiVoltCLI/              # Application .NET CLI
├── scripts/                  # Scripts de déploiement et collecte
├── monitoring/               # Stack Grafana + Prometheus
├── config/                   # Configuration des hôtes
└── docs/                     # Documentation complète
```

## 🚀 Démarrage Rapide

### Prérequis

- .NET 8.0 SDK
- Docker
- Python 3.11+
- GitLab Runner (optionnel)

### Installation

```bash
# Cloner le projet
git clone https://gitlab.com/mehdi_taii/optivolt.git
cd optivolt

# Compiler OptiVoltCLI
cd OptiVoltCLI
dotnet build -c Release -o ../publish

# Tester localement
cd ..
./test_local_deployment.sh
```

### Démarrer le Monitoring

```bash
# Lancer Grafana + Prometheus + Scaphandre
./start-monitoring.sh

# Accéder à Grafana
# URL: http://localhost:3000
# Login: admin / optivolt2025
```

## 📊 Utilisation

### Commandes CLI

```bash
cd publish

# Déployer un environnement
dotnet OptiVoltCLI.dll deploy --environment docker

# Exécuter des tests
dotnet OptiVoltCLI.dll test --environment docker --type cpu

# Collecter les métriques
dotnet OptiVoltCLI.dll collect --environment docker

# Installer Scaphandre
dotnet OptiVoltCLI.dll scaphandre install

# Vérifier Scaphandre
dotnet OptiVoltCLI.dll scaphandre check

# Collecter métriques énergétiques
dotnet OptiVoltCLI.dll scaphandre collect --duration 30
```

### Pipeline GitLab CI

Le pipeline automatique comprend 6 stages :

1. **Build** : Compilation OptiVoltCLI
2. **Deploy** : Déploiement environnements
3. **Test** : Tests de charge (CPU, API, DB)
4. **Metrics** : Collecte métriques + workload benchmark
5. **Power-monitoring** : Métriques énergétiques Scaphandre
6. **Report** : Génération tableau de bord HTML

### Configuration SSH pour Déploiements Distants

```bash
# Générer une clé SSH
ssh-keygen -t ed25519 -C "optivolt@gitlab"

# Copier sur le serveur distant
ssh-copy-id user@serveur-distant

# Mettre à jour config/hosts.json
{
  "hosts": {
    "microvm": {
      "hostname": "microvm.example.com",
      "ip": "XXX.XXX.XXX.XXX",
      "user": "ubuntu",
      "port": 22,
      "workdir": "/home/ubuntu/optivolt-tests"
    }
  }
}
```

## 📈 Métriques Collectées

### Workload Benchmark
- Charge CPU intensive (calculs cryptographiques)
- Consommation mémoire
- Throughput (itérations/sec)
- Durée et intensité configurables

### Scaphandre (Power Monitoring)
- Consommation électrique totale (Watts)
- Consommation par socket CPU
- Consommation par processus
- Basé sur Intel RAPL

### Métriques Système
- CPU utilisation (%)
- Mémoire (MB)
- I/O disque
- Réseau

## 📁 Structure des Fichiers

```
.
├── README.md                       # Ce fichier
├── CONFORMITE_FINALE.md            # Document de conformité
├── .gitlab-ci.yml                  # Pipeline CI/CD
├── docker-compose-monitoring.yml   # Stack monitoring
├── start-monitoring.sh             # Démarrage monitoring
├── test_local_deployment.sh        # Tests locaux
│
├── OptiVoltCLI/                    # Application CLI
│   ├── Program.cs                  # Code principal (957 lignes)
│   ├── OptiVoltCLI.csproj          # Projet .NET 8.0
│   └── publish/                    # Binaires compilés
│
├── scripts/                        # Scripts automation
│   ├── deploy_docker.sh            # Déploiement Docker
│   ├── deploy_microvm.sh           # Déploiement MicroVM
│   ├── deploy_unikernel.sh         # Déploiement Unikernel
│   ├── setup_scaphandre.sh         # Installation Scaphandre
│   ├── workload_benchmark.py       # Benchmark de charge
│   ├── collect_metrics.sh          # Collecte métriques
│   └── generate_dashboard.py      # Génération rapport
│
├── config/                         # Configuration
│   └── hosts.json                  # Définition des hôtes
│
├── monitoring/                     # Stack monitoring
│   ├── grafana/                    # Configuration Grafana
│   │   ├── dashboards/             # Dashboards JSON
│   │   └── provisioning/           # Auto-provisioning
│   └── prometheus/                 # Configuration Prometheus
│       └── prometheus.yml
│
├── docs/                           # Documentation
│   ├── SCAPHANDRE_INTEGRATION.md   # Guide Scaphandre
│   └── GRAFANA_INTEGRATION.md      # Guide Grafana
│
└── results/                        # Résultats des tests
    ├── workload_results.json
    ├── docker_deploy_results.json
    └── dashboard.html
```

## 🔧 Technologies Utilisées

- **.NET 8.0** : Application CLI
- **Docker** : Containerisation
- **GitLab CI/CD** : Pipeline automatisé
- **Scaphandre** : Monitoring énergétique
- **Prometheus** : Base de données métriques
- **Grafana** : Visualisation
- **Python 3.11** : Scripts de benchmark
- **Bash** : Scripts d'automatisation

## 📚 Documentation

- [CONFORMITE_FINALE.md](./CONFORMITE_FINALE.md) - Conformité avec la tâche
- [docs/SCAPHANDRE_INTEGRATION.md](./docs/SCAPHANDRE_INTEGRATION.md) - Guide Scaphandre
- [docs/GRAFANA_INTEGRATION.md](./docs/GRAFANA_INTEGRATION.md) - Guide Grafana

## 🧪 Tests

### Tests Locaux

```bash
# Déploiement Docker complet
./test_local_deployment.sh

# Workload benchmark
WORKLOAD_DURATION=30 WORKLOAD_INTENSITY=heavy python3 scripts/workload_benchmark.py

# Monitoring stack
./start-monitoring.sh
```

### Tests GitLab CI

Pipeline déclenché automatiquement sur chaque push vers `main`.

URL : https://gitlab.com/mehdi_taii/optivolt/-/pipelines

## 📝 Licence

Projet académique - Tous droits réservés

## 👤 Auteur

Mehdi Taii - OptiFit Project

## 🔗 Liens

- **GitLab** : https://gitlab.com/mehdi_taii/optivolt
- **Pipeline** : https://gitlab.com/mehdi_taii/optivolt/-/pipelines
- **Scaphandre** : https://github.com/hubblo-org/scaphandre
