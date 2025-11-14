# OptiVolt - Analyse de Performance Énergétique

> Pipeline automatisé pour comparer la consommation énergétique entre Docker, MicroVM et Unikernel

[![Pipeline Status](https://img.shields.io/badge/pipeline-passing-brightgreen)]() 
[![.NET](https://img.shields.io/badge/.NET-8.0-blue)]()
[![License](https://img.shields.io/badge/license-Academic-orange)]()

## 🎯 Objectif

Créer un pipeline CI/CD automatisé pour :
- Déployer des environnements (Docker, MicroVM, Unikernel)
- Exécuter des tests de charge
- Collecter des métriques de performance et d'énergie
- Visualiser les résultats dans un tableau de bord

## 🏗️ Architecture

```
optivolt/
├── OptiVoltCLI/              # Application .NET CLI
│   ├── Commands/             # Commandes deploy, test, collect
│   ├── Services/             # SSH, Metrics, Configuration
│   └── Models/               # HostConfig, TestResult
├── scripts/                  # Scripts de déploiement et collecte
├── monitoring/               # Stack Grafana + Prometheus
├── .gitlab/ci/               # Configuration CI/CD modulaire
└── docs/                     # Documentation technique
```

## 🚀 Quick Start

### Prérequis

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0 docker.io python3 python3-pip
pip3 install psutil
```

### Installation

```bash
# Cloner le projet
git clone https://gitlab.com/mehdi_taii/optivolt.git
cd optivolt

# Compiler OptiVoltCLI
cd OptiVoltCLI
dotnet build -c Release -o ../publish
cd ..

# Tester localement
./test_local_deployment.sh
```

### Démarrer le Monitoring

```bash
# Lancer Grafana + Prometheus
./start-monitoring.sh

# Accéder à Grafana: http://localhost:3000
# Login: admin / optivolt2025
```

## 📊 Utilisation

### CLI Commands

```bash
cd publish

# Déployer un environnement
dotnet OptiVoltCLI.dll deploy --environment docker

# Exécuter des tests
dotnet OptiVoltCLI.dll test --environment docker --type cpu --duration 30

# Collecter les métriques
dotnet OptiVoltCLI.dll collect --environment docker
```

### Pipeline GitLab CI

Le pipeline s'exécute automatiquement sur chaque push :

```yaml
stages:
  - build              # Compilation .NET
  - deploy             # Déploiement environnements
  - test               # Tests de charge
  - metrics            # Collecte métriques
  - power-monitoring   # Métriques énergétiques
  - report             # Génération dashboard
```

## 🔧 Configuration SSH

Pour déployer sur des serveurs distants :

```bash
# Générer une clé SSH
ssh-keygen -t ed25519 -C "optivolt@gitlab"

# Copier sur le serveur distant
ssh-copy-id user@serveur-distant

# Mettre à jour config/hosts.json
{
  "environments": {
    "microvm": {
      "hostname": "192.168.1.101",
      "port": 22,
      "username": "optivolt",
      "privateKeyPath": "~/.ssh/id_ed25519",
      "workingDirectory": "/home/optivolt/tests"
    }
  }
}
```

## 📈 Métriques Collectées

### Performance
- CPU usage (%)
- Memory usage (MB)
- Disk I/O (MB/s)
- Network throughput (Mbps)
- Response time (ms)

### Énergie (Scaphandre)
- Consommation électrique (Watts)
- Consommation par socket CPU
- Consommation par processus
- Basé sur Intel RAPL

| Document | Description |
|----------|-------------|
| [RAPPORT_ETAT_PROJET.md](./RAPPORT_ETAT_PROJET.md) | Rapport complet d'état du projet |
| [docs/SCAPHANDRE_INTEGRATION.md](./docs/SCAPHANDRE_INTEGRATION.md) | Guide d'intégration Scaphandre |
| [docs/GRAFANA_INTEGRATION.md](./docs/GRAFANA_INTEGRATION.md) | Configuration dashboards Grafana |
| [.gitlab/ci/README.md](./.gitlab/ci/README.md) | Documentation pipeline CI/CD |

## 🧪 Tests

```bash
# Tests locaux complets
./test_local_deployment.sh

# Workload benchmark
WORKLOAD_DURATION=30 WORKLOAD_INTENSITY=heavy python3 scripts/workload_benchmark.py

# Métriques énergétiques
./scripts/setup_scaphandre.sh install
./scripts/setup_scaphandre.sh check
```

## 🔗 Liens

- **GitLab**: https://gitlab.com/mehdi_taii/optivolt
- **Pipeline**: https://gitlab.com/mehdi_taii/optivolt/-/pipelines
- **Scaphandre**: https://github.com/hubblo-org/scaphandre

## � Stack Technique

- **.NET 8.0** - Application CLI
- **Docker** - Containerisation
- **GitLab CI/CD** - Pipeline automatisé
- **Scaphandre** - Monitoring énergétique
- **Prometheus** - Base de données métriques
- **Grafana** - Visualisation
- **Python 3** - Scripts de benchmark
- **Bash** - Scripts d'automatisation