# 🚀 Configuration Oracle Cloud Free Tier pour OptivoltCLI

## Pourquoi Oracle Cloud ?

✅ **2 VMs Ampere gratuites À VIE** (4 OCPUs, 24 GB RAM au total)  
✅ **KVM natif inclus** - Firecracker et OSv fonctionneront directement  
✅ **Toujours gratuit** - Pas de limite de temps  
✅ **200 GB de stockage bloc** gratuit  
✅ **10 TB de transfert** par mois gratuit  

## 📋 Prérequis

- Une carte de crédit (pour vérification, **aucun débit**)
- Un email valide
- 30-45 minutes pour la configuration complète

---

## Étape 1 : Créer un compte Oracle Cloud (10 min)

### 1.1 Inscription

1. Aller sur https://www.oracle.com/cloud/free/
2. Cliquer sur **"Start for free"**
3. Remplir le formulaire :
   - **Email** : Votre email
   - **Country/Territory** : Choisir votre pays
   - Cliquer sur **"Verify my email"**

4. Vérifier votre email et cliquer sur le lien de confirmation

5. Compléter les informations :
   - **Account Name** : Choisir un nom unique (ex: `optivolt-tests`)
   - **Home Region** : Choisir la région la plus proche
     - Europe : `France Central (Paris)` ou `Germany Central (Frankfurt)`
     - Amérique : `US East (Ashburn)`
   
   ⚠️ **IMPORTANT** : La région ne peut pas être changée après !

6. Informations personnelles :
   - Nom, prénom, adresse
   - **Carte de crédit** (pour vérification uniquement)
   
   ⚠️ Oracle vérifie avec ~1€ puis annule immédiatement

7. Accepter les conditions et cliquer sur **"Start my free trial"**

### 1.2 Attendre la validation

- Délai : 5-15 minutes généralement
- Vous recevrez un email de confirmation
- Connexion : https://cloud.oracle.com/

---

## Étape 2 : Créer une VM avec KVM (15 min)

### 2.1 Accéder à la console

1. Se connecter sur https://cloud.oracle.com/
2. Aller dans le menu ☰ (hamburger) en haut à gauche
3. **Compute** → **Instances**
4. Cliquer sur **"Create Instance"**

### 2.2 Configuration de la VM

#### Nom et compartiment
```
Name: optivolt-test-vm
Compartment: (root) - par défaut
```

#### Placement
```
Availability Domain: Laisser par défaut
```

#### Image et Shape

**Image** :
1. Cliquer sur **"Change Image"**
2. Sélectionner **"Canonical Ubuntu"**
3. Version : **Ubuntu 22.04**
4. Cliquer sur **"Select Image"**

**Shape** :
1. Cliquer sur **"Change Shape"**
2. Sélectionner **"Ampere"** (ARM64)
3. **VM.Standard.A1.Flex**
   - **OCPUs** : 2 (ajuster le slider)
   - **Memory** : 12 GB (ajuster le slider)
4. Cliquer sur **"Select Shape"**

⚠️ **Conseil** : Commencez avec 2 OCPUs / 12 GB, vous pouvez créer une 2ème VM plus tard

#### Networking

```
Virtual Cloud Network (VCN): Créer automatiquement (par défaut)
Subnet: Public subnet (par défaut)
☑ Assign a public IPv4 address
```

#### Add SSH Keys

**Option 1 - Générer automatiquement (Recommandé)** :
```
○ Generate a key pair for me
```
- Cliquer sur **"Save Private Key"** → Sauvegarder `ssh-key-*.key`
- Cliquer sur **"Save Public Key"** → Sauvegarder `ssh-key-*.key.pub`

**Option 2 - Utiliser votre clé existante** :
```
○ Upload public key files (.pub)
```
- Uploader votre fichier `~/.ssh/id_rsa.pub`

#### Boot Volume
```
Laisser les paramètres par défaut (50 GB)
```

### 2.3 Créer la VM

1. Cliquer sur **"Create"**
2. Attendre 2-3 minutes
3. État devient **"RUNNING" (vert)**
4. **Noter l'IP publique** affichée

---

## Étape 3 : Configurer l'accès SSH (5 min)

### 3.1 Ouvrir les ports dans Oracle Cloud

1. Dans la page de l'instance, section **"Instance Details"**
2. Cliquer sur le **VCN Name** (lien bleu)
3. Dans la section **"Subnets"**, cliquer sur le subnet public
4. Dans **"Security Lists"**, cliquer sur **"Default Security List"**
5. Cliquer sur **"Add Ingress Rules"**

Ajouter ces règles :

**Règle 1 - SSH** :
```
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 22
Description: SSH access
```

**Règle 2 - Grafana** :
```
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 3000
Description: Grafana
```

**Règle 3 - Prometheus** :
```
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 9090
Description: Prometheus
```

6. Cliquer sur **"Add Ingress Rules"** pour chaque règle

### 3.2 Configurer le firewall sur la VM

Depuis votre machine locale (VirtualBox ou autre) :

```bash
# Se connecter à la VM Oracle (remplacer par votre IP)
ssh -i ssh-key-*.key ubuntu@<IP_PUBLIQUE_ORACLE>

# Une fois connecté sur la VM Oracle :
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 3000 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9090 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9100 -j ACCEPT
sudo netfilter-persistent save
```

---

## Étape 4 : Installer le projet OptivoltCLI (10 min)

### 4.1 Vérifier KVM

```bash
# Sur la VM Oracle
sudo apt update
sudo apt install -y cpu-checker
sudo kvm-ok
```

✅ Résultat attendu : **"KVM acceleration can be used"**

### 4.2 Installer les dépendances

```bash
# Git
sudo apt install -y git

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
newgrp docker

# .NET 8.0 (si vous voulez compiler le CLI)
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0
echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> ~/.bashrc
source ~/.bashrc
```

### 4.3 Cloner le projet

```bash
cd ~
git clone <URL_DE_VOTRE_REPO_GIT> optivolt-automation
# OU transférer depuis votre machine locale :
```

**Depuis votre machine locale (VirtualBox)** :
```bash
# Compresser le projet
cd /home/ubuntu
tar czf optivolt-automation.tar.gz optivolt-automation/

# Transférer vers Oracle Cloud (remplacer par votre IP)
scp -i ssh-key-*.key optivolt-automation.tar.gz ubuntu@<IP_ORACLE>:~

# Sur la VM Oracle
cd ~
tar xzf optivolt-automation.tar.gz
cd optivolt-automation
```

### 4.4 Installer Firecracker et OSv

```bash
cd ~/optivolt-automation
bash scripts/setup_local_vms.sh
```

Ce script installe :
- QEMU/KVM
- Firecracker v1.5.0
- OSv avec Capstan
- Configure `config/hosts.json`

---

## Étape 5 : Exécuter les tests (5 min)

### 5.1 Test rapide

```bash
cd ~/optivolt-automation
bash scripts/test_local_setup.sh
```

✅ Vérifications :
- Docker : OK
- Firecracker : OK
- OSv/Capstan : OK
- Monitoring stack : OK

### 5.2 Benchmark complet

```bash
cd ~/optivolt-automation
bash scripts/run_full_benchmark.sh
```

Durée : ~10 minutes

Résultats dans :
- `results/docker_results.json`
- `results/microvm_results.json`
- `results/unikernel_results.json`

---

## Étape 6 : Visualiser dans Grafana

### 6.1 Accès Grafana

Depuis votre navigateur local (sur Windows) :

```
http://<IP_PUBLIQUE_ORACLE>:3000
```

**Identifiants** :
- Username : `admin`
- Password : `optivolt2025`

### 6.2 Dashboards disponibles

1. **OptiVolt Performance Comparison**
   - Comparaison Docker vs MicroVM vs Unikernel
   - CPU, RAM, temps démarrage
   - Graphiques en temps réel

2. **Node Exporter Full**
   - Métriques système détaillées
   - CPU, disque, réseau, mémoire

3. **Docker Container Stats**
   - Métriques des conteneurs
   - cAdvisor integration

---

## Étape 7 : Utiliser OptivoltCLI (depuis local)

### 7.1 Configurer hosts.json

Sur votre machine **locale** (VirtualBox), éditer `config/hosts.json` :

```json
{
  "hosts": {
    "oracle-docker": {
      "hostname": "oracle-docker",
      "ip": "<IP_PUBLIQUE_ORACLE>",
      "port": 22,
      "username": "ubuntu",
      "privateKeyPath": "/home/ubuntu/.ssh/id_rsa",
      "workdir": "/home/ubuntu/optivolt-automation",
      "environment": "docker"
    },
    "oracle-microvm": {
      "hostname": "oracle-microvm",
      "ip": "<IP_PUBLIQUE_ORACLE>",
      "port": 22,
      "username": "ubuntu",
      "privateKeyPath": "/home/ubuntu/.ssh/id_rsa",
      "workdir": "/home/ubuntu/optivolt-automation",
      "environment": "microvm"
    },
    "oracle-unikernel": {
      "hostname": "oracle-unikernel",
      "ip": "<IP_PUBLIQUE_ORACLE>",
      "port": 22,
      "username": "ubuntu",
      "privateKeyPath": "/home/ubuntu/.ssh/id_rsa",
      "workdir": "/home/ubuntu/optivolt-automation",
      "environment": "unikernel"
    }
  }
}
```

### 7.2 Copier la clé SSH Oracle

```bash
# Sur votre machine locale
cp /path/to/ssh-key-*.key ~/.ssh/oracle_cloud_key
chmod 600 ~/.ssh/oracle_cloud_key

# Modifier hosts.json pour pointer vers cette clé
"privateKeyPath": "/home/ubuntu/.ssh/oracle_cloud_key"
```

### 7.3 Tester le CLI

```bash
cd /home/ubuntu/optivolt-automation

# Deploy sur Oracle Cloud
./publish/OptiVoltCLI deploy --host oracle-docker

# Run tests
./publish/OptiVoltCLI test --host oracle-docker --duration 60

# Collect metrics
./publish/OptiVoltCLI collect --host oracle-docker --output results/oracle_docker.json
```

---

## 🎯 Architecture finale

```
┌─────────────────────────────────────────────────────────┐
│  Votre machine locale (VirtualBox Ubuntu)               │
│  ┌────────────────────────────────────────────┐         │
│  │  OptivoltCLI                               │         │
│  │  - Envoie commandes SSH                    │         │
│  │  - Collecte résultats                      │         │
│  └────────────────┬───────────────────────────┘         │
│                   │ SSH                                  │
└───────────────────┼──────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  Oracle Cloud VM (IP publique)                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐        │
│  │  Docker    │  │ Firecracker│  │    OSv     │        │
│  │  Container │  │  MicroVM   │  │  Unikernel │        │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘        │
│        │               │               │                │
│        └───────────────┴───────────────┘                │
│                        │                                │
│              ┌─────────▼──────────┐                     │
│              │  Monitoring Stack  │                     │
│              │  - Grafana :3000   │                     │
│              │  - Prometheus :9090│                     │
│              │  - Node Exporter   │                     │
│              │  - Scaphandre      │                     │
│              └────────────────────┘                     │
└─────────────────────────────────────────────────────────┘
         │
         │ HTTP :3000, :9090
         ▼
┌─────────────────────────────────────────────────────────┐
│  Votre navigateur (Windows)                             │
│  http://<IP_ORACLE>:3000 → Grafana Dashboards          │
└─────────────────────────────────────────────────────────┘
```

---

## 💰 Gestion des coûts

### Always Free Resources (inclus à vie)

✅ **2 VMs Ampere** :
- VM.Standard.A1.Flex
- Jusqu'à 4 OCPUs total
- Jusqu'à 24 GB RAM total
- Exemple : 2 VMs × (2 OCPU, 12 GB RAM)

✅ **Stockage** :
- 200 GB Block Volume
- 10 GB Object Storage

✅ **Réseau** :
- 10 TB sortant/mois
- VCN gratuit

### Comment éviter les frais

❌ **Ne PAS utiliser** :
- VMs x86 (payantes après trial)
- Plus de 4 OCPUs Ampere total
- Plus de 24 GB RAM Ampere total
- Load Balancers

✅ **Rester dans le Free Tier** :
- Utiliser uniquement Ampere shapes
- Maximum 2 VMs avec total ≤ 4 OCPU, ≤ 24 GB RAM
- Surveiller l'onglet "Cost Analysis"

---

## 🔧 Dépannage

### Problème : Impossible de créer une VM Ampere

**Erreur** : "Out of capacity for shape VM.Standard.A1.Flex"

**Solution** :
1. Essayer une autre Availability Domain
2. Essayer à différents moments (capacité limitée)
3. Créer une VM avec moins de ressources (1 OCPU, 6 GB)
4. Essayer une autre région (attention : définitif !)

### Problème : SSH connexion timeout

**Vérifications** :
1. Security List → Port 22 ouvert ?
2. Instance → État = RUNNING ?
3. Clé SSH correcte ?
4. `ssh -vvv` pour debug

### Problème : Grafana inaccessible

**Vérifications** :
1. Security List → Port 3000 ouvert ?
2. iptables configuré ?
   ```bash
   sudo iptables -L -n | grep 3000
   ```
3. Container Grafana démarré ?
   ```bash
   docker ps | grep grafana
   ```

### Problème : KVM non disponible malgré Oracle Cloud

**Solution** :
```bash
# Vérifier les modules kernel
lsmod | grep kvm

# Si absent, charger manuellement
sudo modprobe kvm
sudo modprobe kvm_intel  # ou kvm_amd selon CPU
```

---

## 📚 Ressources

- **Oracle Cloud Free Tier** : https://www.oracle.com/cloud/free/
- **Documentation Oracle** : https://docs.oracle.com/en-us/iaas/
- **Firecracker** : https://firecracker-microvm.github.io/
- **OSv** : http://osv.io/
- **Forum support** : https://cloudcustomerconnect.oracle.com/

---

## ✅ Checklist finale

- [ ] Compte Oracle Cloud créé
- [ ] VM Ampere créée (2 OCPU, 12 GB RAM)
- [ ] IP publique notée
- [ ] SSH fonctionnel
- [ ] KVM vérifié avec `sudo kvm-ok`
- [ ] Projet cloné/transféré
- [ ] Docker installé
- [ ] Firecracker installé
- [ ] OSv/Capstan installé
- [ ] Monitoring stack démarré
- [ ] Grafana accessible sur :3000
- [ ] Tests exécutés avec succès
- [ ] Résultats visualisés dans Grafana

---

## 🚀 Prochaines étapes

Une fois tout configuré :

1. **Exécuter le benchmark complet**
   ```bash
   bash scripts/run_full_benchmark.sh
   ```

2. **Analyser les résultats dans Grafana**
   - Ouvrir http://<IP_ORACLE>:3000
   - Dashboard "OptiVolt Performance Comparison"

3. **Générer le rapport final**
   ```bash
   python3 scripts/generate_final_dashboard.py
   ```

4. **Exporter les résultats**
   ```bash
   # Télécharger sur votre machine locale
   scp -i ssh-key-*.key ubuntu@<IP_ORACLE>:~/optivolt-automation/results/*.json ~/
   ```

---

**Besoin d'aide ?** Signalez tout problème rencontré !
