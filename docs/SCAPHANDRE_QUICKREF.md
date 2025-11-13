# ⚡ Scaphandre - Aide-Mémoire OptiVolt

## 🚀 Commandes Rapides

### Installation
```bash
./scripts/setup_scaphandre.sh install
# ou
dotnet run -- scaphandre install
```

### Vérification
```bash
./scripts/setup_scaphandre.sh check
scaphandre --version
```

### Collecte Simple
```bash
# 30 secondes, sortie JSON
./scripts/setup_scaphandre.sh run results/power.json 30

# Via OptiVolt CLI
dotnet run -- scaphandre collect --duration 30 --output results/power.json

# Affichage terminal
scaphandre stdout -t 15
```

### Mode Prometheus
```bash
# Port 8080
./scripts/setup_scaphandre.sh prometheus 8080
# Accès: http://localhost:8080/metrics
```

### Docker
```bash
./scripts/setup_scaphandre.sh docker
```

---

## 📊 Workflow OptiVolt Complet

```bash
# 1. Déployer
dotnet run -- deploy --environment docker

# 2. Tester
dotnet run -- test --environment docker --type all

# 3. Collecter (inclut Scaphandre automatiquement)
dotnet run -- metrics --environment docker

# 4. Collecter énergie uniquement
dotnet run -- scaphandre collect --duration 60

# 5. Rapport
dotnet run -- report
```

---

## 🔧 Troubleshooting Express

### Module RAPL manquant
```bash
sudo modprobe intel_rapl_common
ls -la /sys/class/powercap/
```

### Permission denied
```bash
sudo scaphandre stdout -t 5
# ou
sudo chmod -R a+r /sys/class/powercap/
```

### Scaphandre not found
```bash
which scaphandre
./scripts/setup_scaphandre.sh install
```

---

## 📖 Structure JSON Générée

```json
{
  "available": true,
  "host_power_watts": 12.5,
  "socket_power_watts": 10.2,
  "top_consumers": [
    {"pid": 642, "exe": "/usr/sbin/dockerd", "power_w": 4.81}
  ]
}
```

---

## 🎯 Prérequis

- ✅ CPU Intel (Sandy Bridge+) ou AMD récent
- ✅ Linux kernel 2.6.32+
- ✅ Module `intel_rapl_common` chargé
- ✅ Accès `/sys/class/powercap/`

---

## 📚 Documentation Complète

Voir `docs/SCAPHANDRE_INTEGRATION.md` pour le guide complet.

---

## 🔗 Liens Utiles

- [Scaphandre Docs](https://hubblo-org.github.io/scaphandre-documentation/)
- [GitHub](https://github.com/hubblo-org/scaphandre)
- [Compatibility](https://hubblo-org.github.io/scaphandre-documentation/compatibility.html)
