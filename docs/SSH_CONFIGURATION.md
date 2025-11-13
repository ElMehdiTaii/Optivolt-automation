# 🔐 Configuration SSH pour GitLab CI - OptiVolt

## 🎯 Objectif

Configurer SSH dans GitLab CI pour permettre aux jobs `deploy:docker`, `deploy:microvm`, et `deploy:unikernel` de se connecter aux machines distantes.

---

## ⚠️ **Important : C'est Optionnel !**

Votre pipeline actuel a `allow_failure: true` pour tous les jobs de déploiement. Cela signifie :

- ✅ **Sans SSH** : Le pipeline réussit, les jobs deploy échouent mais ne bloquent pas
- ✅ **Avec SSH** : Le pipeline réussit ET les déploiements fonctionnent réellement

**Si vous voulez juste tester l'intégration Scaphandre, vous n'avez PAS besoin de configurer SSH.**

---

## 📋 **Étape 1 : Générer une Paire de Clés SSH**

### Sur votre machine locale :

```bash
# Générer une nouvelle paire de clés dédiée à GitLab CI
ssh-keygen -t ed25519 -C "gitlab-ci-optivolt" -f ~/.ssh/gitlab_ci_optivolt

# Appuyez sur Entrée pour ne pas mettre de passphrase (important pour CI/CD)
# Enter passphrase (empty for no passphrase): [Entrée]
# Enter same passphrase again: [Entrée]
```

**Résultat :**
```
~/.ssh/gitlab_ci_optivolt      ← Clé PRIVÉE (à garder secrète)
~/.ssh/gitlab_ci_optivolt.pub  ← Clé PUBLIQUE (à copier sur les serveurs)
```

---

## 📤 **Étape 2 : Déployer la Clé Publique sur les Serveurs**

### Option A : Avec ssh-copy-id (Recommandé)

```bash
# Pour localhost (si nécessaire)
ssh-copy-id -i ~/.ssh/gitlab_ci_optivolt.pub root@localhost

# Pour MicroVM
ssh-copy-id -i ~/.ssh/gitlab_ci_optivolt.pub optivolt@192.168.1.101

# Pour Unikernel
ssh-copy-id -i ~/.ssh/gitlab_ci_optivolt.pub optivolt@192.168.1.102
```

### Option B : Manuellement

```bash
# Afficher la clé publique
cat ~/.ssh/gitlab_ci_optivolt.pub

# Copier le résultat, puis se connecter à chaque serveur et faire :
ssh optivolt@192.168.1.101
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "VOTRE_CLE_PUBLIQUE_ICI" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

### Vérifier que ça fonctionne :

```bash
# Tester la connexion
ssh -i ~/.ssh/gitlab_ci_optivolt root@localhost
ssh -i ~/.ssh/gitlab_ci_optivolt optivolt@192.168.1.101
ssh -i ~/.ssh/gitlab_ci_optivolt optivolt@192.168.1.102

# Si ça fonctionne sans demander de mot de passe, c'est bon !
```

---

## 🔑 **Étape 3 : Récupérer la Clé Privée**

```bash
# Afficher la clé privée
cat ~/.ssh/gitlab_ci_optivolt
```

**Copiez TOUT le contenu**, depuis `-----BEGIN OPENSSH PRIVATE KEY-----` jusqu'à `-----END OPENSSH PRIVATE KEY-----` inclus.

Exemple :
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBXj8jN6vH3qM+xK9fP2JQRLkYzX4V9TnN8K2PnW7QxZQAAAJBr7Q5Ma+0O
... [plusieurs lignes]
-----END OPENSSH PRIVATE KEY-----
```

---

## 🌐 **Étape 4 : Générer SSH_KNOWN_HOSTS**

```bash
# Créer un fichier temporaire
ssh-keyscan localhost > /tmp/known_hosts_gitlab
ssh-keyscan 192.168.1.101 >> /tmp/known_hosts_gitlab
ssh-keyscan 192.168.1.102 >> /tmp/known_hosts_gitlab

# Afficher le contenu
cat /tmp/known_hosts_gitlab
```

**Copiez tout le contenu.**

Exemple :
```
localhost ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC...
192.168.1.101 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC...
192.168.1.102 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC...
```

---

## 🎮 **Étape 5 : Ajouter les Variables dans GitLab**

### 1. Aller sur GitLab

Ouvrez votre navigateur et allez sur :
```
https://gitlab.com/mehdi_taii/optivolt/-/settings/ci_cd
```

### 2. Section "Variables"

Cliquez sur **"Expand"** dans la section **Variables**.

### 3. Ajouter `SSH_PRIVATE_KEY`

Cliquez sur **"Add variable"** :

| Champ | Valeur |
|-------|--------|
| **Key** | `SSH_PRIVATE_KEY` |
| **Value** | Collez le contenu de `~/.ssh/gitlab_ci_optivolt` (incluant BEGIN/END) |
| **Type** | Variable |
| **Environments** | All (default) |
| **Protect variable** | ☑ Coché (si vous ne poussez que sur main) |
| **Mask variable** | ☐ Décoché (les clés SSH ne peuvent pas être masquées) |
| **Expand variable reference** | ☐ Décoché |

Cliquez sur **"Add variable"**.

### 4. Ajouter `SSH_KNOWN_HOSTS`

Cliquez à nouveau sur **"Add variable"** :

| Champ | Valeur |
|-------|--------|
| **Key** | `SSH_KNOWN_HOSTS` |
| **Value** | Collez le contenu de `/tmp/known_hosts_gitlab` |
| **Type** | Variable |
| **Environments** | All (default) |
| **Protect variable** | ☐ Décoché |
| **Mask variable** | ☐ Décoché |
| **Expand variable reference** | ☐ Décoché |

Cliquez sur **"Add variable"**.

---

## ✅ **Étape 6 : Vérifier la Configuration**

### Dans GitLab CI/CD Variables, vous devriez voir :

```
┌────────────────────────┬────────────────────────┬──────────────┐
│ Key                    │ Environments           │ Flags        │
├────────────────────────┼────────────────────────┼──────────────┤
│ SSH_PRIVATE_KEY        │ All (default)          │ Protected    │
│ SSH_KNOWN_HOSTS        │ All (default)          │              │
└────────────────────────┴────────────────────────┴──────────────┘
```

---

## 🚀 **Étape 7 : Tester le Pipeline**

### Pousser votre code :

```bash
cd /home/ubuntu/optivolt-automation
git add .
git commit -m "feat: Integrate Scaphandre + SSH configured"
git push origin main
```

### Vérifier le pipeline :

1. Allez sur : `https://gitlab.com/mehdi_taii/optivolt/-/pipelines`
2. Cliquez sur le pipeline en cours
3. Vérifiez que les jobs `deploy:*` réussissent maintenant

---

## 🐛 **Troubleshooting**

### **Erreur : "Permission denied (publickey)"**

**Cause :** La clé publique n'est pas dans `authorized_keys` du serveur.

**Solution :**
```bash
# Vérifier sur le serveur distant
ssh optivolt@192.168.1.101
cat ~/.ssh/authorized_keys | grep gitlab-ci-optivolt
# Si absent, refaire l'étape 2
```

### **Erreur : "Host key verification failed"**

**Cause :** `SSH_KNOWN_HOSTS` est incorrect ou manquant.

**Solution :**
```bash
# Regénérer SSH_KNOWN_HOSTS
ssh-keyscan 192.168.1.101 192.168.1.102 localhost > /tmp/known_hosts_new
cat /tmp/known_hosts_new
# Mettre à jour la variable dans GitLab
```

### **Erreur : "Load key: invalid format"**

**Cause :** La clé privée n'a pas été copiée correctement (manque BEGIN/END ou retours à la ligne).

**Solution :**
```bash
# Afficher avec les caractères spéciaux
cat -A ~/.ssh/gitlab_ci_optivolt
# Vérifier qu'il n'y a pas de ^M (retours Windows)
# Recopier exactement dans GitLab
```

### **Le job deploy échoue toujours**

**Cause :** Vérifier que le serveur cible est accessible depuis GitLab CI.

**Note :** Si vos serveurs sont sur un réseau local (192.168.x.x), GitLab.com (cloud) ne pourra pas les atteindre ! Dans ce cas, vous devez :
- Utiliser un GitLab Runner auto-hébergé sur votre réseau local
- OU utiliser un VPN/Tunnel
- OU exposer vos serveurs publiquement (déconseillé)

---

## 🏠 **Alternative : GitLab Runner Local**

Si vos serveurs sont sur un réseau privé (192.168.x.x), la meilleure solution est d'installer un **GitLab Runner** sur votre réseau local.

### Installation rapide :

```bash
# Sur une machine de votre réseau local
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner

# Enregistrer le runner
sudo gitlab-runner register
# URL: https://gitlab.com
# Token: Voir dans GitLab > Settings > CI/CD > Runners
# Description: local-runner
# Tags: local
# Executor: shell
```

### Modifier .gitlab-ci.yml :

```yaml
deploy:docker:
  tags:
    - local  # Au lieu de 'docker'
```

---

## 📊 **Comparaison des Options**

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| **Sans SSH** | Simple, aucune config | Les déploiements ne fonctionnent pas |
| **SSH + GitLab.com** | Pas d'infrastructure | Ne fonctionne que pour serveurs publics |
| **Runner Local** | Accès réseau local | Installation supplémentaire |

---

## 🎯 **Recommandation**

Pour **OptiVolt** :

1. **Court terme** : Laissez `allow_failure: true` et testez sans SSH
   - Scaphandre et les métriques fonctionneront
   - Les jobs deploy échoueront mais ne bloqueront pas

2. **Moyen terme** : Installez un GitLab Runner local
   - Permet l'accès aux serveurs 192.168.x.x
   - Permet de tester RAPL sur bare-metal

3. **Long terme** : Utilisez des serveurs cloud accessibles publiquement
   - Simplifie le CI/CD
   - Permet l'utilisation de GitLab.com

---

## ✅ **Validation**

Pour vérifier que SSH est correctement configuré :

```bash
# Test depuis votre machine
ssh -i ~/.ssh/gitlab_ci_optivolt optivolt@192.168.1.101 "hostname && whoami"
# Devrait afficher le hostname du serveur sans demander de mot de passe
```

---

## 📝 **Résumé des Commandes**

```bash
# 1. Générer la clé
ssh-keygen -t ed25519 -C "gitlab-ci" -f ~/.ssh/gitlab_ci_optivolt

# 2. Copier sur les serveurs
ssh-copy-id -i ~/.ssh/gitlab_ci_optivolt.pub optivolt@192.168.1.101
ssh-copy-id -i ~/.ssh/gitlab_ci_optivolt.pub optivolt@192.168.1.102

# 3. Récupérer la clé privée
cat ~/.ssh/gitlab_ci_optivolt  # Copier dans GitLab → SSH_PRIVATE_KEY

# 4. Générer known_hosts
ssh-keyscan 192.168.1.101 192.168.1.102 localhost > /tmp/known_hosts
cat /tmp/known_hosts  # Copier dans GitLab → SSH_KNOWN_HOSTS

# 5. Ajouter dans GitLab
# Aller sur : https://gitlab.com/mehdi_taii/optivolt/-/settings/ci_cd
# Variables → Add variable → SSH_PRIVATE_KEY et SSH_KNOWN_HOSTS

# 6. Pousser et tester
git push origin main
```

---

## 🔗 **Ressources**

- [GitLab CI SSH Keys](https://docs.gitlab.com/ee/ci/ssh_keys/)
- [SSH Key Authentication](https://www.ssh.com/academy/ssh/public-key-authentication)
- [GitLab Runner Installation](https://docs.gitlab.com/runner/install/)

---

**🎉 Une fois configuré, vos déploiements fonctionneront automatiquement dans GitLab CI !**
