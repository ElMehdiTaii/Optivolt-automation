# 🚀 Guide : Exécution MicroVM et Unikernel sur Ubuntu VirtualBox

## 📋 Prérequis

Vous avez Ubuntu installé dans VirtualBox et vous voulez exécuter des MicroVMs et Unikernels **localement** pour vos benchmarks.

---

## ⚡ Configuration Rapide (5 minutes)

### Étape 1 : Activer la virtualisation imbriquée

**Sur votre machine hôte (Windows/Mac/Linux)**, éteindre la VM Ubuntu puis :

#### Via ligne de commande :
```bash
# Lister vos VMs
VBoxManage list vms

# Activer nested virtualization (remplacer "Ubuntu" par le nom de votre VM)
VBoxManage modifyvm "Ubuntu" --nested-hw-virt on
```

#### Via l'interface VirtualBox :
1. Sélectionner votre VM Ubuntu (éteinte)
2. Configuration → Système → Processeur
3. ✅ Cocher **"Activer VT-x/AMD-V imbriqué"**
4. OK → Démarrer la VM

### Étape 2 : Exécuter le script d'installation

**Dans votre VM Ubuntu** :
```bash
cd /home/ubuntu/optivolt-automation
bash scripts/setup_local_vms.sh
```

Ce script installe automatiquement :
- ✅ QEMU/KVM pour les MicroVMs
- ✅ Firecracker (MicroVM ultra-léger)
- ✅ Docker pour conteneurs
- ✅ OSv/Capstan pour Unikernels
- ✅ Configure `hosts.json` en mode local

### Étape 3 : Vérifier l'installation

```bash
# Vérifier KVM
sudo kvm-ok
# Devrait afficher : "KVM acceleration can be used"

# Vérifier les outils
docker --version
firecracker --version
qemu-system-x86_64 --version
capstan --version  # Si installé
```

---

## 🧪 Tester l'installation

### Test 1 : Docker (Baseline)
```bash
cd publish/
./OptiVoltCLI deploy --environment docker
./OptiVoltCLI test --environment docker --type cpu --duration 30
```

### Test 2 : MicroVM avec Firecracker
```bash
./OptiVoltCLI deploy --environment microvm
./OptiVoltCLI test --environment microvm --type cpu --duration 30
```

### Test 3 : Unikernel avec OSv
```bash
./OptiVoltCLI deploy --environment unikernel
./OptiVoltCLI test --environment unikernel --type cpu --duration 30
```

### Test 4 : Collecte comparative
```bash
./OptiVoltCLI collect --environment all --output results/local_comparison.json
```

---

## 🏗️ Architecture Locale

```
Ubuntu VirtualBox VM
├── Docker Engine          → Conteneurs
├── QEMU/KVM              → MicroVMs classiques
├── Firecracker           → MicroVMs ultra-légers
└── OSv (Capstan)         → Unikernels
```

**Tous tournent sur localhost** avec la même configuration réseau.

---

## 🔧 Troubleshooting

### Problème 1 : "KVM acceleration can NOT be used"

**Cause** : Virtualisation imbriquée non activée

**Solution** :
```bash
# Sur la machine hôte (VM éteinte)
VBoxManage modifyvm "NomVM" --nested-hw-virt on
```

### Problème 2 : Permission denied sur /dev/kvm

**Solution** :
```bash
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER
# Redémarrer la session ou :
newgrp kvm
```

### Problème 3 : Firecracker ne démarre pas

**Vérifier** :
```bash
# Permissions KVM
ls -la /dev/kvm

# Version kernel
uname -r  # Minimum 4.14+
```

### Problème 4 : Mode simulation (sans KVM)

Si KVM n'est pas disponible, le projet fonctionne en **mode simulation** :
- ✅ Docker fonctionne normalement
- ⚠️ MicroVM/Unikernel utilisent QEMU sans accélération (plus lent mais fonctionnel)

---

## 📊 Benchmarks Locaux

### Scenario complet automatisé

```bash
# 1. Déployer tous les environnements
for env in docker microvm unikernel; do
    ./OptiVoltCLI deploy --environment $env
done

# 2. Lancer tous les tests
for env in docker microvm unikernel; do
    for test in cpu api db; do
        ./OptiVoltCLI test --environment $env --type $test --duration 60
    done
done

# 3. Collecter les métriques
./OptiVoltCLI collect --environment all

# 4. Générer le dashboard
python3 scripts/generate_dashboard.py results/
```

### Résultats attendus

Vous pourrez comparer :
- **Temps de démarrage** : Docker vs MicroVM vs Unikernel
- **Utilisation CPU/RAM** : Overhead de virtualisation
- **Performances** : Throughput CPU, latence API
- **Consommation énergétique** : Via Scaphandre

---

## 🎯 Configuration recommandée VirtualBox

Pour des benchmarks fiables :

**VM Settings :**
- **RAM** : Minimum 4 GB (8 GB recommandé)
- **CPU** : 2-4 cœurs avec VT-x/AMD-V activé
- **Disque** : 20 GB minimum (SSD recommandé)
- **Réseau** : NAT ou Bridged

**System → Processeur :**
- ✅ Activer PAE/NX
- ✅ Activer VT-x/AMD-V imbriqué
- ✅ Allouer au moins 2 CPUs

**System → Accélération :**
- ✅ Interface de paravirtualisation : KVM

---

## 📈 Monitoring en temps réel

Pendant les tests, démarrer le monitoring :

```bash
# Terminal 1 : Démarrer Grafana/Prometheus
docker-compose -f docker-compose-monitoring.yml up -d

# Terminal 2 : Accéder au dashboard
# Ouvrir http://localhost:3000
# Login : admin / optivolt2025

# Terminal 3 : Lancer les tests
./OptiVoltCLI test --environment all --type all --duration 120
```

---

## 🚀 Exemple complet

```bash
# 1. Configuration initiale (une seule fois)
bash scripts/setup_local_vms.sh

# 2. Compilation du CLI
cd OptiVoltCLI
dotnet publish -c Release -o ../publish

# 3. Benchmark complet
cd ../publish
./OptiVoltCLI deploy --environment docker
./OptiVoltCLI test --environment docker --type all --duration 60
./OptiVoltCLI collect --environment docker

# 4. Voir les résultats
cat ../results/collected_metrics.json
```

---

## 💡 Alternatives si virtualisation imbriquée impossible

Si votre processeur ne supporte pas la virtualisation imbriquée :

### Option 1 : Utiliser uniquement Docker
```bash
# Docker fonctionne sans KVM
./OptiVoltCLI test --environment docker --type all
```

### Option 2 : Cloud gratuit
- **Oracle Cloud Free Tier** : 2 instances ARM gratuites
- **AWS Free Tier** : t2.micro avec KVM
- **Google Cloud** : 300$ de crédit

### Option 3 : Machine physique
Installer Ubuntu directement sur une machine physique pour avoir KVM natif.

---

## ✅ Checklist de validation

Après installation, vérifier :

- [ ] `sudo kvm-ok` → "KVM acceleration can be used"
- [ ] `docker ps` → fonctionne sans erreur
- [ ] `firecracker --version` → affiche la version
- [ ] `ls -la /dev/kvm` → device existe
- [ ] `./OptiVoltCLI deploy --environment docker` → succès
- [ ] `cat config/hosts.json` → tous les hosts sur localhost

---

## 📞 Support

En cas de problème, vérifier :
1. Logs : `tail -f logs/*.log`
2. Errors : `dmesg | grep kvm`
3. Documentation : `docs/`

---

**Configuration locale prête en 5 minutes ! 🎉**
