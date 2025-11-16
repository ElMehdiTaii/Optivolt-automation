#!/bin/bash

#######################################################################
# Script de Lancement VRAIE MicroVM Firecracker avec KVM
#######################################################################
# Ce script crée et lance une VRAIE MicroVM Firecracker utilisant KVM
# pour des tests réels d'optimisation énergétique
#######################################################################

set -e

WORK_DIR="/tmp/optivolt-firecracker"
KERNEL_URL="https://s3.amazonaws.com/spec.ccfc.min/img/quickstart_guide/x86_64/kernels/vmlinux.bin"
KERNEL_FALLBACK="https://github.com/firecracker-microvm/firecracker/releases/download/v1.4.0/vmlinux.bin"
ROOTFS_SIZE_MB=200
MICROVM_MEM_MB=128
MICROVM_VCPUS=1

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  OptiVolt - Lancement VRAIE MicroVM Firecracker + KVM       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

#######################################################################
# Étape 1 : Vérifications
#######################################################################
echo "🔍 Étape 1/7 : Vérifications système"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vérifier KVM
if [ ! -c /dev/kvm ]; then
    echo "❌ Erreur: /dev/kvm non disponible"
    echo "   KVM est requis pour Firecracker"
    exit 1
fi
echo "✅ KVM disponible: /dev/kvm"

# Vérifier permissions KVM
if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
    echo "⚠️  Permissions KVM insuffisantes, correction..."
    sudo chmod 666 /dev/kvm
fi
echo "✅ Permissions KVM: OK"

# Vérifier Firecracker
if ! command -v firecracker &> /dev/null; then
    echo "❌ Erreur: firecracker non trouvé"
    echo "   Installation: sudo ln -s /workspaces/Optivolt-automation/release-v1.13.1-x86_64/firecracker-* /usr/local/bin/firecracker"
    exit 1
fi
echo "✅ Firecracker: $(which firecracker)"
firecracker --version 2>&1 | head -1

#######################################################################
# Étape 2 : Préparation répertoire de travail
#######################################################################
echo ""
echo "📁 Étape 2/7 : Préparation environnement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
echo "✅ Répertoire: $WORK_DIR"

#######################################################################
# Étape 3 : Téléchargement kernel Linux minimal
#######################################################################
echo ""
echo "⬇️  Étape 3/7 : Téléchargement kernel Linux minimal"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "vmlinux.bin" ]; then
    echo "Téléchargement depuis AWS S3..."
    if ! curl -fsSL -o vmlinux.bin "$KERNEL_URL"; then
        echo "⚠️  Échec AWS S3, tentative GitHub..."
        curl -fsSL -o vmlinux.bin "$KERNEL_FALLBACK"
    fi
    echo "✅ Kernel téléchargé: $(du -h vmlinux.bin | cut -f1)"
else
    echo "✅ Kernel déjà présent: $(du -h vmlinux.bin | cut -f1)"
fi

#######################################################################
# Étape 4 : Création rootfs Alpine Linux
#######################################################################
echo ""
echo "📦 Étape 4/7 : Création rootfs Alpine Linux"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "rootfs.ext4" ]; then
    echo "Création image ext4 de ${ROOTFS_SIZE_MB}MB..."
    dd if=/dev/zero of=rootfs.ext4 bs=1M count=$ROOTFS_SIZE_MB status=progress
    mkfs.ext4 -F rootfs.ext4
    
    echo "Montage et installation Alpine..."
    mkdir -p /tmp/rootfs-mount
    sudo mount rootfs.ext4 /tmp/rootfs-mount
    
    # Télécharger Alpine minirootfs
    ALPINE_VERSION="3.18"
    ALPINE_ARCH="x86_64"
    ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/alpine-minirootfs-${ALPINE_VERSION}.0-${ALPINE_ARCH}.tar.gz"
    
    echo "Téléchargement Alpine minirootfs..."
    curl -fsSL "$ALPINE_URL" | sudo tar -xz -C /tmp/rootfs-mount
    
    # Configuration système minimal
    sudo tee /tmp/rootfs-mount/etc/inittab > /dev/null << 'INITTAB_EOF'
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default
tty1::respawn:/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/openrc shutdown
INITTAB_EOF

    # Script de workload CPU
    sudo tee /tmp/rootfs-mount/usr/local/bin/workload.sh > /dev/null << 'WORKLOAD_EOF'
#!/bin/sh
echo "OptiVolt MicroVM - Workload CPU démarré"
while true; do
    # Calcul Monte Carlo simple
    for i in $(seq 1 1000); do
        awk 'BEGIN { x=rand(); y=rand(); if(x*x+y*y<1) print 1; else print 0 }' > /dev/null
    done
    sleep 1
done
WORKLOAD_EOF

    sudo chmod +x /tmp/rootfs-mount/usr/local/bin/workload.sh
    
    # Script d'init
    sudo tee /tmp/rootfs-mount/sbin/init > /dev/null << 'INIT_EOF'
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
hostname optivolt-microvm
ip link set dev eth0 up
ip addr add 172.16.0.2/24 dev eth0 || true
echo "OptiVolt Firecracker MicroVM démarrée (KVM)"
/usr/local/bin/workload.sh &
exec /bin/sh
INIT_EOF

    sudo chmod +x /tmp/rootfs-mount/sbin/init
    
    sudo umount /tmp/rootfs-mount
    echo "✅ Rootfs créé: $(du -h rootfs.ext4 | cut -f1)"
else
    echo "✅ Rootfs déjà présent: $(du -h rootfs.ext4 | cut -f1)"
fi

#######################################################################
# Étape 5 : Configuration Firecracker
#######################################################################
echo ""
echo "⚙️  Étape 5/7 : Configuration Firecracker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > firecracker-config.json << CONFIG_EOF
{
  "boot-source": {
    "kernel_image_path": "$WORK_DIR/vmlinux.bin",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off init=/sbin/init"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "$WORK_DIR/rootfs.ext4",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "machine-config": {
    "vcpu_count": $MICROVM_VCPUS,
    "mem_size_mib": $MICROVM_MEM_MB,
    "ht_enabled": false
  },
  "logger": {
    "log_path": "$WORK_DIR/firecracker.log",
    "level": "Info",
    "show_level": true,
    "show_log_origin": false
  },
  "metrics": {
    "metrics_path": "$WORK_DIR/firecracker-metrics.json"
  }
}
CONFIG_EOF

echo "✅ Configuration créée: firecracker-config.json"
echo "   • vCPUs: $MICROVM_VCPUS"
echo "   • RAM: ${MICROVM_MEM_MB} MB"
echo "   • Kernel: vmlinux.bin"
echo "   • Rootfs: rootfs.ext4"

#######################################################################
# Étape 6 : Lancement MicroVM
#######################################################################
echo ""
echo "🚀 Étape 6/7 : Lancement MicroVM Firecracker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Nettoyer anciennes instances
pkill -9 firecracker 2>/dev/null || true
rm -f firecracker.socket

echo "Démarrage Firecracker avec KVM..."
echo "Commande: firecracker --api-sock firecracker.socket --config-file firecracker-config.json"
echo ""
echo "⚠️  La MicroVM va démarrer en arrière-plan"
echo "   Socket API: $WORK_DIR/firecracker.socket"
echo "   Logs: $WORK_DIR/firecracker.log"
echo "   Métriques: $WORK_DIR/firecracker-metrics.json"
echo ""

# Lancer en background
nohup firecracker --api-sock firecracker.socket \
    --config-file firecracker-config.json \
    > firecracker-stdout.log 2>&1 &

FIRECRACKER_PID=$!
echo "✅ Firecracker lancé (PID: $FIRECRACKER_PID)"

# Attendre démarrage
echo "Attente démarrage MicroVM (5 secondes)..."
sleep 5

# Vérifier si le processus tourne
if ps -p $FIRECRACKER_PID > /dev/null; then
    echo "✅ MicroVM opérationnelle !"
else
    echo "❌ Erreur: MicroVM n'a pas démarré"
    echo "Logs:"
    cat firecracker-stdout.log
    exit 1
fi

#######################################################################
# Étape 7 : Statistiques et monitoring
#######################################################################
echo ""
echo "📊 Étape 7/7 : Informations MicroVM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Process Firecracker:"
ps aux | grep firecracker | grep -v grep || echo "  Aucun process trouvé"
echo ""
echo "Fichiers créés:"
ls -lh "$WORK_DIR" | grep -E '(vmlinux|rootfs|config|socket)'
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 MicroVM Firecracker lancée avec succès !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Commandes utiles:"
echo ""
echo "Voir logs temps réel:"
echo "  tail -f $WORK_DIR/firecracker.log"
echo ""
echo "Voir métriques:"
echo "  cat $WORK_DIR/firecracker-metrics.json | jq ."
echo ""
echo "Arrêter MicroVM:"
echo "  pkill -9 firecracker"
echo ""
echo "Comparer avec Docker:"
echo "  docker stats optivolt-docker optivolt-microvm"
echo "  # vs process Firecracker (PID: $FIRECRACKER_PID)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 La MicroVM tourne maintenant en arrière-plan avec KVM"
echo "   Isolation hardware réelle, boot time <125ms"
echo "   Workload CPU actif pour comparaison avec Docker"
echo ""
echo "📊 Dashboard Grafana: http://localhost:3000/d/optivolt-unified"
echo "   (Note: Firecracker non visible dans cAdvisor, utiliser métriques JSON)"
echo ""
