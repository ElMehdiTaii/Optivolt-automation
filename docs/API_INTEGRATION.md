# Intégration API FastAPI avec OptiVolt

## Vue d'ensemble

L'API FastAPI (`greenapps/apps/web_api`) est maintenant intégrée au système de benchmarking OptiVolt pour mesurer les performances entre Docker et Unikernel.

## Architecture

```
greenapps/apps/web_api/
├── app/
│   ├── app.py              # Application FastAPI principale
│   ├── routes/
│   │   └── simulation_routes.py  # Endpoints de simulation
│   └── helpers.py          # Fonctions utilitaires
├── Dockerfile              # Image Docker de l'API ✨ NOUVEAU
└── pyproject.toml          # Dépendances Python

scripts/
├── deploy_fastapi.sh       # Déploiement de l'API dans Docker ✨ NOUVEAU
├── benchmark_api.sh        # Script de benchmark complet ✨ NOUVEAU
└── run_test_api.sh         # Intégration avec OptiVoltCLI (modifié)
```

## Endpoints disponibles

### GET Endpoints
- `GET /` - Message de bienvenue
- `GET /simulate/normal` - Réponse GET normale
- `GET /simulate/heavy?size_kb=500` - Réponse avec payload lourd
- `GET /simulate/delay?ms=500` - Réponse avec délai simulé

### POST Endpoints
- `POST /simulate/normal` - POST avec payload simple
  ```json
  {"content": "test data"}
  ```
- `POST /simulate/heavy` - POST avec payload lourd
  ```json
  {"size_kb": 100}
  ```
- `POST /simulate/delay` - POST avec délai simulé
  ```json
  {"content": "test", "ms": 500}
  ```

## Utilisation

### 1. Déploiement manuel de l'API

```bash
# Déployer l'API dans Docker
./scripts/deploy_fastapi.sh
```

L'API sera accessible sur `http://localhost:8000`

Documentation interactive : `http://localhost:8000/docs`

### 2. Test manuel avec le script de benchmark

```bash
# Benchmark de 60 secondes
./scripts/benchmark_api.sh 60 http://localhost:8000
```

**Métriques collectées :**
- Nombre total de requêtes
- Requêtes/seconde (throughput)
- Latence moyenne/min/max
- Taux de succès
- Détail par endpoint

### 3. Test via OptiVoltCLI (intégration complète)

```bash
# Compiler OptiVoltCLI
cd OptiVoltCLI
dotnet build -c Release -o ../publish
cd ..

# Déployer et tester l'API sur Docker
cd publish
dotnet OptiVoltCLI.dll test --environment docker --type api --duration 60

# Les résultats seront dans test_api_docker.json
```

### 4. Comparaison Docker vs Unikernel (TODO)

Pour comparer les performances entre Docker et Unikernel :

```bash
# 1. Test Docker
dotnet OptiVoltCLI.dll test --environment docker --type api --duration 60

# 2. Test Unikernel (nécessite configuration)
dotnet OptiVoltCLI.dll test --environment unikernel --type api --duration 60

# 3. Générer le rapport de comparaison
python3 scripts/compare_environments.py results/ comparison.html
```

## Métriques mesurées

Le benchmark teste **6 endpoints** en boucle pendant la durée spécifiée :

1. `GET /simulate/normal` - Requête légère
2. `GET /simulate/heavy?size_kb=100` - Charge lourde
3. `GET /simulate/delay?ms=50` - Avec latence
4. `POST /simulate/normal` - POST simple
5. `POST /simulate/heavy` - POST lourd (50KB)
6. `POST /simulate/delay` - POST avec délai

### Résultats typiques

```
Résultats du Benchmark
======================
Durée: 30s

📊 Statistiques globales:
  • Total requêtes: 2450
  • Requêtes/seconde: 81
  • Taux de succès: 100%
  • Requêtes échouées: 0

⏱️  Latence:
  • Moyenne: 73ms
  • Minimum: 15ms
  • Maximum: 245ms

🔷 Détail par endpoint:
  GET /simulate/normal: 408 requêtes
  GET /simulate/heavy:  408 requêtes
  GET /simulate/delay:  408 requêtes
  POST /simulate/normal: 408 requêtes
  POST /simulate/heavy:  408 requêtes
  POST /simulate/delay:  410 requêtes
```

## Monitoring avec Grafana

Pour visualiser les métriques en temps réel :

```bash
# Démarrer la stack de monitoring
./start-monitoring.sh

# Accéder à Grafana
open http://localhost:3000
# Login: admin / optivolt2025
```

Les métriques Docker de l'API seront disponibles dans le dashboard OptiVolt.

## Commandes utiles

```bash
# Voir les logs de l'API
docker logs -f optivolt-fastapi

# Voir les stats en temps réel
docker stats optivolt-fastapi

# Arrêter l'API
docker stop optivolt-fastapi

# Tester un endpoint manuellement
curl http://localhost:8000/simulate/normal
curl -X POST http://localhost:8000/simulate/heavy \
  -H "Content-Type: application/json" \
  -d '{"size_kb": 100}'
```

## Troubleshooting

### L'API ne démarre pas

```bash
# Vérifier les logs Docker
docker logs optivolt-fastapi

# Vérifier que le port 8000 est libre
sudo netstat -tulpn | grep 8000

# Reconstruire l'image
cd greenapps/apps/web_api
docker build -t optivolt/fastapi:latest .
```

### Le benchmark échoue

```bash
# Vérifier que l'API répond
curl http://localhost:8000/

# Tester un endpoint manuellement
curl http://localhost:8000/simulate/normal
```

### Dépendance manquante (greenux_shared_module)

Si vous voyez des erreurs liées à `greenux_shared_module`, assurez-vous que le module est dans le PYTHONPATH ou installez-le :

```bash
cd greenapps/apps/shared_module
pip install -e .
```

## Prochaines étapes

- [ ] Déployer l'API sur Unikernel (OSv/MirageOS)
- [ ] Comparer les métriques Docker vs Unikernel
- [ ] Ajouter des tests de charge plus intensifs
- [ ] Intégrer les métriques énergétiques (Scaphandre)
- [ ] Créer un dashboard Grafana dédié à l'API

## Contribution

Pour ajouter de nouveaux endpoints ou types de tests :

1. Modifier `greenapps/apps/web_api/app/routes/simulation_routes.py`
2. Mettre à jour `scripts/benchmark_api.sh` pour tester les nouveaux endpoints
3. Rebuild l'image Docker : `./scripts/deploy_fastapi.sh`

---

**Documentation OptiVolt** | Version 1.0 | Novembre 2025
