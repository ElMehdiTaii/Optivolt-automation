# 📊 Intégration Grafana pour OptiVolt

## 🎯 Vue d'Ensemble

Ce guide vous montre comment visualiser vos métriques de consommation énergétique OptiVolt avec **Grafana** + **Prometheus** + **Scaphandre**.

### **Architecture**

```
┌─────────────────────────────────────────────────────────┐
│                   OptiVolt Stack                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Scaphandre (8080)  ──┐                                │
│  Node Exporter (9100) ─┤                               │
│  cAdvisor (8081)  ─────┤                               │
│                        │                                │
│                        ├──→ Prometheus (9090)           │
│                        │    (Collecte & Stockage)       │
│                        │                                │
│                        └──→ Grafana (3000)              │
│                             (Visualisation)             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### **Composants**

| Service | Port | Rôle |
|---------|------|------|
| **Scaphandre** | 8080 | Métriques de consommation électrique (Watts) |
| **Prometheus** | 9090 | Base de données de séries temporelles |
| **Grafana** | 3000 | Interface de visualisation (dashboards) |
| **Node Exporter** | 9100 | Métriques système (CPU, RAM, Disk, Network) |
| **cAdvisor** | 8081 | Métriques Docker (containers) |

---

## 🚀 Démarrage Rapide

### **1. Démarrer la Stack**

```bash
cd /home/ubuntu/optivolt-automation
./start-monitoring.sh
```

**Le script va :**
- ✅ Vérifier Docker et RAPL
- ✅ Démarrer tous les services
- ✅ Attendre que tout soit prêt
- ✅ Afficher les URLs d'accès

### **2. Accéder à Grafana**

Ouvrez votre navigateur :
```
http://localhost:3000
```

**Identifiants :**
- **Username :** `admin`
- **Password :** `optivolt2025`

### **3. Voir le Dashboard**

Le dashboard **"OptiVolt - Power Consumption Monitoring"** est automatiquement configuré !

Naviguez vers : **Dashboards → OptiVolt → Power Consumption Monitoring**

---

## 📊 Dashboards Disponibles

### **Dashboard Principal : Power Consumption**

Le dashboard inclut :

#### **1. Total Host Power Consumption**
- Consommation totale de l'hôte en Watts
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
