# Guide d'intégration de l'API FastAPI avec OptiVolt

## Vue d'ensemble

L'API FastAPI est maintenant intégrée dans OptiVolt pour tester les performances réelles d'une application web sur Docker vs Unikernel.

## Architecture

```
greenapps/apps/web_api/
├── app/
│   ├── main.py              # Application FastAPI
│   ├── routes/
│   │   └── simulation_routes.py  # Endpoints de simulation
│   └── helpers.py
├── Dockerfile               # Build de l'API
├── docker-compose.yml       # Déploiement simplifié
└── pyproject.toml          # Dépendances Python
```

## Déploiement rapide

### Option 1: Script automatisé (recommandé)

```bash
# Déployer l'API dans Docker
./scripts/deploy_web_api.sh

# L'API sera accessible sur http://localhost:8000
```

### Option 2: Docker Compose

```bash
cd greenapps/apps/web_api
docker-compose up -d
```

### Option 3: Manuel avec Docker

```bash
cd greenapps/apps/web_api
docker build -t optivolt-web-api .
docker run -d -p 8000:8000 --name optivolt-web-api optivolt-web-api
```

## Endpoints disponibles

### GET Endpoints

```bash
# Requête légère
curl http://localhost:8000/simulate/normal

# Réponse lourde (500KB par défaut)
curl http://localhost:8000/simulate/heavy?size_kb=500

# Avec délai
curl http://localhost:8000/simulate/delay?ms=500
```

### POST Endpoints

```bash
# Envoi de données normales
curl -X POST http://localhost:8000/simulate/normal \
  -H "Content-Type: application/json" \
  -d '{"content":"Test data"}'

# Traitement lourd
curl -X POST http://localhost:8000/simulate/heavy \
  -H "Content-Type: application/json" \
  -d '{"size_kb":100}'

# POST avec délai
curl -X POST http://localhost:8000/simulate/delay \
  -H "Content-Type: application/json" \
  -d '{"ms":500, "content":"Data"}'
```

## Tests de performance avec OptiVolt

### Test automatique via OptiVoltCLI

```bash
cd publish

# Déployer l'API
./scripts/deploy_web_api.sh

# Tester l'API pendant 30 secondes
dotnet OptiVoltCLI.dll test --environment docker --type api --duration 30

# Les résultats seront sauvegardés dans test_api_docker.json
```

### Test manuel du script

```bash
# Tester directement avec le script amélioré
./scripts/run_test_api.sh 30 localhost:8000
```

## Métriques collectées

Le script `run_test_api.sh` collecte :

- **Total requests**: Nombre total de requêtes envoyées
- **Successful requests**: Requêtes réussies (HTTP 2xx)
- **Failed requests**: Requêtes échouées
- **Success rate**: Taux de succès en pourcentage
- **Average response time**: Temps de réponse moyen en ms
- **Requests per second**: Débit (req/s)
- **Total response time**: Temps cumulé

## Comparaison Docker vs Unikernel

### Étape 1: Tester sur Docker

```bash
# Déployer l'API sur Docker
./scripts/deploy_web_api.sh

# Tester pendant 60 secondes
dotnet OptiVoltCLI.dll test --environment docker --type api --duration 60
```

### Étape 2: Tester sur Unikernel

```bash
# Déployer l'API sur Unikernel (à implémenter)
./scripts/deploy_unikernel_api.sh

# Tester pendant 60 secondes
dotnet OptiVoltCLI.dll test --environment unikernel --type api --duration 60
```

### Étape 3: Comparer les résultats

```bash
# Générer le rapport de comparaison
python3 scripts/compare_environments.py results/ comparison_api.html

# Ouvrir le rapport dans un navigateur
firefox comparison_api.html
```

## Documentation interactive

Une fois l'API déployée, accédez à la documentation Swagger :

```
http://localhost:8000/docs
```

## Monitoring en temps réel

Visualisez les métriques dans Grafana :

```bash
# Démarrer le stack de monitoring
./start-monitoring.sh

# Accéder à Grafana
# URL: http://localhost:3000
# Login: admin / optivolt2025
```

## Troubleshooting

### L'API ne démarre pas

```bash
# Vérifier les logs
docker logs optivolt-web-api

# Reconstruire l'image
cd greenapps/apps/web_api
docker build --no-cache -t optivolt-web-api .
```

### Port 8000 déjà utilisé

```bash
# Trouver quel processus utilise le port
sudo lsof -i :8000

# Changer le port dans le script
# Modifier API_PORT dans deploy_web_api.sh
```

### Tests échouent

```bash
# Vérifier que l'API répond
curl http://localhost:8000/

# Vérifier la connectivité réseau
docker network ls
docker network inspect optivolt-network
```

## Améliorations futures

- [ ] Support Unikernel pour l'API
- [ ] Tests de charge avec Apache Bench (ab)
- [ ] Intégration avec Locust pour tests distribués
- [ ] Métriques détaillées par endpoint
- [ ] Graphiques de latence (p50, p95, p99)
- [ ] Tests de résilience (chaos engineering)

## Références

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [OptiVolt Main README](../README.md)
