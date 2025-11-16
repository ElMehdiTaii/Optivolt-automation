# 🌐 Intégration API FastAPI avec OptiVolt

## 📖 Vue d'ensemble

L'API FastAPI est intégrée au système de benchmarking OptiVolt pour mesurer les performances applicatives réelles entre Docker, MicroVM et Unikernel.

**🎯 Objectif :** Comparer les performances d'une API REST sur différents environnements de virtualisation.

---

## 🏗️ Architecture

```
scripts/
├── deploy_fastapi.sh       # Déploiement API dans Docker
├── deploy_web_api.sh        # Alternative de déploiement
├── benchmark_api.sh         # Script de benchmark API
└── run_test_api.sh          # Tests OptiVoltCLI

OptiVoltCLI/
└── Commands/
    └── TestCommand.cs       # Intégration tests API
```

---

## 🚀 Endpoints Disponibles

### GET Endpoints

| Endpoint | Description | Paramètres |
|----------|-------------|------------|
| `GET /` | Message de bienvenue | - |
| `GET /simulate/normal` | Réponse GET standard | - |
| `GET /simulate/heavy` | Réponse avec payload lourd | `size_kb=500` |
| `GET /simulate/delay` | Réponse avec délai artificiel | `ms=500` |

### POST Endpoints

| Endpoint | Description | Body |
|----------|-------------|------|
| `POST /simulate/normal` | POST standard | `{"content": "data"}` |
| `POST /simulate/heavy` | POST avec charge | `{"size_kb": 100}` |
| `POST /simulate/delay` | POST avec délai | `{"ms": 500, "content": "data"}` |

---

## 💻 Utilisation

### 1. Déploiement de l'API

```bash
# Déployer l'API dans Docker
cd /workspaces/Optivolt-automation
bash scripts/deploy_fastapi.sh
```

**Résultat :**
- Container `optivolt-fastapi` créé
- API accessible sur `http://localhost:8000`
- Documentation Swagger : `http://localhost:8000/docs`

### 2. Test Manuel de l'API

```bash
# Requête GET simple
curl http://localhost:8000/simulate/normal

# Requête GET lourde (500 KB)
curl http://localhost:8000/simulate/heavy?size_kb=500

# Requête GET avec délai (500ms)
curl http://localhost:8000/simulate/delay?ms=500

# Requête POST
curl -X POST http://localhost:8000/simulate/normal \
  -H "Content-Type: application/json" \
  -d '{"content":"Test data"}'
```

### 3. Benchmark avec Script

```bash
# Benchmark de 60 secondes
bash scripts/benchmark_api.sh 60 http://localhost:8000

# Benchmark avec plus de requêtes
bash scripts/benchmark_api.sh 120 http://localhost:8000
```

**Métriques collectées :**
- 📊 Nombre total de requêtes
- ⚡ Requêtes/seconde (throughput)
- ⏱️ Latence moyenne/min/max (ms)
- ✅ Taux de succès (%)
- 📈 Détail par endpoint

### 4. Test via OptiVoltCLI

```bash
cd /workspaces/Optivolt-automation/publish

# Test API Docker (30 secondes)
./OptiVoltCLI test --environment docker --type api --duration 30

# Test API MicroVM
./OptiVoltCLI test --environment microvm --type api --duration 30

# Test API Unikernel
./OptiVoltCLI test --environment unikernel --type api --duration 30
```

---

## 📊 Résultats de Benchmark

### Format JSON

```json
{
  "environment": "docker",
  "test_type": "api",
  "duration_seconds": 60,
  "metrics": {
    "total_requests": 15420,
    "requests_per_second": 257,
    "latency_ms": {
      "avg": 38.5,
      "min": 12.1,
      "max": 156.3
    },
    "success_rate": 99.8,
    "endpoint_breakdown": {
      "GET /simulate/normal": 5140,
      "GET /simulate/heavy": 5140,
      "POST /simulate/normal": 5140
    }
  }
}
```

### Exemple de Résultats Comparatifs

| Environment | Req/s | Latence Moy. | Success Rate |
|-------------|-------|--------------|--------------|
| Docker      | 257   | 38.5 ms      | 99.8%        |
| MicroVM     | 312   | 31.2 ms      | 99.9%        |
| Unikernel   | 289   | 34.1 ms      | 99.7%        |

---

## 🔧 Configuration Avancée

### Personnaliser les Tests

Éditer `scripts/benchmark_api.sh` :

```bash
# Modifier le nombre de workers
WORKERS=10

# Ajuster les endpoints testés
ENDPOINTS=(
  "/simulate/normal"
  "/simulate/heavy?size_kb=1000"
  "/simulate/delay?ms=100"
)

# Changer la distribution des requêtes
GET_RATIO=0.7
POST_RATIO=0.3
```

### Ajouter des Endpoints

Créer une nouvelle API FastAPI :

```python
# app/routes/custom_routes.py
from fastapi import APIRouter

router = APIRouter()

@router.get("/custom/endpoint")
async def custom_endpoint():
    return {"message": "Custom response"}
```

---

## 🐛 Dépannage

### Problème : API ne répond pas

```bash
# Vérifier le container
docker ps | grep fastapi

# Voir les logs
docker logs optivolt-fastapi -f

# Redémarrer
docker restart optivolt-fastapi
```

### Problème : Port 8000 déjà utilisé

```bash
# Trouver le processus
lsof -i :8000

# Arrêter l'ancien container
docker stop optivolt-fastapi
docker rm optivolt-fastapi

# Relancer
bash scripts/deploy_fastapi.sh
```

### Problème : Erreurs de connexion

```bash
# Tester la connectivité
curl -v http://localhost:8000/

# Vérifier les règles réseau
docker network inspect bridge
```

---

## 📚 Ressources

### Documentation

- [FastAPI Official Docs](https://fastapi.tiangolo.com/)
- [OptiVolt README](../README.md)
- [Guide Tests Réels](../GUIDE_TESTS_REELS.md)

### Scripts Associés

- `scripts/deploy_fastapi.sh` - Déploiement
- `scripts/benchmark_api.sh` - Benchmarking
- `scripts/run_test_api.sh` - Tests intégrés

---

**✅ API Integration Ready!**

L'API FastAPI est maintenant intégrée et prête pour les benchmarks comparatifs.

**Prochaine étape :** Exécuter `bash scripts/run_real_benchmark.sh 60` pour comparer tous les environnements.


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
