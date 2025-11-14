# 🚀 Guide Rapide: Déploiement Unikernel avec Unikraft

## Installation Express (Ubuntu 20.04+)

```bash
# 1. Installer les dépendances
sudo apt-get update
sudo apt-get install -y build-essential libncurses-dev libyaml-dev \
  flex git wget socat bison unzip uuid-runtime \
  qemu-kvm qemu-system-x86 python3-pip

# 2. Installer Kraft CLI
pip3 install --user kraft
export PATH="$HOME/.local/bin:$PATH"

# 3. Vérifier l'installation
kraft --version
```

## Créer votre premier Unikernel

### Application Hello World

```bash
# Créer un projet
mkdir ~/my-unikernel && cd ~/my-unikernel

# Initialiser avec un template
kraft init -t helloworld

# Structure générée:
#   Kraftfile        - Configuration
#   main.c           - Code source
#   Makefile         - Build

# Compiler l'unikernel
kraft build

# Lancer avec QEMU
kraft run
```

### Application HTTP Serveur

```bash
# Créer un serveur HTTP
kraft init -t httpreply

# Éditer le Kraftfile pour configurer le réseau
cat > Kraftfile << 'EOF'
specification: v0.6

unikraft:
  version: stable
  kconfig:
    - CONFIG_LIBUKNETDEV=y
    - CONFIG_LWIP=y

targets:
  - architecture: x86_64
    platform: kvm

libraries:
  lwip:
    version: stable

EOF

# Compiler
kraft build

# Lancer avec réseau
kraft run --network bridge --ip 192.168.1.102
```

## Intégration avec OptiVolt

### 1. Configurer le réseau

```bash
# Créer un bridge
sudo ip link add br0 type bridge
sudo ip addr add 192.168.1.1/24 dev br0
sudo ip link set br0 up
sudo sysctl -w net.ipv4.ip_forward=1

# NAT pour internet
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### 2. Lancer l'unikernel

```bash
# Avec kraft
kraft run --network bridge --ip 192.168.1.102 -p 22:22

# Ou avec QEMU directement
qemu-system-x86_64 \
  -kernel build/unikernel_kvm-x86_64 \
  -nographic \
  -m 512M \
  -netdev bridge,id=net0,br=br0 \
  -device virtio-net-pci,netdev=net0
```

### 3. Tester avec OptiVoltCLI

```bash
# Mettre à jour config/hosts.json
{
  "unikernel": {
    "hostname": "my-unikernel",
    "ip": "192.168.1.102",
    "user": "root",
    "port": 22,
    "workdir": "/tmp"
  }
}

# Déployer
dotnet OptiVoltCLI.dll deploy --environment unikernel

# Tester
dotnet OptiVoltCLI.dll test --environment unikernel --type cpu
```

## Applications Réelles

### Node.js sur Unikraft

```bash
# Utiliser le template Node.js
kraft init -t node

# Ajouter votre app
cat > server.js << 'EOF'
const http = require('http');
http.createServer((req, res) => {
  res.writeHead(200);
  res.end('Hello from Unikernel!\n');
}).listen(8080);
EOF

# Compiler et lancer
kraft build && kraft run -p 8080:8080
```

### Python Flask

```bash
kraft init -t python3

# Ajouter Flask
cat > app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from Python Unikernel!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

kraft build && kraft run -p 5000:5000
```

## Performance Tuning

### Optimisations CPU

```yaml
# Dans Kraftfile
unikraft:
  kconfig:
    - CONFIG_OPTIMIZE_SIZE=n
    - CONFIG_OPTIMIZE_PERF=y
    - CONFIG_LIBUKALLOCPOOL=y
```

### Optimisations Mémoire

```yaml
unikraft:
  kconfig:
    - CONFIG_LIBUKALLOC_IFMALLOC=y
    - CONFIG_LIBUKALLOC_IFMALLOC_MAXSIZE=4194304
```

### Optimisations Réseau

```yaml
unikraft:
  kconfig:
    - CONFIG_LWIP_NETIF_EXT_STATUS_CALLBACK=y
    - CONFIG_LWIP_NUM_NETIF_CLIENT_DATA=2
```

## Monitoring & Debug

### Logs

```bash
# Activer les logs détaillés
kraft run --log-level debug

# Logs dans QEMU
kraft run -- --debug
```

### Profiling

```bash
# Activer le profiling
kraft build --kconfig CONFIG_LIBUKDEBUG_PRINTD=y

# Mesurer les performances
kraft run -- --stats
```

## Troubleshooting

### Problème: Kernel Panic

```bash
# Vérifier la config
kraft configure --menuconfig

# Rebuild complet
kraft clean && kraft build
```

### Problème: Réseau ne fonctionne pas

```bash
# Vérifier le bridge
ip link show br0

# Vérifier les permissions
sudo chmod 666 /dev/net/tun
```

### Problème: Performance faible

```bash
# Activer KVM
sudo modprobe kvm-intel  # ou kvm-amd

# Vérifier
lsmod | grep kvm
ls -la /dev/kvm
```

## Ressources

- **Documentation**: https://unikraft.org/docs/
- **GitHub**: https://github.com/unikraft/unikraft
- **Forum**: https://github.com/unikraft/unikraft/discussions
- **Examples**: https://github.com/unikraft/app-examples

## Prochaines Étapes

1. **Créer votre application** - Adapter votre code existant
2. **Optimiser** - Tuning des paramètres selon vos besoins
3. **Benchmarker** - Comparer avec Docker/VM via OptiVolt
4. **Production** - Déployer avec orchestration (KubeVirt, Firecracker)

---

💡 **Astuce**: Commencez simple avec le container Docker (déjà configuré), puis migrez progressivement vers un vrai unikernel Unikraft.
