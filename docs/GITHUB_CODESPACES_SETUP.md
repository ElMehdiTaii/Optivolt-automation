# 🚀 Configuration GitHub Codespaces pour OptiVolt

## 💡 Pourquoi GitHub Codespaces ?

✅ **120 heures/mois GRATUITES** (comptes gratuits) + stockage 15GB  
✅ **KVM natif disponible** - Support Firecracker et virtualisation  
✅ **Démarrage < 2 minutes** - Environnement préconfiguré  
✅ **VS Code dans le navigateur** - Aucune installation locale  
✅ **Accès universel** - Depuis n'importe quel appareil  
✅ **Docker préinstallé** - Stack monitoring ready  

**🎯 Parfait pour OptiVolt :** Benchmarks Docker vs MicroVM vs Unikernel avec monitoring temps réel !

---

## 📋 Prérequis

- **Compte GitHub** (gratuit) → https://github.com/signup
- **Navigateur moderne** (Chrome, Firefox, Edge, Safari)
- **Connexion internet** stable

---

## 🚀 Étape 1 : Créer un Codespace (2 minutes)

### Si vous avez déjà un repository OptiVolt

1. Aller sur votre repository : `https://github.com/votre-username/Optivolt-automation`
2. Cliquer sur le bouton vert **"Code"**
3. Onglet **"Codespaces"**
4. Cliquer **"Create codespace on main"**
5. ☕ Attendre 1-2 minutes (installation automatique)

### Si vous n'avez pas encore de repository

**Option A : Fork ce projet**
```
https://github.com/ElMehdiTaii/Optivolt-automation
```
→ Cliquer **"Fork"** en haut à droite  
→ Puis suivre les étapes ci-dessus sur votre fork

**Option B : Créer depuis zéro**

1. Créer un nouveau repository sur GitHub
2. Cloner votre code existant :
   ```bash
   cd /votre/projet/local
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/votre-username/optivolt.git
   git push -u origin main
   ```
3. Créer un Codespace depuis ce repository
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

## ⚡ Étape 2 : Premier Démarrage (< 3 minutes)

### 2.1 Ouvrir le Terminal

Dans VS Code (navigateur) :
- **Menu** → `Terminal` → `New Terminal`
- **OU** raccourci : `` Ctrl+` ``

### 2.2 Vérifier l'Environnement

```bash
# Vérifier Docker (préinstallé)
docker --version
docker ps

# Vérifier .NET SDK (préinstallé)
dotnet --version  # Doit afficher 8.0+

# Vérifier KVM (optionnel pour MicroVM natif)
lscpu | grep Virtualization
```

**✅ Tout est prêt !** Codespaces inclut Docker, .NET, Python, Git.

### 2.3 Démarrer le Monitoring

```bash
# Lancer Prometheus + Grafana + cAdvisor
cd /workspaces/Optivolt-automation
bash start-monitoring.sh

# Attendre 20 secondes
sleep 20

# Vérifier les containers
docker ps | grep optivolt
```

**Résultat attendu :** 4-6 containers actifs (prometheus, grafana, cadvisor, node-exporter)

---

## 🔨 Étape 3 : Compiler OptiVoltCLI (2 minutes)

```bash
# Compiler le CLI
cd /workspaces/Optivolt-automation/OptiVoltCLI
dotnet publish -c Release -o ../publish

# Vérifier
cd /workspaces/Optivolt-automation
./publish/OptiVoltCLI --version
```

---

## 🚀 Étape 4 : Premier Benchmark (1 minute)

```bash
# Lancer un benchmark de 60 secondes
cd /workspaces/Optivolt-automation
bash scripts/run_real_benchmark.sh 60
```

**Pendant l'exécution :**
- Métriques collectées en temps réel
- Résultats dans `results/comparison.json`
- Dashboards Grafana mis à jour

---

## 📊 Étape 5 : Visualiser dans Grafana

### Accès à Grafana

1. **VS Code** → Onglet **PORTS** (panneau bas)
2. Trouver la ligne **3000** (Grafana)
3. Cliquer sur l'icône **🌐** (globe)
4. **Login :** `admin` / `admin`

### Navigation

1. Menu **☰** → **Dashboards** → **Browse**
2. Sélectionner **"OptiVolt - Docker vs MicroVM vs Unikernel"**

**Vous verrez :**
- 📈 CPU temps réel par environnement
- 💾 Mémoire par container
- 📊 Stats individuelles
- 📋 Tableau comparatif

📖 **Guide détaillé :** [../GRAFANA_CODESPACES_ACCESS.md](../GRAFANA_CODESPACES_ACCESS.md)

---

## 🔧 Configuration Avancée

### Personnaliser la Configuration

Éditer `config/hosts.json` :

```json
{
  "environments": {
    "docker": {
      "hostname": "localhost",
      "port": 22,
      "username": "codespace",
      "privateKeyPath": "/home/codespace/.ssh/id_rsa",
      "workingDirectory": "/workspaces/Optivolt-automation"
    }
  }
}
```

### Installer des Outils Supplémentaires

```bash
# jq pour traiter JSON
sudo apt install -y jq

# htop pour monitoring système
sudo apt install -y htop

# Vérifier Firecracker (pour MicroVM natif)
wget https://github.com/firecracker-microvm/firecracker/releases/download/v1.13.1/firecracker-v1.13.1-x86_64.tgz
tar -xzf firecracker-v1.13.1-x86_64.tgz
sudo mv release-v1.13.1-x86_64/firecracker-v1.13.1-x86_64 /usr/local/bin/firecracker
sudo chmod +x /usr/local/bin/firecracker
```

---

## 🐛 Dépannage

### Problème : Docker ne démarre pas

```bash
# Vérifier le service
sudo systemctl status docker

# Redémarrer si nécessaire
sudo systemctl restart docker
```

### Problème : Ports non accessibles

```bash
# Vérifier que les containers tournent
docker ps

# Redémarrer le monitoring
docker-compose -f docker-compose-monitoring.yml down
bash start-monitoring.sh
```

### Problème : .NET CLI introuvable

```bash
# Installer manuellement
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0

# Ajouter au PATH
echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
source ~/.bashrc
```

### Problème : Permissions Docker

```bash
# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER

# Recharger les groupes
newgrp docker

# Tester
docker ps
```

---

## 💡 Conseils d'Utilisation

### Sauvegarder vos Changements

```bash
# Commit réguliers
git add .
git commit -m "Update: description des changements"
git push
```

### Arrêter/Redémarrer un Codespace

- **Pause automatique :** Après 30 min d'inactivité
- **Arrêt manuel :** GitHub → Codespaces → `...` → Stop
- **Redémarrage :** GitHub → Codespaces → Cliquer sur votre Codespace

### Gérer les Ressources

```bash
# Voir l'utilisation actuelle
htop

# Nettoyer Docker
docker system prune -a

# Voir l'espace disque
df -h
```

---

## 📚 Ressources

### Documentation Essentielle

| Document | Description |
|----------|-------------|
| [../README.md](../README.md) | Documentation principale |
| [../QUICKSTART_CODESPACES.md](../QUICKSTART_CODESPACES.md) | Démarrage rapide |
| [../GRAFANA_CODESPACES_ACCESS.md](../GRAFANA_CODESPACES_ACCESS.md) | Guide Grafana complet |
| [../GUIDE_TESTS_REELS.md](../GUIDE_TESTS_REELS.md) | Tests et benchmarks |

### Liens Externes

- [GitHub Codespaces Docs](https://docs.github.com/en/codespaces)
- [Docker Docs](https://docs.docker.com/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)

---

## ✅ Checklist de Configuration

- [ ] Codespace créé et démarré
- [ ] Docker fonctionnel (`docker ps`)
- [ ] .NET SDK installé (`dotnet --version`)
- [ ] Monitoring lancé (`docker ps | grep optivolt`)
- [ ] OptiVoltCLI compilé (`./publish/OptiVoltCLI --version`)
- [ ] Premier benchmark exécuté
- [ ] Grafana accessible (port 3000)
- [ ] Dashboards visibles

---

**🎉 Configuration Terminée !**

Votre environnement Codespaces est prêt pour les benchmarks OptiVolt.

**Prochaine étape :** Consulter [../QUICKSTART_CODESPACES.md](../QUICKSTART_CODESPACES.md) pour les commandes essentielles.


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
