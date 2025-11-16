# 🚀 Configuration GitHub Codespaces pour OptivoltCLI

## Pourquoi GitHub Codespaces ?

✅ **60 heures/mois GRATUITES** pour tous les comptes GitHub  
✅ **KVM natif disponible** sur machines 4-core+  
✅ **Configuration en 10 minutes**  
✅ **VS Code dans le navigateur** - aucune installation locale  
✅ **Accès depuis n'importe où** - juste un navigateur  
✅ **Firecracker + OSv fonctionnent** directement  

---

## 📋 Prérequis

- **Compte GitHub** (gratuit) - https://github.com
- **Navigateur web** moderne (Chrome, Firefox, Edge)
- **Connexion internet** stable

---

## Étape 1 : Créer/Préparer votre repository GitHub (5 min)

### 1.1 Créer un compte GitHub (si vous n'en avez pas)

1. Aller sur https://github.com/signup
2. Entrer votre email
3. Créer un mot de passe
4. Choisir un nom d'utilisateur
5. Vérifier votre email
6. Sélectionner le plan **Free** (gratuit)

### 1.2 Créer un nouveau repository

**Option A : Depuis l'interface GitHub**

1. Aller sur https://github.com/new
2. **Repository name** : `optivolt-automation`
3. **Description** : `OptivoltCLI - Docker vs MicroVM vs Unikernel benchmarking`
4. Sélectionner **Public** (pour Codespaces gratuit)
5. ☑ **Add a README file**
6. Cliquer sur **"Create repository"**

**Option B : Depuis votre machine locale (VirtualBox)**

```bash
cd /home/ubuntu/optivolt-automation

# Initialiser Git (si pas déjà fait)
git init

# Ajouter tous les fichiers
git add .

# Commit initial
git commit -m "Initial commit - OptivoltCLI project"

# Ajouter le remote GitHub (remplacer votreusername)
git remote add origin https://github.com/votreusername/optivolt-automation.git

# Push vers GitHub
git branch -M main
git push -u origin main
```

---

## Étape 2 : Créer un Codespace (2 min)

### 2.1 Ouvrir votre repository sur GitHub

```
https://github.com/votreusername/optivolt-automation
```

### 2.2 Lancer un Codespace

**Méthode 1 : Via l'interface GitHub**

1. Sur la page du repository, cliquer sur le bouton vert **"Code"**
2. Cliquer sur l'onglet **"Codespaces"**
3. Cliquer sur **"Create codespace on main"**
4. **Sélectionner la machine** : 
   - **4-core** (minimum pour KVM)
   - ou **8-core** (recommandé pour meilleures performances)

⏱️ **Temps de création** : 2-3 minutes

✅ **VS Code s'ouvre dans le navigateur** avec votre projet !

**Méthode 2 : Via CLI GitHub (optionnel)**

```bash
# Installer GitHub CLI (sur votre machine locale)
gh auth login

# Créer un codespace
gh codespace create --repo votreusername/optivolt-automation --machine largePremiumLinux

# Ouvrir VS Code web
gh codespace code

# OU se connecter en SSH
gh codespace ssh
```

---

## Étape 3 : Vérifier KVM dans Codespace (2 min)

### 3.1 Ouvrir le terminal

Dans VS Code (navigateur), ouvrir le terminal :
- **Menu** : `Terminal` → `New Terminal`
- **OU raccourci** : `` Ctrl+` `` (backtick)

### 3.2 Vérifier KVM

```bash
# Vérifier les flags CPU
egrep -c '(vmx|svm)' /proc/cpuinfo
# Doit afficher un nombre > 0

# Installer cpu-checker
sudo apt update
sudo apt install -y cpu-checker

# Vérifier KVM
sudo kvm-ok
```

✅ **Résultat attendu** :
```
INFO: /dev/kvm exists
KVM acceleration can be used
```

❌ **Si KVM non disponible** :

Vérifier la taille de la machine :
```bash
# Afficher les specs
nproc   # Doit afficher au moins 4
free -h # RAM disponible
```

**Si < 4 cores** : Recréer le Codespace avec machine 4-core minimum :
1. Fermer le Codespace actuel
2. Sur GitHub : `Code` → `Codespaces` → `...` → `Delete`
3. Recréer avec **4-core** ou **8-core**

---

## Étape 4 : Installer les dépendances (10 min)

### 4.1 Installer Docker

```bash
# Docker est souvent pré-installé dans Codespaces
docker --version

# Si pas installé :
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

### 4.2 Installer QEMU/KVM

```bash
sudo apt update
sudo apt install -y \
  qemu-kvm \
  qemu-system-x86 \
  libvirt-daemon-system \
  bridge-utils \
  cpu-checker
```

### 4.3 Installer Python et dépendances

```bash
# Python3 et pip
sudo apt install -y python3 python3-pip

# Dépendances Python du projet
pip3 install psutil
```

### 4.4 Installer .NET 8.0 (pour OptiVoltCLI)

```bash
# Télécharger et installer .NET
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0

# Ajouter au PATH
echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> ~/.bashrc
source ~/.bashrc

# Vérifier
dotnet --version
```

---

## Étape 5 : Installer Firecracker et OSv (10 min)

### 5.1 Utiliser le script d'installation

```bash
cd /workspaces/optivolt-automation
bash scripts/setup_local_vms.sh
```

Ce script installe automatiquement :
- ✅ Firecracker v1.5.0
- ✅ OSv avec Capstan
- ✅ Configure `config/hosts.json`

### 5.2 Vérifier les installations

**Firecracker** :
```bash
firecracker --version
# Doit afficher: Firecracker v1.5.0
```

**OSv (Capstan)** :
```bash
capstan --version
# Doit afficher la version de Capstan
```

**KVM** :
```bash
ls -la /dev/kvm
# Doit exister
```

---

## Étape 6 : Configurer les ports (forward) (3 min)

GitHub Codespaces forward automatiquement les ports, mais on peut les configurer manuellement.

### 6.1 Forward des ports dans VS Code

Dans le terminal VS Code :
1. Ouvrir l'onglet **"PORTS"** (en bas)
2. Les ports sont auto-détectés quand les services démarrent
3. Vérifier que ces ports sont visibles :
   - `3000` - Grafana
   - `9090` - Prometheus
   - `9100` - Node Exporter
   - `8080` - cAdvisor

### 6.2 Rendre les ports publics (optionnel)

Pour accéder depuis un autre appareil :
1. Clic droit sur le port dans l'onglet PORTS
2. **"Port Visibility"** → **"Public"**

⚠️ **Attention** : Cela rend le service accessible sur Internet !

---

## Étape 7 : Démarrer le monitoring (5 min)

### 7.1 Lancer Docker Compose

```bash
cd /workspaces/optivolt-automation

# Démarrer tous les services de monitoring
docker-compose -f docker-compose-monitoring.yml up -d

# Vérifier les conteneurs
docker ps
```

✅ **Conteneurs attendus** :
- `grafana` (port 3000)
- `prometheus` (port 9090)
- `node-exporter` (port 9100)
- `cadvisor` (port 8080)
- `scaphandre` (monitoring énergétique)

### 7.2 Accéder à Grafana

**Dans VS Code Codespace** :
1. Aller dans l'onglet **"PORTS"**
2. Trouver la ligne **3000** (Grafana)
3. Cliquer sur l'icône **"🌐 Open in Browser"**

**OU copier l'URL** :
```
https://<votre-codespace-name>-3000.app.github.dev
```

**Identifiants Grafana** :
- Username : `admin`
- Password : `optivolt2025`

✅ Vous devriez voir les dashboards Grafana !

---

## Étape 8 : Exécuter les tests (15 min)

### 8.1 Test rapide de vérification

```bash
cd /workspaces/optivolt-automation
bash scripts/test_local_setup.sh
```

✅ **Vérifications** :
- Docker : OK
- Firecracker : OK
- OSv/Capstan : OK
- KVM : OK
- Monitoring : OK

### 8.2 Déployer les 3 environnements

**Docker** :
```bash
bash scripts/deploy_docker.sh
docker ps | grep optivolt-test-app
```

**MicroVM (Firecracker)** :
```bash
# Le script setup_local_vms.sh a déjà préparé Firecracker
# Vérifier que /dev/kvm est accessible
ls -la /dev/kvm
sudo chmod 666 /dev/kvm  # Si besoin
```

**Unikernel (OSv)** :
```bash
# Capstan est déjà installé
capstan --version
```

### 8.3 Exécuter le benchmark complet

```bash
cd /workspaces/optivolt-automation
bash scripts/run_full_benchmark.sh
```

**Durée** : ~10-15 minutes

**Résultats stockés dans** :
```
results/
├── docker_results.json
├── microvm_results.json
└── unikernel_results.json
```

### 8.4 Visualiser les résultats

**Grafana** :
1. Ouvrir l'URL du port 3000 (voir Étape 7.2)
2. Dashboard : **"OptiVolt Performance Comparison"**
3. Comparer :
   - CPU usage (Docker vs MicroVM vs Unikernel)
   - RAM usage
   - Temps de démarrage
   - Throughput

**JSON Results** :
```bash
# Afficher les résultats JSON
cat results/docker_results.json | jq .
cat results/microvm_results.json | jq .
cat results/unikernel_results.json | jq .
```

---

## Étape 9 : Utiliser OptiVoltCLI (5 min)

### 9.1 Compiler le CLI

```bash
cd /workspaces/optivolt-automation/OptiVoltCLI
dotnet build -c Release
dotnet publish -c Release -o ../publish
```

### 9.2 Tester les commandes

```bash
cd /workspaces/optivolt-automation

# Deploy sur localhost
./publish/OptiVoltCLI deploy --host localhost

# Run test CPU (60 secondes)
./publish/OptiVoltCLI test --host localhost --duration 60

# Collect metrics
./publish/OptiVoltCLI collect --host localhost --output results/codespace_test.json
```

### 9.3 Voir les résultats collectés

```bash
# Afficher les métriques
cat results/codespace_test.json | jq .

# Voir les logs
ls -lh logs/
cat logs/optivolt-cli.log
```

---

## Étape 10 : Télécharger les résultats (5 min)

### 10.1 Depuis VS Code web

**Méthode 1 : Via l'explorateur de fichiers**
1. Clic droit sur le dossier `results/`
2. **"Download..."**
3. Les fichiers sont téléchargés sur votre machine locale

**Méthode 2 : Via terminal**
```bash
# Créer une archive
cd /workspaces/optivolt-automation
tar czf optivolt-results.tar.gz results/ logs/

# Télécharger via VS Code
# Clic droit sur optivolt-results.tar.gz → Download
```

### 10.2 Depuis GitHub CLI (optionnel)

```bash
# Sur votre machine locale
gh codespace cp remote:~/optivolt-automation/results/*.json ./
```

---

## 🎯 Architecture GitHub Codespaces

```
┌─────────────────────────────────────────────────────────┐
│  Votre navigateur (Chrome/Firefox/Edge)                 │
│  ┌───────────────────────────────────────────┐          │
│  │  VS Code Web                              │          │
│  │  https://*.github.dev                     │          │
│  └───────────────┬───────────────────────────┘          │
└──────────────────┼──────────────────────────────────────┘
                   │ HTTPS
                   ▼
┌─────────────────────────────────────────────────────────┐
│  GitHub Codespace (Cloud Linux VM)                      │
│  ┌─────────────────────────────────────────────┐        │
│  │  /workspaces/optivolt-automation            │        │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  │        │
│  │  │  Docker  │  │Firecracker│ │   OSv    │  │        │
│  │  │Container │  │  MicroVM  │  │ Unikernel│  │        │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  │        │
│  │       │             │             │         │        │
│  │       └─────────────┴─────────────┘         │        │
│  │                     │                       │        │
│  │           ┌─────────▼─────────┐             │        │
│  │           │  KVM (/dev/kvm)   │             │        │
│  │           └───────────────────┘             │        │
│  │                                             │        │
│  │           ┌───────────────────┐             │        │
│  │           │ Monitoring Stack  │             │        │
│  │           │ • Grafana :3000   │◄────────────┼────────┐
│  │           │ • Prometheus :9090│             │        │
│  │           │ • Node Exporter   │             │        │
│  │           └───────────────────┘             │        │
│  └─────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
         │
         │ Port forwarding (https://*-3000.github.dev)
         ▼
┌─────────────────────────────────────────────────────────┐
│  Votre navigateur - Grafana                             │
│  https://<codespace>-3000.app.github.dev                │
└─────────────────────────────────────────────────────────┘
```

---

## 💡 Astuces GitHub Codespaces

### Pause/Resume automatique

- **Pause automatique** après 30 minutes d'inactivité
- **Resume** en cliquant sur "Restart Codespace"
- Les fichiers sont **conservés** pendant 30 jours

### Limites du plan gratuit

✅ **60 heures/mois** pour tous les comptes  
✅ **Machines 2-core** illimitées  
✅ **Machines 4-core** : ~15h/mois (60h * 0.25)  
✅ **Machines 8-core** : ~7.5h/mois (60h * 0.125)  

**Calcul** : 1h sur machine 4-core = 2 "core-hours"

### Surveiller votre usage

```
https://github.com/settings/billing
```

Section **"Codespaces"** → Voir heures consommées

### Optimiser l'usage

1. **Pause manuelle** quand vous ne travaillez pas :
   - `Cmd/Ctrl + Shift + P` → "Stop Current Codespace"

2. **Supprimer les Codespaces** inutilisés :
   - https://github.com/codespaces
   - Supprimer les anciens

3. **Utiliser machine 4-core** au lieu de 8-core (suffisant)

### Accès VS Code Desktop (optionnel)

Au lieu du web, ouvrir dans VS Code local :
1. Installer VS Code Desktop
2. Installer extension "GitHub Codespaces"
3. `Cmd/Ctrl + Shift + P` → "Codespaces: Connect to Codespace"

---

## 🔧 Dépannage

### Problème : KVM non disponible

**Erreur** : "/dev/kvm: No such file or directory"

**Solution** :
```bash
# Vérifier la taille de la machine
nproc  # Doit être >= 4

# Si < 4 : Recréer le Codespace avec machine 4-core+
```

**Sur GitHub** :
1. Supprimer le Codespace actuel
2. `Code` → `Codespaces` → `New with options`
3. Sélectionner **"4-core"** ou **"8-core"**

### Problème : Docker ne démarre pas

**Solution** :
```bash
# Démarrer le service Docker
sudo service docker start

# Ajouter votre user au groupe
sudo usermod -aG docker $USER
newgrp docker
```

### Problème : Port Grafana inaccessible

**Vérifications** :
1. Conteneur démarré ?
   ```bash
   docker ps | grep grafana
   ```

2. Port forwarding actif ?
   - Vérifier l'onglet "PORTS" dans VS Code

3. Visibilité du port ?
   - Clic droit sur port 3000 → "Port Visibility" → "Public"

### Problème : Firecracker "Permission denied"

**Solution** :
```bash
# Donner accès à /dev/kvm
sudo chmod 666 /dev/kvm

# Ajouter au groupe kvm
sudo usermod -aG kvm $USER
newgrp kvm
```

### Problème : Espace disque insuffisant

**Vérifier** :
```bash
df -h
```

**Nettoyer** :
```bash
# Supprimer images Docker inutilisées
docker system prune -a -f

# Nettoyer apt cache
sudo apt clean
```

---

## 📚 Ressources

- **GitHub Codespaces** : https://github.com/features/codespaces
- **Documentation** : https://docs.github.com/codespaces
- **Pricing** : https://docs.github.com/billing/managing-billing-for-github-codespaces
- **VS Code Web** : https://code.visualstudio.com/docs/editor/vscode-web

---

## ✅ Checklist finale

- [ ] Compte GitHub créé
- [ ] Repository `optivolt-automation` créé
- [ ] Codespace lancé avec machine 4-core minimum
- [ ] VS Code web ouvert dans le navigateur
- [ ] `sudo kvm-ok` affiche "KVM acceleration can be used"
- [ ] Docker installé et fonctionnel
- [ ] .NET 8.0 installé
- [ ] Firecracker v1.5.0 installé
- [ ] OSv/Capstan installé
- [ ] Monitoring stack démarré (docker-compose)
- [ ] Grafana accessible via port forwarding (3000)
- [ ] Tests exécutés avec succès
- [ ] Résultats JSON générés dans `results/`
- [ ] Grafana affiche les comparaisons Docker vs MicroVM vs Unikernel
- [ ] Résultats téléchargés sur votre machine locale

---

## 🚀 Commandes récapitulatives

**Setup complet en une session** :

```bash
# 1. Vérifier KVM
sudo apt update && sudo apt install -y cpu-checker
sudo kvm-ok

# 2. Installer tout
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER && newgrp docker
wget https://dot.net/v1/dotnet-install.sh && bash dotnet-install.sh --channel 8.0
echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc && source ~/.bashrc

# 3. Setup projet
cd /workspaces/optivolt-automation
bash scripts/setup_local_vms.sh

# 4. Lancer monitoring
docker-compose -f docker-compose-monitoring.yml up -d

# 5. Exécuter benchmark
bash scripts/run_full_benchmark.sh

# 6. Voir résultats
cat results/*.json | jq .
```

---

**Prêt à tester dans Codespaces !** 🎉

**Temps total estimé** : 30-45 minutes pour setup complet + benchmarks
