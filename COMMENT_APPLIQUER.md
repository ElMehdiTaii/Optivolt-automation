# 🚀 COMMENT APPLIQUER - Guide Rapide

## ✅ Vous êtes prêt ! Tous les fichiers sont créés.

### 🎯 OPTION 1 : Démarrage Interactif (Recommandé)

**La façon la plus simple de commencer :**

```bash
bash START_HERE.sh
```

Ce script vous guide à travers :
- ✅ Compilation automatique du CLI
- ✅ Test rapide Docker (2 minutes)
- ✅ Affichage des premiers résultats

---

### 🔥 OPTION 2 : Commandes Manuelles (5 étapes)

Si vous préférez le contrôle total :

```bash
# 1. Compiler le CLI
cd OptiVoltCLI
dotnet publish -c Release -o ../publish
cd ..

# 2. Aller dans le dossier publish
cd publish

# 3. Déployer l'environnement Docker
./OptiVoltCLI deploy --environment docker

# 4. Lancer un test CPU de 30 secondes
./OptiVoltCLI test --environment docker --type cpu --duration 30

# 5. Collecter les métriques
./OptiVoltCLI collect --environment docker --output ../results/test1.json
```

**Voir les résultats :**
```bash
cd ..
cat results/test1.json
```

---

## 🚀 Pour aller plus loin

### Configuration complète (MicroVM + Unikernel)

**Important :** Avant d'exécuter, activez la virtualisation imbriquée dans VirtualBox.

Sur votre **machine hôte** (VM éteinte) :
```bash
VBoxManage modifyvm "Ubuntu" --nested-hw-virt on
```

Puis dans votre **VM Ubuntu** :
```bash
# Configuration automatique
bash scripts/setup_local_vms.sh

# Test de vérification
bash scripts/test_local_setup.sh

# Benchmark complet
bash scripts/run_full_benchmark.sh
```

---

## 📊 Commandes CLI Disponibles

```bash
# Déployer un environnement
./OptiVoltCLI deploy --environment <docker|microvm|unikernel>

# Exécuter des tests
./OptiVoltCLI test --environment <env> --type <cpu|api|db> --duration <seconds>

# Collecter les métriques
./OptiVoltCLI collect --environment <env|all> --output <fichier.json>
```

---

## 📖 Documentation Complète

- **Guide VirtualBox détaillé :** `docs/LOCAL_VM_SETUP.md`
- **Résumé de configuration :** `docs/VIRTUALBOX_SETUP_SUMMARY.txt`
- **État du projet :** `RAPPORT_ETAT_PROJET.md`
- **README principal :** `README.md`

---

## 📁 Scripts Créés Pour Vous

| Script | Description | Durée |
|--------|-------------|-------|
| `START_HERE.sh` | Guide interactif | 2-5 min |
| `scripts/setup_local_vms.sh` | Configuration complète | 15-20 min |
| `scripts/test_local_setup.sh` | Test rapide | 5 min |
| `scripts/run_full_benchmark.sh` | Benchmark complet | 15-30 min |

---

## 🎯 Résumé en 1 commande

**Pour commencer immédiatement :**

```bash
bash START_HERE.sh
```

Puis choisissez **Option 1** (Test rapide Docker)

**Vous aurez vos premiers résultats en 2 minutes !** 🎉

---

## 📊 Monitoring en Temps Réel (Optionnel)

```bash
# Démarrer Grafana
docker-compose -f docker-compose-monitoring.yml up -d

# Ouvrir dans le navigateur
# URL: http://localhost:3000
# Login: admin / optivolt2025
```

---

## ⚠️ Troubleshooting

### Problème : CLI non trouvé
```bash
cd OptiVoltCLI
dotnet publish -c Release -o ../publish
```

### Problème : Docker non disponible
```bash
# Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### Problème : KVM non disponible
- Activer nested virtualization dans VirtualBox
- Ou continuer avec Docker uniquement

---

## 💡 Prochaines Étapes

1. ✅ **Maintenant** : `bash START_HERE.sh`
2. Activer virtualisation imbriquée
3. Installer MicroVM/Unikernel : `bash scripts/setup_local_vms.sh`
4. Benchmark complet : `bash scripts/run_full_benchmark.sh`
5. Analyser les résultats dans `results/`

---

**Vous êtes prêt ! Lancez `bash START_HERE.sh` pour commencer.** 🚀
