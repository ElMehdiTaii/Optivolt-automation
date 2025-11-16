# 🚀 Configuration WSL2 avec KVM pour OptivoltCLI

## Pourquoi WSL2 ?

✅ **KVM natif** supporté depuis Windows 11 build 22000+  
✅ **Plus simple** que VirtualBox avec nested virtualization  
✅ **Meilleures performances** que VirtualBox  
✅ **Intégration parfaite** avec Windows  
✅ **Gratuit** et inclus dans Windows  

---

## 📋 Prérequis

- **Windows 11** (ou Windows 10 version 22H2+)
- **Virtualisation activée** dans le BIOS (VT-x/AMD-V)
- **Au moins 8 GB RAM** (12 GB recommandé)
- **20 GB d'espace disque** libre

---

## Étape 1 : Vérifier votre version Windows (2 min)

### 1.1 Vérifier la version

**Ouvrir PowerShell** :
- Appuyer sur `Win + X`
- Cliquer sur **"Windows PowerShell"** ou **"Terminal"**

**Exécuter** :
```powershell
winver
```

✅ **Requis** :
- Windows 11 : Build **22000** ou supérieur
- Windows 10 : Version **22H2** (build 19045) ou supérieur

### 1.2 Vérifier la virtualisation

```powershell
systeminfo | findstr /C:"Virtualization"
```

✅ **Résultat attendu** :
```
Virtualization Enabled In Firmware: Yes
```

❌ **Si "No"** → Aller dans le BIOS et activer VT-x/AMD-V :
1. Redémarrer le PC
2. Appuyer sur `F2`, `F10`, `Del` ou `Esc` (selon fabricant)
3. Chercher "Virtualization Technology" ou "VT-x" ou "AMD-V"
4. Mettre sur **Enabled**
5. Sauvegarder et redémarrer

---

## Étape 2 : Installer WSL2 (10 min)

### 2.1 Ouvrir PowerShell en Administrateur

1. Appuyer sur `Win + X`
2. Cliquer sur **"Terminal (Admin)"** ou **"Windows PowerShell (Admin)"**
3. Cliquer **"Oui"** sur l'invite UAC

### 2.2 Installer WSL2

**Commande unique** (recommandée) :
```powershell
wsl --install
```

Cette commande :
- Active les fonctionnalités WSL
- Installe WSL2
- Télécharge Ubuntu (par défaut)
- Configure tout automatiquement

**OU installation manuelle** (si `--install` ne fonctionne pas) :
```powershell
# Activer WSL
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Activer Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Redémarrer Windows
Restart-Computer
```

**Après redémarrage** :
```powershell
# Définir WSL2 par défaut
wsl --set-default-version 2

# Mettre à jour WSL
wsl --update
```

### 2.3 Installer Ubuntu 22.04

```powershell
wsl --install -d Ubuntu-22.04
```

**Lors du premier démarrage** :
- Entrer un **nom d'utilisateur** (ex: `optivolt`)
- Entrer un **mot de passe** (vous en aurez besoin !)
- Confirmer le mot de passe

✅ **Terminé !** Vous êtes maintenant dans Ubuntu.

---

## Étape 3 : Activer la virtualisation imbriquée (5 min)

### 3.1 Quitter WSL

Dans le terminal Ubuntu WSL :
```bash
exit
```

### 3.2 Créer/éditer `.wslconfig`

**Ouvrir Bloc-notes en Administrateur** :
1. `Win + R` → taper `notepad`
2. Clic droit → **"Exécuter en tant qu'administrateur"**

**Ouvrir/créer le fichier** :
```
C:\Users\<VotreNomUtilisateur>\.wslconfig
```

**Remplacer par** (ou ajouter si vide) :
```ini
[wsl2]
# Activer la virtualisation imbriquée (KVM)
nestedVirtualization=true

# Allouer 12 GB RAM (ajuster selon votre PC)
memory=12GB

# Allouer 4 CPU cores (ajuster selon votre PC)
processors=4

# Désactiver la limite de swap
swap=0

# Localiser le fichier swap (optionnel)
# swapFile=C:\\Users\\<VotreNom>\\wsl-swap.vhdx
```

**Sauvegarder et fermer** le Bloc-notes.

### 3.3 Redémarrer WSL

**Dans PowerShell** :
```powershell
# Arrêter toutes les instances WSL
wsl --shutdown

# Attendre 10 secondes
Start-Sleep -Seconds 10

# Redémarrer Ubuntu
wsl -d Ubuntu-22.04
```

---

## Étape 4 : Vérifier KVM dans WSL2 (5 min)

### 4.1 Installer les outils de vérification

**Dans le terminal Ubuntu WSL2** :
```bash
# Mettre à jour les paquets
sudo apt update

# Installer cpu-checker et KVM
sudo apt install -y cpu-checker qemu-kvm libvirt-daemon-system
```

### 4.2 Vérifier KVM

```bash
sudo kvm-ok
```

✅ **Résultat attendu** :
```
INFO: /dev/kvm exists
KVM acceleration can be used
```

❌ **Si erreur "KVM not available"** :

**Vérifier les flags CPU** :
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

Si `0` → La virtualisation n'est pas activée :
1. Vérifier `.wslconfig` (étape 3.2)
2. Vérifier BIOS (étape 1.2)
3. Redémarrer Windows complètement

**Vérifier le device /dev/kvm** :
```bash
ls -la /dev/kvm
```

Si n'existe pas :
```bash
sudo modprobe kvm
sudo modprobe kvm_intel  # Pour Intel
# OU
sudo modprobe kvm_amd    # Pour AMD
```

---

## Étape 5 : Installer le projet OptivoltCLI (10 min)

### 5.1 Installer Git et Docker

**Dans Ubuntu WSL2** :
```bash
# Git
sudo apt install -y git

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Recharger les groupes
newgrp docker

# Vérifier Docker
docker --version
docker ps
```

### 5.2 Cloner le projet

**Option A : Depuis GitHub** (si vous avez un repo) :
```bash
cd ~
git clone https://github.com/votreuser/optivolt-automation.git
cd optivolt-automation
```

**Option B : Copier depuis Windows** :

**Sur Windows** (PowerShell) :
```powershell
# Copier le projet dans WSL
wsl -d Ubuntu-22.04 cp -r /mnt/c/chemin/vers/optivolt-automation ~/optivolt-automation
```

**OU depuis Ubuntu WSL2** :
```bash
# Accéder aux fichiers Windows (lecteur C: = /mnt/c/)
cp -r /mnt/c/Users/<VotreNom>/Documents/optivolt-automation ~/optivolt-automation
cd ~/optivolt-automation
```

### 5.3 Installer les dépendances du projet

```bash
cd ~/optivolt-automation

# Installer Python et dépendances
sudo apt install -y python3 python3-pip
pip3 install psutil

# Installer .NET 8.0 (pour OptiVoltCLI)
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0

# Ajouter .NET au PATH
echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> ~/.bashrc
source ~/.bashrc
```

---

## Étape 6 : Installer Firecracker et OSv (15 min)

### 6.1 Exécuter le script d'installation

```bash
cd ~/optivolt-automation
bash scripts/setup_local_vms.sh
```

Ce script installe automatiquement :
- ✅ QEMU/KVM
- ✅ Firecracker v1.5.0
- ✅ OSv avec Capstan
- ✅ Configure `config/hosts.json`

### 6.2 Vérifier les installations

**Docker** :
```bash
docker ps
```

**Firecracker** :
```bash
firecracker --version
# Doit afficher: Firecracker v1.5.0
```

**OSv (Capstan)** :
```bash
capstan --version
# Doit afficher: Capstan version
```

**KVM** :
```bash
sudo kvm-ok
# Doit afficher: KVM acceleration can be used
```

---

## Étape 7 : Démarrer le monitoring (5 min)

### 7.1 Lancer Docker Compose

```bash
cd ~/optivolt-automation

# Démarrer Grafana, Prometheus, Node-exporter, etc.
docker-compose -f docker-compose-monitoring.yml up -d

# Vérifier les conteneurs
docker ps
```

✅ **Conteneurs attendus** :
- `grafana` (port 3000)
- `prometheus` (port 9090)
- `node-exporter` (port 9100)
- `cadvisor` (port 8080)
- `scaphandre` (power monitoring)

### 7.2 Accéder à Grafana depuis Windows

**Dans votre navigateur Windows** :
```
http://localhost:3000
```

**Identifiants** :
- Username : `admin`
- Password : `optivolt2025`

✅ Vous devriez voir le dashboard Grafana !

---

## Étape 8 : Exécuter les tests (10 min)

### 8.1 Test rapide

```bash
cd ~/optivolt-automation
bash scripts/test_local_setup.sh
```

✅ **Vérifications** :
- Docker : OK
- Firecracker : OK
- OSv/Capstan : OK
- Monitoring : OK

### 8.2 Déploiement Docker

```bash
cd ~/optivolt-automation
bash scripts/deploy_docker.sh
```

✅ Créé un conteneur `optivolt-test-app`

### 8.3 Benchmark complet

```bash
cd ~/optivolt-automation
bash scripts/run_full_benchmark.sh
```

**Durée** : ~10 minutes

**Résultats dans** :
- `results/docker_results.json`
- `results/microvm_results.json`
- `results/unikernel_results.json`

---

## Étape 9 : Utiliser OptiVoltCLI (5 min)

### 9.1 Compiler le CLI (si nécessaire)

```bash
cd ~/optivolt-automation/OptiVoltCLI
dotnet build -c Release
dotnet publish -c Release -o ../publish
```

### 9.2 Tester les commandes

```bash
cd ~/optivolt-automation

# Deploy sur localhost
./publish/OptiVoltCLI deploy --host localhost

# Run test CPU (60 secondes)
./publish/OptiVoltCLI test --host localhost --duration 60

# Collect metrics
./publish/OptiVoltCLI collect --host localhost --output results/wsl2_test.json
```

### 9.3 Voir les résultats dans Grafana

**Navigateur Windows** :
```
http://localhost:3000
```

- Dashboard : **"OptiVolt Performance Comparison"**
- Voir CPU, RAM, temps démarrage
- Comparer Docker vs MicroVM vs Unikernel

---

## 🎯 Architecture WSL2

```
┌─────────────────────────────────────────────────────────┐
│  Windows 11                                             │
│  ┌───────────────────────────────────────────┐          │
│  │  Navigateur                               │          │
│  │  http://localhost:3000 → Grafana          │          │
│  └───────────────┬───────────────────────────┘          │
│                  │                                       │
│  ┌───────────────▼───────────────────────────┐          │
│  │  WSL2 (Ubuntu 22.04)                      │          │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐│          │
│  │  │  Docker  │  │Firecracker│ │   OSv    ││          │
│  │  │Container │  │  MicroVM  │  │ Unikernel││          │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘│          │
│  │       │             │             │       │          │
│  │       └─────────────┴─────────────┘       │          │
│  │                     │                     │          │
│  │           ┌─────────▼─────────┐           │          │
│  │           │  KVM (/dev/kvm)   │           │          │
│  │           └───────────────────┘           │          │
│  │                                           │          │
│  │           ┌───────────────────┐           │          │
│  │           │ Monitoring Stack  │           │          │
│  │           │ • Grafana :3000   │           │          │
│  │           │ • Prometheus :9090│           │          │
│  │           │ • Node Exporter   │           │          │
│  │           └───────────────────┘           │          │
│  └───────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Dépannage

### Problème : WSL2 ne démarre pas

**Erreur** : "The virtual machine could not be started..."

**Solution** :
```powershell
# PowerShell Admin
wsl --shutdown
wsl --unregister Ubuntu-22.04
wsl --install -d Ubuntu-22.04
```

### Problème : KVM non disponible malgré .wslconfig

**Vérifications** :
1. Windows 11 build 22000+ ?
   ```powershell
   winver
   ```

2. Virtualisation activée dans BIOS ?
   ```powershell
   systeminfo | findstr /C:"Virtualization"
   ```

3. `.wslconfig` bien placé ?
   - Doit être dans `C:\Users\<VotreNom>\.wslconfig`
   - Vérifier les fautes de frappe

4. WSL bien redémarré ?
   ```powershell
   wsl --shutdown
   # Attendre 10 secondes
   wsl
   ```

### Problème : Docker ne démarre pas

**Solution** :
```bash
# Démarrer le service Docker
sudo service docker start

# OU installer Docker Desktop Windows
# puis Settings → Use WSL2 based engine
```

### Problème : Grafana inaccessible depuis Windows

**Vérifications** :
1. Conteneur démarré ?
   ```bash
   docker ps | grep grafana
   ```

2. Port binding correct ?
   ```bash
   docker port <grafana_container_id>
   ```

3. Firewall Windows ?
   - Ouvrir "Pare-feu Windows Defender"
   - Autoriser port 3000 pour WSL

### Problème : Firecracker "Permission denied /dev/kvm"

**Solution** :
```bash
# Ajouter votre utilisateur au groupe kvm
sudo usermod -aG kvm $USER

# Recharger les groupes
newgrp kvm

# OU changer les permissions (temporaire)
sudo chmod 666 /dev/kvm
```

---

## 💡 Astuces WSL2

### Accéder aux fichiers Windows depuis WSL2

```bash
# Lecteur C:
cd /mnt/c/Users/<VotreNom>/Documents

# Lecteur D:
cd /mnt/d/
```

### Accéder aux fichiers WSL2 depuis Windows

**Explorateur Windows** :
```
\\wsl$\Ubuntu-22.04\home\<votreuser>\
```

**OU directement** :
```
\\wsl.localhost\Ubuntu-22.04\home\<votreuser>\
```

### Exécuter des commandes WSL depuis PowerShell

```powershell
# Exécuter une commande
wsl ls -la

# Exécuter un script
wsl bash ~/optivolt-automation/scripts/test_local_setup.sh

# Ouvrir VS Code dans le dossier WSL
wsl code ~/optivolt-automation
```

### Limiter la consommation RAM de WSL2

**Éditer `.wslconfig`** :
```ini
[wsl2]
memory=8GB          # Limiter à 8 GB
processors=2        # Limiter à 2 cores
swap=2GB            # Limiter le swap
```

### Sauvegarder/Restaurer votre installation WSL2

**Exporter** :
```powershell
wsl --export Ubuntu-22.04 C:\backup\ubuntu-optivolt.tar
```

**Importer** :
```powershell
wsl --import Ubuntu-OptiVolt C:\WSL\Ubuntu C:\backup\ubuntu-optivolt.tar
```

---

## 📚 Ressources

- **Documentation Microsoft WSL** : https://learn.microsoft.com/windows/wsl/
- **WSL2 + KVM** : https://learn.microsoft.com/windows/wsl/wsl-config#nested-virtualization
- **Firecracker** : https://firecracker-microvm.github.io/
- **OSv** : http://osv.io/
- **Docker Desktop WSL2** : https://docs.docker.com/desktop/wsl/

---

## ✅ Checklist finale

- [ ] Windows 11 build 22000+ vérifié
- [ ] Virtualisation activée dans BIOS
- [ ] WSL2 installé
- [ ] Ubuntu 22.04 installé dans WSL2
- [ ] `.wslconfig` créé avec `nestedVirtualization=true`
- [ ] WSL redémarré avec `wsl --shutdown`
- [ ] `sudo kvm-ok` affiche "KVM acceleration can be used"
- [ ] Docker installé et fonctionnel
- [ ] Projet OptivoltCLI cloné/copié
- [ ] Firecracker installé (v1.5.0)
- [ ] OSv/Capstan installé
- [ ] Monitoring stack démarré
- [ ] Grafana accessible sur http://localhost:3000
- [ ] Tests exécutés avec succès
- [ ] Résultats visibles dans Grafana

---

## 🚀 Prochaines étapes

Une fois WSL2 configuré :

1. **Exécuter le benchmark complet**
   ```bash
   cd ~/optivolt-automation
   bash scripts/run_full_benchmark.sh
   ```

2. **Analyser les résultats dans Grafana**
   - Ouvrir http://localhost:3000 (Windows)
   - Dashboard "OptiVolt Performance Comparison"
   - Comparer Docker vs Firecracker vs OSv

3. **Générer le rapport final**
   ```bash
   python3 scripts/generate_final_dashboard.py
   ```

4. **Sauvegarder les résultats**
   ```bash
   # Copier vers Windows
   cp -r ~/optivolt-automation/results /mnt/c/Users/<VotreNom>/Documents/
   ```

---

**Besoin d'aide ?** N'hésitez pas à poser des questions !
