# 🌐 Guide Accès Grafana dans GitHub Codespaces

## ✅ Grafana est Configuré et Actif !

Vos dashboards OptiVolt sont prêts avec 6 containers actifs générant des métriques en temps réel.

---

## 🚀 3 Méthodes pour Accéder à Grafana

### Méthode 1 : Port Forwarding VS Code (⭐ Plus Simple)

1. **Ouvrir l'onglet PORTS**
   - En bas de VS Code, cliquer sur l'onglet `PORTS`
   - Vous verrez une liste de ports forwarded

2. **Localiser le port 3000 (Grafana)**
   ```
   Port    Running Process         Visibility
   3000    grafana                 Private
   9090    prometheus              Private
   ```

3. **Cliquer sur l'icône 🌐**
   - À droite de la ligne "3000"
   - Cliquer sur l'icône de globe
   - Une nouvelle fenêtre s'ouvre avec Grafana

4. **Alternative : Copier l'URL**
   - Clic droit sur le port 3000 → "Copy Local Address"
   - L'URL ressemble à : `https://zany-telegram-xqvvj647whqr4-3000.app.github.dev`

---

### Méthode 2 : Rendre le Port Public

Si le port n'est pas accessible :

1. **Dans l'onglet PORTS**
2. **Clic droit sur port 3000**
3. **Sélectionner "Port Visibility" → Public**
4. **Copier l'URL** et ouvrir dans le navigateur

---

### Méthode 3 : Ligne de Commande

```bash
# Afficher l'URL du port 3000
gh codespace ports --codespace $CODESPACE_NAME 2>/dev/null | grep 3000

# Alternative : obtenir l'URL directement
echo "URL Grafana: https://${CODESPACE_NAME}-3000.app.github.dev"
```

---

## 🔐 Connexion à Grafana

Une fois l'URL ouverte :

```
Username: admin
Password: optivolt2025
```

⚠️ **Important** : Le mot de passe par défaut a été changé pour des raisons de sécurité.  
**NE PAS utiliser** `admin/admin` (ne fonctionnera pas).

**Si Grafana demande de changer le mot de passe** :
- ⏭️ Cliquer **"Skip"** pour garder `optivolt2025`
- ✅ Ou changer vers un nouveau mot de passe sécurisé

---

## 📊 Navigation dans Grafana

### 1. Accéder aux Dashboards

**Après le login:**

1. **Menu hamburger** (☰) en haut à gauche
2. Cliquer sur **"Dashboards"**
3. Cliquer sur **"Browse"**
4. Vous verrez :
   ```
   📊 OptiVolt - Docker vs MicroVM vs Unikernel
   📊 OptiVolt - System Metrics
   📊 Power Consumption - OptiVolt Comparison (ancien)
   ```

### 2. Ouvrir le Dashboard Principal

✅ **Dashboards disponibles** (vérifiés et actifs) :

| Dashboard | UID | Status |
|-----------|-----|--------|
| **OptiVolt - Docker vs MicroVM vs Unikernel** | `e83063fd-4599-4366-beff-b1b2531fd79e` | ✅ Actif |
| **OptiVolt - System Metrics** | `e3749ecb-7918-45e5-9d10-9678de399665` | ✅ Actif |

**Pour ouvrir un dashboard** :

1. Cliquer sur **"OptiVolt - Docker vs MicroVM vs Unikernel"**
2. Vous verrez :
   - 📈 Graphique CPU en temps réel (3 environnements)
   - 💾 Graphique Mémoire en temps réel
   - 📊 Statistiques actuelles par container
   - 📋 Tableau récapitulatif

**⚠️ Si le dashboard est vide** : C'est normal si aucun benchmark n'a été lancé !  
→ Lancer : `bash scripts/run_real_benchmark.sh 60` puis rafraîchir Grafana.

---

## 🎨 Que Voir dans les Dashboards

### Panel 1 : CPU Usage Comparison
- **Ligne Docker** : Utilisation CPU container standard
- **Ligne MicroVM** : Utilisation CPU container optimisé
- **Ligne Unikernel** : Utilisation CPU container minimal
- **Refresh** : Automatique toutes les 10 secondes

### Panel 2 : Memory Usage
- Consommation mémoire en temps réel
- Comparaison des 3 environnements
- Détection anomalies/fuites mémoire

### Panel 3-4-5 : Stats Individuelles
- **Docker** : Stats en temps réel avec gauge coloré
- **MicroVM** : Stats optimisées
- **Unikernel** : Stats minimales

### Panel 6 : Tableau Récapitulatif
- Vue d'ensemble de tous les containers
- Métriques instantanées
- Export possible en CSV

---

## 🔍 Explorer les Métriques Prometheus

### Accès à Prometheus Explorer

1. **Menu** (☰) → **Explore**
2. **Datasource** : Sélectionner "Prometheus"
3. **Essayer ces requêtes** :

#### Requête 1 : CPU par container
```promql
rate(container_cpu_usage_seconds_total{name=~"optivolt.*"}[1m]) * 100
```

#### Requête 2 : Mémoire par container
```promql
container_memory_usage_bytes{name=~"optivolt.*"} / 1024 / 1024
```

#### Requête 3 : Comparaison CPU moyenne
```promql
avg by (name) (rate(container_cpu_usage_seconds_total{name=~"optivolt.*"}[5m])) * 100
```

#### Requête 4 : Top containers par CPU
```promql
topk(5, rate(container_cpu_usage_seconds_total[1m]) * 100)
```

---

## 🚀 Lancer un Benchmark pour Voir les Métriques

Si vous ne voyez pas de données dans les dashboards :

```bash
# Lancer un benchmark de 60 secondes
cd /workspaces/Optivolt-automation
bash scripts/run_real_benchmark.sh 60
```

**Pendant l'exécution** (60 secondes) :
1. Retourner sur Grafana
2. Actualiser le dashboard
3. Observer les métriques en temps réel !

---

## 📈 Visualisation en Temps Réel

### Activer l'Auto-Refresh

Dans le dashboard :
1. **Coin supérieur droit** : Trouver l'icône d'horloge
2. Cliquer et sélectionner :
   - `5s` - Très rapide
   - `10s` - Recommandé ✅
   - `30s` - Économie ressources
3. Le dashboard se rafraîchit automatiquement

### Ajuster la Plage de Temps

En haut à droite :
- **Last 5 minutes** : Données récentes
- **Last 15 minutes** : Vue d'ensemble
- **Last 1 hour** : Tendances
- **Custom** : Plage personnalisée

---

## 🛠️ Personnaliser les Dashboards

### Modifier un Panel

1. **Cliquer sur le titre** du panel
2. Sélectionner **"Edit"**
3. Modifier :
   - Requête Prometheus
   - Type de visualisation
   - Couleurs et seuils
   - Légendes
4. **Apply** pour sauvegarder

### Ajouter un Nouveau Panel

1. **En haut du dashboard** : Cliquer sur l'icône **"+"**
2. Sélectionner **"Add visualization"**
3. Choisir **"Prometheus"** comme datasource
4. Entrer votre requête PromQL
5. Personnaliser l'affichage
6. **Apply**

---

## 📊 Dashboards Disponibles

### 1. OptiVolt - Docker vs MicroVM vs Unikernel
**Contenu :**
- Comparaison CPU/Mémoire temps réel
- Stats individuelles par environnement
- Tableau récapitulatif

**Utilisation :** Benchmark et comparaison performance

### 2. OptiVolt - System Metrics
**Contenu :**
- CPU/Mémoire du système hôte
- Nombre de containers actifs
- Métriques Node Exporter

**Utilisation :** Monitoring système global

### 3. Power Consumption (ancien)
**Contenu :**
- Tentative métriques énergétiques
- Scaphandre (limité dans Codespaces)

**Utilisation :** Référence énergétique

---

## 🎯 Scénarios d'Utilisation

### Scénario 1 : Voir les Résultats d'un Benchmark

```bash
# 1. Lancer le benchmark
bash scripts/run_real_benchmark.sh 60

# 2. Pendant l'exécution, ouvrir Grafana
# (Utiliser l'URL du port 3000)

# 3. Dashboard → OptiVolt Comparison
# Observer les métriques en temps réel !
```

### Scénario 2 : Comparer les Environnements

1. Lancer plusieurs benchmarks successifs
2. Dans Grafana : Ajuster **Time Range** à "Last 30 minutes"
3. Observer l'évolution comparative
4. Utiliser **Table Panel** pour résumé

### Scénario 3 : Export des Données

1. Ouvrir le dashboard
2. **Menu panel** (⋮) → **Inspect** → **Data**
3. **Download CSV** pour exporter
4. Analyser dans Excel/Python

---

## 🐛 Dépannage

### Problème : "Dashboard is empty"

**Solution :**
```bash
# Vérifier que les containers tournent
docker ps | grep optivolt

# Relancer un benchmark
bash scripts/run_real_benchmark.sh 30
```

### Problème : "No data points"

**Causes possibles :**
1. Time Range trop ancien (ajuster à "Last 5 minutes")
2. Aucun container actif
3. Prometheus non connecté

**Solution :**
```bash
# Vérifier Prometheus
curl http://localhost:9090/-/healthy

# Vérifier les métriques
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq
```

### Problème : "Invalid username or password"

**Solutions :**
1. Utiliser : `admin` / `admin`
2. Si changé : Réinitialiser Grafana
   ```bash
   docker restart optivolt-grafana
   ```

### Problème : Port 3000 non accessible

**Solution :**
```bash
# Vérifier Grafana
docker logs optivolt-grafana | tail -20

# Redémarrer si nécessaire
docker restart optivolt-grafana

# Attendre 10 secondes et réessayer
```

---

## 📱 Accès depuis Mobile/Tablette

L'URL forwarded fonctionne aussi sur mobile !

1. Copier l'URL du port 3000
2. Envoyer par email/Slack
3. Ouvrir sur mobile
4. Login admin/optivolt2025
5. Dashboards optimisés responsive

---

## 🎓 Ressources Supplémentaires

### Documentation Grafana
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)
- [Prometheus Queries](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### Commandes Utiles

```bash
# Vérifier tous les services
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Logs Grafana
docker logs optivolt-grafana -f

# Logs Prometheus
docker logs optivolt-prometheus -f

# Relancer monitoring
docker-compose -f docker-compose-monitoring.yml restart
```

---

## ✅ Checklist d'Accès

- [ ] Ouvrir VS Code → Onglet PORTS
- [ ] Localiser port 3000
- [ ] Cliquer sur l'icône 🌐 ou copier l'URL
- [ ] Login : admin / admin
- [ ] Menu → Dashboards → Browse
- [ ] Ouvrir "OptiVolt - Docker vs MicroVM vs Unikernel"
- [ ] Lancer un benchmark pour voir les données
- [ ] Profiter des visualisations temps réel ! 🎉

---

## 🎉 Résultat Final

Vous devriez maintenant voir :
- ✅ Graphiques CPU animés en temps réel
- ✅ Graphiques Mémoire par environnement
- ✅ Stats colorées (vert/jaune/rouge)
- ✅ Tableaux récapitulatifs
- ✅ Métriques actualisées automatiquement

**Si rien ne s'affiche** : Lancer `bash scripts/run_real_benchmark.sh 60` et observer !

---

**Besoin d'aide ?**  
📖 Voir : `GUIDE_TESTS_REELS.md`  
🔧 Script : `scripts/setup_grafana_dashboards.sh`  
🚀 Benchmark : `scripts/run_real_benchmark.sh`
