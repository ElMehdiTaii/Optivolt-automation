# ⚡ Monitoring Énergétique avec Scaphandre

## 🎯 Qu'est-ce que Scaphandre ?

**Scaphandre** est un outil open-source de métrologie énergétique qui mesure la **consommation électrique réelle** (en Watts) de vos services informatiques. Il utilise les compteurs matériels Intel RAPL (Running Average Power Limit).

**📊 Intégration OptiVolt :**
- ✅ Mesurer la consommation énergétique réelle
- ✅ Comparer l'efficacité énergétique (Docker vs MicroVM vs Unikernel)
- ✅ Identifier les processus énergivores
- ✅ Décisions basées sur données énergétiques réelles

**⚠️ Limitation GitHub Codespaces :** RAPL n'est pas accessible dans les environnements virtualisés (Codespaces, VirtualBox). Scaphandre fonctionne uniquement sur du **bare-metal avec processeurs Intel récents**.

---

## 🚀 Installation (Bare-Metal uniquement)

### Option 1 : Binaire Précompilé (Recommandé)

```bash
# Télécharger
wget https://github.com/hubblo-org/scaphandre/releases/download/v1.0.0/scaphandre-v1.0.0-x86_64-unknown-linux-gnu.tar.gz

# Extraire
tar -xzf scaphandre-v1.0.0-x86_64-unknown-linux-gnu.tar.gz

# Installer
sudo mv scaphandre /usr/local/bin/
sudo chmod +x /usr/local/bin/scaphandre

# Charger module RAPL
sudo modprobe intel_rapl_common  # Kernel >= 5.0
# OU
sudo modprobe intel_rapl          # Kernel < 5.0
```

### Option 2 : Docker (Alternative)
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

```bash
# Lancer Scaphandre dans Docker
docker run -d --name scaphandre \
  -v /sys/class/powercap:/sys/class/powercap:ro \
  -v /proc:/proc:ro \
  -p 8080:8080 \
  hubblo/scaphandre prometheus
```

**⚠️ Note :** Docker nécessite également l'accès aux compteurs RAPL sur l'hôte.

---

## 🔍 Vérification

### Test Basique

```bash
# Vérifier la version
scaphandre --version

# Test de 5 secondes (stdout)
scaphandre stdout -t 5
```

**Sortie attendue (bare-metal) :**
```
Host:   12.5 W    Core    Uncore    DRAM
Socket0 12.5 W    8.2 W   2.1 W     2.2 W

Top 5 consumers:
PID     Name          Power (W)
1234    firefox       3.5
5678    chrome        2.8
9012    vscode        1.2
```

**Sortie dans Codespaces/VM :**
```
Error: Cannot access RAPL counters
RAPL requires bare-metal with Intel CPU
```

---

## 📊 Utilisation dans OptiVolt

### 1. Mode Prometheus (Recommandé)

```bash
# Lancer Scaphandre en mode Prometheus
scaphandre prometheus --port 8080

# Vérifier les métriques
curl http://localhost:8080/metrics | grep scaph_host_power_microwatts
```

**Métriques exposées :**
- `scaph_host_power_microwatts` - Consommation hôte totale
- `scaph_socket_power_microwatts` - Par socket CPU
- `scaph_process_power_consumption_microwatts` - Par processus

### 2. Intégration avec Prometheus

Éditer `monitoring/prometheus/prometheus.yml` :

```yaml
scrape_configs:
  - job_name: 'scaphandre'
    static_configs:
      - targets: ['localhost:8080']
    scrape_interval: 15s
```

Redémarrer Prometheus :
```bash
docker restart optivolt-prometheus
```

### 3. Visualisation dans Grafana

**Requêtes PromQL utiles :**

```promql
# Consommation totale (Watts)
scaph_host_power_microwatts / 1000000

# Consommation par socket
scaph_socket_power_microwatts / 1000000

# Top 5 processus énergivores
topk(5, scaph_process_power_consumption_microwatts / 1000000)
```

**Créer un panel :**
1. Grafana → Dashboards → New Panel
2. Data source : Prometheus
3. Query : `scaph_host_power_microwatts / 1000000`
4. Title : "Power Consumption (W)"
5. Save

---

## 🧪 Tests de Benchmark Énergétique

### Benchmark Simple

```bash
# Test Docker (30 secondes avec monitoring énergie)
scaphandre stdout -t 30 &
SCAPH_PID=$!

# Lancer workload
docker run --rm stress --cpu 4 --timeout 30s

# Arrêter Scaphandre
kill $SCAPH_PID
```

### Comparaison Environnements

```bash
# 1. Mesurer Docker
echo "=== Docker ===" > power_comparison.txt
scaphandre stdout -t 60 >> power_comparison.txt &
bash scripts/deploy_docker.sh
bash scripts/run_test_cpu.sh docker 60
sleep 5

# 2. Mesurer MicroVM
echo "=== MicroVM ===" >> power_comparison.txt
scaphandre stdout -t 60 >> power_comparison.txt &
bash scripts/deploy_microvm.sh
bash scripts/run_test_cpu.sh microvm 60
sleep 5

# Analyser
cat power_comparison.txt
```

---

## 📈 Interprétation des Résultats

### Exemple de Métriques

| Environment | CPU (W) | RAM (W) | Total (W) | Efficacité |
|-------------|---------|---------|-----------|------------|
| Docker      | 8.5     | 2.1     | 12.3      | Baseline   |
| MicroVM     | 6.8     | 1.5     | 9.2       | +25%       |
| Unikernel   | 5.2     | 0.9     | 7.1       | +42%       |

**✅ Meilleure efficacité = Consommation plus faible pour même workload**

---

## 🐛 Dépannage

### Problème : "Cannot access RAPL"

**Cause :** Environnement virtualisé (Codespaces, VirtualBox, VMware)

**Solution :**
```
❌ Scaphandre ne fonctionne PAS dans:
   - GitHub Codespaces
   - VirtualBox
   - VMware
   - AWS EC2 (sauf bare-metal)

✅ Scaphandre fonctionne sur:
   - Machines physiques Intel
   - Serveurs bare-metal
   - Certains cloud providers bare-metal (OVH, Hetzner)
```

### Problème : "Module intel_rapl not found"

```bash
# Vérifier les modules disponibles
ls /sys/class/powercap/

# Charger le bon module
sudo modprobe intel_rapl_common  # Kernel >= 5.0
# OU
sudo modprobe intel_rapl          # Kernel < 5.0

# Rendre permanent
echo "intel_rapl_common" | sudo tee -a /etc/modules
```

### Problème : "Permission denied /sys/class/powercap"

```bash
# Donner permissions (temporaire)
sudo chmod -R a+r /sys/class/powercap

# OU lancer avec sudo
sudo scaphandre prometheus --port 8080
```

---

## 🌐 Alternative pour Codespaces

**Dans GitHub Codespaces,** utilisez les métriques CPU/RAM comme proxy d'efficacité énergétique :

```promql
# "Efficacité énergétique estimée" basée sur CPU
(
  rate(container_cpu_usage_seconds_total{name="optivolt-docker"}[1m]) * 100
) / (
  rate(container_cpu_usage_seconds_total{name="optivolt-microvm"}[1m]) * 100
)
```

**Principe :** Moins de CPU utilisé = Moins d'énergie consommée (approximation)

---

## 📚 Ressources

### Documentation Officielle

- [Scaphandre GitHub](https://github.com/hubblo-org/scaphandre)
- [Scaphandre Documentation](https://hubblo-org.github.io/scaphandre-documentation/)
- [Intel RAPL](https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/advisory-guidance/running-average-power-limit-energy-reporting.html)

### Guides OptiVolt

- [../README.md](../README.md) - Documentation principale
- [GRAFANA_INTEGRATION.md](GRAFANA_INTEGRATION.md) - Visualisation métriques
- [../GUIDE_TESTS_REELS.md](../GUIDE_TESTS_REELS.md) - Benchmarks

---

## ✅ Récapitulatif

| Aspect | GitHub Codespaces | Bare-Metal |
|--------|-------------------|------------|
| **RAPL disponible** | ❌ Non | ✅ Oui |
| **Scaphandre fonctionne** | ❌ Non | ✅ Oui |
| **Alternative** | ✅ Métriques CPU/RAM | - |
| **Benchmarks** | ✅ Performance | ✅ Performance + Énergie |

---

**⚡ Monitoring énergétique configuré !**

Pour bare-metal, Scaphandre fournit des métriques énergétiques précises.  
Pour Codespaces, utilisez les métriques CPU/RAM comme indicateurs d'efficacité.

**Prochaine étape :** Consulter [GRAFANA_INTEGRATION.md](GRAFANA_INTEGRATION.md) pour visualiser les données.


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
