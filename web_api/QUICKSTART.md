# 🚀 OptiVolt Web API - Guide de Démarrage Rapide

## Vue d'ensemble

Ce guide vous permet de tester l'API web OptiVolt sur 4 plateformes différentes :
- **Docker Standard** (python:3.12-slim, 512MB, 2 CPUs)
- **Docker MicroVM** (optimisé Firecracker, 256MB, 1 CPU)
- **Docker Minimal** (alpine, 128MB, 0.5 CPU)
- **Unikraft Unikernel** (QEMU, 64MB)

## Prérequis

```bash
# Docker installé et fonctionnel
docker --version

# Monitoring OptiVolt démarré
./start-monitoring.sh

# Optionnel : Kraft pour unikernel
curl --proto '=https' --tlsv1.2 -sSf https://get.kraftkit.sh | sh
```

## 🎯 Démarrage Rapide (30 secondes)

### 1. Déployer toutes les variantes

```bash
cd /workspaces/Optivolt-automation
./scripts/deployment/deploy_webapi_all.sh deploy
```

Cette commande :
- ✅ Build les 3 images Docker (standard, microvm, minimal)
- ✅ Lance les conteneurs sur les ports 8001, 8002, 8003
- ✅ Build et lance l'unikernel Unikraft sur le port 8004
- ✅ Vérifie que tous les endpoints répondent

### 2. Vérifier le statut

```bash
./scripts/deployment/deploy_webapi_all.sh status
```

Output attendu :
```
Docker Containers:
NAMES                        STATUS              PORTS
optivolt-webapi-standard     Up 2 minutes        0.0.0.0:8001->8000/tcp
optivolt-webapi-microvm      Up 2 minutes        0.0.0.0:8002->8000/tcp
optivolt-webapi-minimal      Up 2 minutes        0.0.0.0:8003->8000/tcp

Endpoints:
  Standard (Docker):  http://localhost:8001
  MicroVM (Docker):   http://localhost:8002
  Minimal (Docker):   http://localhost:8003
  Unikernel (Kraft):  http://localhost:8004
```

### 3. Tester les APIs

```bash
# Test rapide de tous les endpoints
curl http://localhost:8001/
curl http://localhost:8002/
curl http://localhost:8003/
curl http://localhost:8004/
```

Réponse attendue : `{"message":"Welcome to fake API"}`

## 📊 Monitoring et Dashboard

### Créer le dashboard Grafana

```bash
./scripts/dashboards/create-webapi-dashboard.sh
```

Accéder au dashboard :
- **URL:** http://localhost:3000/d/optivolt-webapi
- **Credentials:** admin / optivolt2025

Le dashboard affiche :
- CPU usage en temps réel (4 plateformes)
- Memory usage en temps réel
- Network I/O (RX/TX)
- Comparaisons visuelles (bargauges)
- Valeurs actuelles (stat panels)

## 🧪 Tests de Charge

### Test rapide (10 secondes)

```bash
./scripts/benchmarks/benchmark_webapi.sh quick
```

Output :
```
  standard: Requests per second: 1234.56 [#/sec] (mean)
  microvm: Requests per second: 1100.23 [#/sec] (mean)
  minimal: Requests per second: 1050.45 [#/sec] (mean)
  unikernel: NOT AVAILABLE (ou résultats si déployé)
```

### Test complet (60 secondes par endpoint)

```bash
./scripts/benchmarks/benchmark_webapi.sh full
```

Cette commande :
1. Installe les dépendances (Apache Bench, hey)
2. Lance des tests de charge sur tous les endpoints
3. Collecte les métriques depuis Prometheus
4. Génère un rapport complet dans `results/webapi_benchmark_YYYYMMDD_HHMMSS/`

### Test de stress (haute charge, 30 secondes)

```bash
./scripts/benchmarks/benchmark_webapi.sh stress
```

Configuration :
- 200 utilisateurs concurrents
- 500 requêtes/seconde
- Durée : 30 secondes

## 🔍 Endpoints API Disponibles

| Endpoint | Description | Latence | Charge |
|----------|-------------|---------|--------|
| `/` | Root endpoint | < 10ms | Légère |
| `/api/light` | Requête légère | < 20ms | Légère |
| `/api/heavy` | Payload lourd | 50-100ms | Lourde |
| `/api/slow` | Simulation latence | 1-2s | Moyenne |
| `/docs` | Swagger UI | - | - |
| `/redoc` | ReDoc | - | - |

## 📈 Résultats Attendus

### CPU Usage (moyenne sous charge)

| Plateforme | CPU % | Optimisation vs Standard |
|------------|-------|--------------------------|
| Standard | ~40% | baseline |
| MicroVM | ~25% | -37% |
| Minimal | ~20% | -50% |
| Unikernel | ~3% | -92% |

### Memory Usage (moyenne)

| Plateforme | Memory (MB) | Optimisation vs Standard |
|------------|-------------|--------------------------|
| Standard | ~250 MB | baseline |
| MicroVM | ~120 MB | -52% |
| Minimal | ~60 MB | -76% |
| Unikernel | ~15 MB | -94% |

### Response Time (moyenne)

| Endpoint | Standard | MicroVM | Minimal | Unikernel |
|----------|----------|---------|---------|-----------|
| `/` | 5ms | 7ms | 8ms | 3ms |
| `/api/light` | 12ms | 15ms | 18ms | 8ms |
| `/api/heavy` | 85ms | 95ms | 105ms | 45ms |

## 🛠️ Commandes Utiles

### Construction manuelle

```bash
cd web_api

# Build image standard
docker build --target standard -t optivolt-webapi-standard:latest .

# Build image microvm
docker build --target microvm -t optivolt-webapi-microvm:latest .

# Build image minimal
docker build --target minimal -t optivolt-webapi-minimal:latest .
```

### Lancement manuel

```bash
# Standard
docker run -d --name optivolt-webapi-standard \
  -p 8001:8000 --memory="512m" --cpus="2.0" \
  optivolt-webapi-standard:latest

# MicroVM
docker run -d --name optivolt-webapi-microvm \
  -p 8002:8000 --memory="256m" --cpus="1.0" \
  optivolt-webapi-microvm:latest

# Minimal
docker run -d --name optivolt-webapi-minimal \
  -p 8003:8000 --memory="128m" --cpus="0.5" \
  optivolt-webapi-minimal:latest
```

### Build Unikraft (manuel)

```bash
cd web_api

# Build
kraft build --no-cache

# Run
kraft run --name optivolt-webapi-unikernel \
  --port 8004:8000 --memory 64M .
```

### Arrêt et nettoyage

```bash
# Tout arrêter
./scripts/deployment/deploy_webapi_all.sh stop

# Vérifier
docker ps -a | grep optivolt-webapi
kraft ps
```

## 🔧 Dépannage

### Les conteneurs ne démarrent pas

```bash
# Vérifier les logs
docker logs optivolt-webapi-standard
docker logs optivolt-webapi-microvm
docker logs optivolt-webapi-minimal

# Vérifier les ports
sudo netstat -tlnp | grep -E '8001|8002|8003|8004'

# Nettoyer et redémarrer
./scripts/deployment/deploy_webapi_all.sh stop
docker system prune -f
./scripts/deployment/deploy_webapi_all.sh deploy
```

### Dashboard Grafana vide

```bash
# Vérifier que Prometheus récupère les métriques
curl http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total

# Vérifier cAdvisor
curl http://localhost:8081/metrics | grep optivolt-webapi

# Re-créer le dashboard
./scripts/dashboards/create-webapi-dashboard.sh
```

### Kraft ne fonctionne pas

```bash
# Installer Kraft
curl --proto '=https' --tlsv1.2 -sSf https://get.kraftkit.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# Vérifier
kraft --version

# Si l'unikernel échoue, continuer sans
# Les 3 variantes Docker suffisent pour les tests
```

## 📁 Structure des Fichiers

```
web_api/
├── Dockerfile              # Multi-stage avec 3 variantes
├── Kraftfile              # Configuration Unikraft
├── .dockerignore          # Optimisation build
├── pyproject.toml         # Dépendances Python
└── app/
    ├── main.py           # FastAPI application
    └── routes/           # API endpoints

scripts/
├── deployment/
│   └── deploy_webapi_all.sh    # Script de déploiement
├── benchmarks/
│   └── benchmark_webapi.sh     # Tests de charge
└── dashboards/
    └── create-webapi-dashboard.sh  # Dashboard Grafana
```

## 🎓 Prochaines Étapes

1. **Analyser les résultats** dans Grafana
2. **Comparer les performances** entre plateformes
3. **Ajuster les paramètres** (memory, CPUs) pour optimiser
4. **Tester différentes charges** avec benchmark_webapi.sh
5. **Documenter les observations** pour le rapport final

## 📚 Ressources

- **API Docs:** http://localhost:8001/docs
- **Grafana:** http://localhost:3000/d/optivolt-webapi
- **Prometheus:** http://localhost:9090
- **cAdvisor:** http://localhost:8081

---

**Temps total estimé:** 5-10 minutes pour setup complet + tests
