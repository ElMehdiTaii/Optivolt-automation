# 📊 Intégration Grafana pour OptiVolt

## 🎯 Vue d'Ensemble

Ce guide explique comment visualiser les métriques de performance OptiVolt avec **Grafana + Prometheus + cAdvisor**.

**🔍 Stack de Monitoring :**

```
┌──────────────────────────────────────────────────┐
│           OptiVolt Monitoring Stack              │
├──────────────────────────────────────────────────┤
│                                                  │
│  Containers Docker    ──┐                       │
│  cAdvisor (8081)      ──┤                       │
│  Node Exporter (9100) ──┤                       │
│                         │                        │
│                         ├──→ Prometheus (9090)   │
│                         │    • Collecte          │
│                         │    • Stockage          │
│                         │                        │
│                         └──→ Grafana (3000)      │
│                              • Dashboards        │
│                              • Alertes           │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## 🚀 Démarrage Rapide

### 1. Lancer la Stack Monitoring

```bash
cd /workspaces/Optivolt-automation
bash start-monitoring.sh

# Attendre 20 secondes
sleep 20

# Vérifier
docker ps | grep optivolt
```

**Containers lancés :**
- `optivolt-prometheus` (port 9090)
- `optivolt-grafana` (port 3000)
- `optivolt-cadvisor` (port 8081)
- `optivolt-node-exporter` (port 9100)

### 2. Accéder à Grafana

**Dans GitHub Codespaces :**
1. VS Code → Onglet **PORTS** (bas)
2. Port **3000** → Cliquer 🌐
3. Login : `admin` / `admin`

**En local :**
```
http://localhost:3000
```

### 3. Voir les Dashboards

Navigation : **Menu (☰) → Dashboards → Browse**

**Dashboards disponibles :**
- ✅ **OptiVolt - Docker vs MicroVM vs Unikernel** (principal)
- ✅ **OptiVolt - System Metrics**
- ℹ️ **Power Consumption** (ancien, optionnel)

📖 **Guide complet accès :** [../GRAFANA_CODESPACES_ACCESS.md](../GRAFANA_CODESPACES_ACCESS.md)

---

## 📊 Dashboards Disponibles

### 1. OptiVolt - Docker vs MicroVM vs Unikernel

**Panels inclus :**

#### 📈 CPU Usage Comparison (Time Series)
```promql
rate(container_cpu_usage_seconds_total{name=~"optivolt.*"}[1m]) * 100
```
- Comparaison CPU temps réel
- 3 courbes (Docker, MicroVM, Unikernel)
- Auto-refresh 10s

#### 💾 Memory Usage Comparison (Time Series)
```promql
container_memory_usage_bytes{name=~"optivolt.*"} / 1024 / 1024
```
- Utilisation mémoire en MB
- Détection fuites mémoire
- Tendances historiques

#### 📊 Stats Individuelles (Gauges)
- Docker : CPU% actuel + gauge coloré
- MicroVM : CPU% actuel + gauge coloré
- Unikernel : CPU% actuel + gauge coloré

#### 📋 Tableau Récapitulatif (Table)
- Vue d'ensemble tous containers
- CPU, Mémoire, Status
- Export CSV possible

### 2. OptiVolt - System Metrics

**Métriques système :**
- CPU hôte (%)
- RAM totale/utilisée (GB)
- Disk I/O (MB/s)
- Network I/O (MB/s)
- Nombre containers actifs

---

## 🔍 Requêtes Prometheus Utiles

### Accès à Prometheus

**Codespaces :** Port 9090 → 🌐  
**Local :** `http://localhost:9090`

### Top Requêtes PromQL

#### 1. CPU par Container
```promql
rate(container_cpu_usage_seconds_total{name=~"optivolt.*"}[1m]) * 100
```

#### 2. Mémoire par Container (MB)
```promql
container_memory_usage_bytes{name=~"optivolt.*"} / 1024 / 1024
```

#### 3. CPU Moyen sur 5 minutes
```promql
avg by (name) (rate(container_cpu_usage_seconds_total{name=~"optivolt.*"}[5m])) * 100
```

#### 4. Top 5 Containers CPU
```promql
topk(5, rate(container_cpu_usage_seconds_total[1m]) * 100)
```

#### 5. Mémoire Totale Utilisée
```promql
sum(container_memory_usage_bytes{name=~"optivolt.*"}) / 1024 / 1024 / 1024
```

#### 6. Network I/O
```promql
rate(container_network_receive_bytes_total{name=~"optivolt.*"}[1m]) / 1024
```

---

## 🛠️ Configuration des Dashboards

### Créer un Dashboard Personnalisé

1. **Menu** → **Dashboards** → **New** → **New Dashboard**
2. **Add visualization**
3. **Data source** : Prometheus
4. Entrer une requête PromQL
5. Personnaliser l'affichage (Graph, Stat, Table, etc.)
6. **Save dashboard**

### Modifier un Panel Existant

1. Ouvrir le dashboard
2. **Titre du panel** → **Edit**
3. Modifier :
   - Requête PromQL
   - Visualisation
   - Couleurs/Seuils
   - Légendes
4. **Apply**

### Importer un Dashboard

1. **Menu** → **Dashboards** → **Import**
2. Entrer l'ID du dashboard (ex: 14282 pour cAdvisor)
3. **Load**
4. Sélectionner **Prometheus** comme datasource
5. **Import**

**Dashboards Recommandés :**
- **893** - Docker Container & Host Metrics
- **14282** - cadvisor exporter
- **1860** - Node Exporter Full

---

## 🔧 Configuration Avancée

### Prometheus Configuration

Fichier : `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Grafana Datasource

```json
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "access": "proxy",
  "isDefault": true
}
```

### Auto-Setup des Dashboards

```bash
# Reconfigurer tous les dashboards
bash scripts/setup_grafana_dashboards.sh
```

Ce script :
- ✅ Vérifie Grafana actif
- ✅ Configure datasource Prometheus
- ✅ Crée les 2 dashboards OptiVolt
- ✅ Fournit instructions d'accès

---

## 📈 Alertes (Optionnel)

### Créer une Alerte

1. Ouvrir un panel
2. **Alert** → **Create alert rule**
3. Définir la condition :
   ```promql
   rate(container_cpu_usage_seconds_total[1m]) * 100 > 80
   ```
4. Configurer notification (email, Slack, etc.)
5. **Save**

### Alertes Recommandées

| Alerte | Condition | Seuil |
|--------|-----------|-------|
| CPU High | `cpu_usage > 80%` | 80% |
| Memory High | `memory > 90%` | 90% |
| Container Down | `up == 0` | 0 |
| Disk Full | `disk_usage > 85%` | 85% |

---

## 🐛 Dépannage

### Problème : Grafana ne démarre pas

```bash
# Voir les logs
docker logs optivolt-grafana -f

# Redémarrer
docker restart optivolt-grafana

# Recréer
docker-compose -f docker-compose-monitoring.yml down
bash start-monitoring.sh
```

### Problème : Pas de données dans les dashboards

```bash
# Vérifier Prometheus
curl http://localhost:9090/-/healthy

# Vérifier les targets Prometheus
curl http://localhost:9090/api/v1/targets | jq

# Relancer un benchmark
bash scripts/run_real_benchmark.sh 30
```

### Problème : Datasource Prometheus introuvable

```bash
# Reconfigurer via script
bash scripts/setup_grafana_dashboards.sh

# OU manuellement :
# Grafana → Configuration → Data Sources → Add Prometheus
# URL: http://prometheus:9090
```

### Problème : Dashboard vide après benchmark

**Solutions :**
1. Ajuster **Time Range** à "Last 5 minutes"
2. Activer **Auto-refresh** (10s ou 30s)
3. Vérifier que les containers `optivolt-*` tournent
4. Relancer un benchmark pour générer des données

---

## 📚 Ressources

### Documentation Officielle

- [Grafana Docs](https://grafana.com/docs/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [cAdvisor Docs](https://github.com/google/cadvisor)
- [Node Exporter Docs](https://github.com/prometheus/node_exporter)

### Guides OptiVolt

- [../README.md](../README.md) - Documentation principale
- [../GRAFANA_CODESPACES_ACCESS.md](../GRAFANA_CODESPACES_ACCESS.md) - Accès détaillé
- [../GUIDE_TESTS_REELS.md](../GUIDE_TESTS_REELS.md) - Benchmarks et tests

---

## ✅ Checklist

- [ ] Stack monitoring démarrée
- [ ] Grafana accessible (port 3000)
- [ ] Login admin/optivolt2025 réussi
- [ ] Datasource Prometheus configuré
- [ ] Dashboards OptiVolt visibles
- [ ] Benchmark exécuté (données générées)
- [ ] Métriques affichées dans dashboards
- [ ] Auto-refresh activé

---

**📊 Monitoring OptiVolt configuré avec succès !**

Vos métriques de performance sont maintenant visualisées en temps réel dans Grafana.

**Prochaine étape :** Exécuter `bash scripts/run_real_benchmark.sh 60` et observer les dashboards s'animer !

- Graphique en temps réel
- Mise à jour toutes les 10 secondes

#### **2. Power by Socket**
- Consommation par socket CPU
- Utile pour serveurs multi-socket
- Compare les sockets entre eux

#### **3. Top 10 Power Consuming Processes**
- Tableau des processus les plus énergivores
- Affiche PID, nom du process et consommation
- Identifie rapidement les applications gourmandes

#### **4. CPU Usage**
- Pourcentage d'utilisation CPU
- Corrélé avec la consommation électrique

#### **5. Memory Usage**
- Pourcentage d'utilisation mémoire
- Impact sur la consommation

#### **6. Energy Efficiency**
- Watts par % CPU
- Mesure l'efficacité énergétique
- Plus bas = plus efficace

---

## 🔧 Utilisation Avancée

### **Ajouter un Dashboard Personnalisé**

1. **Dans Grafana** :
   - Cliquez sur **"+"** → **Dashboard**
   - **Add visualization**
   - Sélectionnez **Prometheus** comme source

2. **Requêtes PromQL utiles** :

```promql
# Consommation totale en Watts
scaph_host_power_microwatts / 1000000

# Consommation par processus
topk(5, scaph_process_power_consumption_microwatts / 1000000)

# Énergie consommée (Joules) sur 5 minutes
increase(scaph_host_energy_microjoules[5m]) / 1000000

# CPU par cœur
100 - (avg by (cpu) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Containers Docker actifs
count(rate(container_cpu_usage_seconds_total[5m]))

# Efficacité énergétique
(scaph_host_power_microwatts / 1000000) / 
  (100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))
```

### **Métriques Scaphandre Disponibles**

```
scaph_host_power_microwatts          # Puissance totale de l'hôte
scaph_socket_power_microwatts        # Puissance par socket
scaph_process_power_consumption_microwatts  # Par processus
scaph_host_energy_microjoules        # Énergie totale consommée
scaph_self_mem_total_program_size    # Mémoire Scaphandre
```

### **Métriques Node Exporter**

```
node_cpu_seconds_total               # Temps CPU
node_memory_MemAvailable_bytes       # RAM disponible
node_disk_io_time_seconds_total      # I/O disque
node_network_receive_bytes_total     # Network RX
```

### **Métriques cAdvisor (Docker)**

```
container_cpu_usage_seconds_total    # CPU par container
container_memory_usage_bytes         # RAM par container
container_network_receive_bytes_total # Network par container
```

---

## 🎨 Créer un Dashboard Comparatif

Pour comparer Docker vs MicroVM vs Unikernel :

### **Dashboard : Environnements Comparison**

```json
{
  "panels": [
    {
      "title": "Power Consumption by Environment",
      "targets": [
        {
          "expr": "scaph_process_power_consumption_microwatts{cmdline=~\".*docker.*\"} / 1000000",
          "legendFormat": "Docker"
        },
        {
          "expr": "scaph_process_power_consumption_microwatts{cmdline=~\".*qemu.*microvm.*\"} / 1000000",
          "legendFormat": "MicroVM"
        },
        {
          "expr": "scaph_process_power_consumption_microwatts{cmdline=~\".*unikernel.*\"} / 1000000",
          "legendFormat": "Unikernel"
        }
      ]
    }
  ]
}
```

---

## 🔍 Monitoring en Production

### **Alertes Prometheus**

Créez `monitoring/prometheus/alerts/power.yml` :

```yaml
groups:
  - name: power_alerts
    interval: 30s
    rules:
      - alert: HighPowerConsumption
        expr: scaph_host_power_microwatts / 1000000 > 100
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High power consumption detected"
          description: "Host consuming {{ $value }}W for 5+ minutes"

      - alert: PowerSpike
        expr: rate(scaph_host_power_microwatts[1m]) > 10000000
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Sudden power spike detected"
          description: "Power increased rapidly"
```

### **Retention des Données**

Par défaut : **30 jours**

Pour modifier, éditez `docker-compose-monitoring.yml` :

```yaml
prometheus:
  command:
    - '--storage.tsdb.retention.time=90d'  # 90 jours
    - '--storage.tsdb.retention.size=50GB'  # ou 50GB max
```

---

## 🛠️ Commandes de Gestion

### **Démarrer la Stack**

```bash
./start-monitoring.sh
```

### **Arrêter la Stack**

```bash
docker-compose -f docker-compose-monitoring.yml down
```

### **Redémarrer un Service**

```bash
docker-compose -f docker-compose-monitoring.yml restart scaphandre
docker-compose -f docker-compose-monitoring.yml restart prometheus
docker-compose -f docker-compose-monitoring.yml restart grafana
```

### **Voir les Logs**

```bash
# Tous les services
docker-compose -f docker-compose-monitoring.yml logs -f

# Un service spécifique
docker-compose -f docker-compose-monitoring.yml logs -f scaphandre
docker-compose -f docker-compose-monitoring.yml logs -f grafana
```

### **Status des Conteneurs**

```bash
docker-compose -f docker-compose-monitoring.yml ps
```

### **Accéder à un Conteneur**

```bash
docker exec -it optivolt-grafana /bin/bash
docker exec -it optivolt-prometheus /bin/sh
```

---

## 📈 Export et Partage

### **Exporter un Dashboard**

1. Dans Grafana : **Dashboard → Settings (⚙️)**
2. **JSON Model** → Copier le JSON
3. Sauvegarder dans `monitoring/grafana/dashboards/`

### **Importer un Dashboard**

1. **Dashboards → New → Import**
2. Coller le JSON ou charger un fichier
3. Sélectionner la datasource **Prometheus**

### **Dashboards Communautaires**

Grafana propose des dashboards pré-faits :

- **Node Exporter Full** : ID `1860`
- **Docker Monitoring** : ID `193`
- **Scaphandre Dashboard** : [Lien](https://metrics.hubblo.org)

**Pour importer :**
1. **Dashboards → Import**
2. Entrer l'ID (ex: `1860`)
3. **Load** → Sélectionner Prometheus → **Import**

---

## 🐛 Troubleshooting

### **Scaphandre ne démarre pas**

```bash
# Vérifier les logs
docker logs optivolt-scaphandre

# Problème RAPL ?
ls -la /sys/class/powercap/
sudo modprobe intel_rapl_common

# Relancer
docker-compose -f docker-compose-monitoring.yml restart scaphandre
```

### **Grafana : "No data"**

```bash
# 1. Vérifier que Prometheus collecte
curl http://localhost:9090/api/v1/targets

# 2. Vérifier les métriques Scaphandre
curl http://localhost:8080/metrics | grep scaph_host_power

# 3. Tester une requête PromQL
curl 'http://localhost:9090/api/v1/query?query=scaph_host_power_microwatts'
```

### **Port déjà utilisé**

```bash
# Identifier le processus
sudo lsof -i :3000  # ou :9090, :8080

# Arrêter le processus ou changer le port dans docker-compose-monitoring.yml
```

### **Permissions insuffisantes**

```bash
# Scaphandre nécessite l'accès à /sys/class/powercap
# Le conteneur doit être en mode privileged (déjà configuré)

# Vérifier les permissions
ls -la /sys/class/powercap/intel-rapl:0/

# Si problème, utiliser sudo
sudo ./start-monitoring.sh
```

---

## 🎯 Cas d'Usage OptiVolt

### **1. Comparer les Environnements**

```promql
# Graphique comparatif
avg by (environment) (scaph_process_power_consumption_microwatts{cmdline=~".*test.*"}) / 1000000
```

### **2. Identifier les Pics de Consommation**

```promql
# Delta sur 5 minutes
delta(scaph_host_power_microwatts[5m]) / 1000000
```

### **3. Calculer le Coût Énergétique**

```promql
# kWh consommé sur 1 heure (à 0.15€/kWh)
(increase(scaph_host_energy_microjoules[1h]) / 1000000 / 3600000) * 0.15
```

### **4. Efficacité par Container**

```promql
# Watts par container
(sum by (name) (rate(container_cpu_usage_seconds_total[5m])) * 
  (scaph_host_power_microwatts / 1000000)) / 
  sum(rate(container_cpu_usage_seconds_total[5m]))
```

---

## 📚 Ressources

- [Scaphandre Documentation](https://hubblo-org.github.io/scaphandre-documentation/)
- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

---

## ✅ Checklist de Déploiement

- [ ] Docker et Docker Compose installés
- [ ] RAPL chargé (`sudo modprobe intel_rapl_common`)
- [ ] Ports disponibles (3000, 8080, 9090, 9100, 8081)
- [ ] Stack démarrée (`./start-monitoring.sh`)
- [ ] Grafana accessible (http://localhost:3000)
- [ ] Dashboard "Power Consumption" visible
- [ ] Métriques remontées (pas de "No data")

---

**🎉 Vous avez maintenant un système de monitoring complet pour OptiVolt !**

Visualisez en temps réel la consommation énergétique de vos environnements Docker, MicroVM et Unikernel ! ⚡📊
