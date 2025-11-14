# Guide de Configuration Unikernel Local

## Option 1 : Unikraft + QEMU (Recommandé)

### Installation Unikraft

```bash
# Dépendances
sudo apt-get update
sudo apt-get install -y build-essential libncurses-dev libyaml-dev flex \
  git wget socat bison unzip uuid-runtime qemu-kvm qemu-system-x86 \
  gcc-aarch64-linux-gnu libguestfs-tools python3-pip

# Installer Kraft CLI
pip3 install --user kraft

# Vérifier l'installation
kraft --version
```

### Créer un Unikernel de Test

```bash
# Créer un projet simple
mkdir ~/unikernel-test
cd ~/unikernel-test

# Initialiser avec Kraft
kraft init -t helloworld

# Compiler l'unikernel
kraft build

# Lancer l'unikernel avec QEMU
kraft run --network bridge --ip 192.168.1.102
```

### Configuration Réseau

```bash
# Créer un bridge réseau
sudo ip link add br0 type bridge
sudo ip addr add 192.168.1.1/24 dev br0
sudo ip link set br0 up

# Configurer le forwarding
sudo sysctl -w net.ipv4.ip_forward=1
```

## Option 2 : VM Alpine Linux (Simulation Légère)

Si vous voulez tester rapidement sans Unikraft :

```bash
# Télécharger Alpine Linux (très léger, ~50MB)
wget https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-virt-3.18.0-x86_64.iso

# Créer un disque virtuel
qemu-img create -f qcow2 alpine-unikernel.qcow2 2G

# Lancer la VM
qemu-system-x86_64 \
  -m 512 \
  -cdrom alpine-virt-3.18.0-x86_64.iso \
  -hda alpine-unikernel.qcow2 \
  -net nic -net user,hostfwd=tcp::2222-:22 \
  -nographic
```

### Configuration Alpine

```bash
# Dans la VM Alpine
setup-alpine

# Installer SSH
apk add openssh
rc-update add sshd
/etc/init.d/sshd start

# Créer l'utilisateur optivolt
adduser optivolt
adduser optivolt wheel
```

## Option 3 : Container Privilegié (Pour Tests Rapides)

```bash
# Créer un container qui simule un unikernel
docker run -d --name unikernel-test \
  --network bridge \
  --privileged \
  -p 2223:22 \
  alpine:latest \
  /bin/sh -c "apk add openssh && \
              ssh-keygen -A && \
              adduser -D optivolt && \
              echo 'optivolt:optivolt' | chpasswd && \
              /usr/sbin/sshd -D"
```

## Configuration pour OptiVolt

### hosts.json

```json
{
  "hosts": {
    "unikernel": {
      "hostname": "unikernel-test",
      "ip": "localhost",
      "user": "optivolt",
      "port": 2223,
      "workdir": "/home/optivolt/optivolt-tests"
    }
  }
}
```

## Vérification

```bash
# Tester la connexion SSH
ssh -p 2223 optivolt@localhost

# Depuis OptiVoltCLI
dotnet OptiVoltCLI.dll deploy --environment unikernel
dotnet OptiVoltCLI.dll test --environment unikernel --type cpu
```

## Métriques avec Scaphandre

```bash
# Installer Scaphandre dans l'environnement unikernel
ssh -p 2223 optivolt@localhost

# Sur Alpine
apk add wget
wget https://github.com/hubblo-org/scaphandre/releases/download/v0.5.0/scaphandre-x86_64-musl
chmod +x scaphandre-x86_64-musl
sudo ./scaphandre-x86_64-musl prometheus --port 8080
```

## Troubleshooting

### Problème : QEMU ne démarre pas
```bash
# Vérifier KVM
ls -la /dev/kvm
sudo usermod -aG kvm $USER
```

### Problème : Connexion SSH refusée
```bash
# Vérifier le service SSH
systemctl status sshd

# Tester la connexion
ssh -vvv -p 2223 optivolt@localhost
```

### Problème : Bridge réseau
```bash
# Vérifier les bridges
ip link show type bridge

# Réinitialiser
sudo ip link delete br0
```
