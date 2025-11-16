#!/bin/bash

# ==============================================================================
# Script Automatisé de Création de VRAIES MicroVMs Firecracker
# OptiVolt - Micro-virtualisation KVM
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/workspaces/Optivolt-automation"
FIRECRACKER_BIN="$PROJECT_ROOT/release-v1.13.1-x86_64/firecracker-v1.13.1-x86_64"
WORKDIR="$PROJECT_ROOT/microvms"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  OptiVolt - Création VRAIES MicroVMs Firecracker            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# Vérifications Préalables
# ==============================================================================

echo -e "${YELLOW}🔍 Vérifications préalables...${NC}"

# Vérifier KVM
if [ ! -c /dev/kvm ]; then
    echo -e "${RED}❌ /dev/kvm non disponible${NC}"
    exit 1
fi
echo -e "${GREEN}✅ KVM disponible${NC}"

# Vérifier permissions KVM
if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
    echo -e "${YELLOW}⚠️  Permissions KVM insuffisantes, ajustement...${NC}"
    sudo chmod 666 /dev/kvm
fi
echo -e "${GREEN}✅ Permissions KVM OK${NC}"

# Vérifier Firecracker
if [ ! -f "$FIRECRACKER_BIN" ]; then
    echo -e "${RED}❌ Firecracker binaire introuvable: $FIRECRACKER_BIN${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Firecracker binaire trouvé${NC}"

# Créer répertoire de travail
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ==============================================================================
# Téléchargement du Kernel Linux Minimal
# ==============================================================================

echo ""
echo -e "${YELLOW}📦 Téléchargement du kernel Linux minimal...${NC}"

KERNEL_URL="https://s3.amazonaws.com/spec.ccfc.min/img/quickstart_guide/x86_64/kernels/vmlinux.bin"
KERNEL_FILE="$WORKDIR/vmlinux.bin"

if [ ! -f "$KERNEL_FILE" ]; then
    echo -e "${BLUE}Téléchargement depuis AWS S3...${NC}"
    curl -fsSL "$KERNEL_URL" -o "$KERNEL_FILE" 2>/dev/null || {
        echo -e "${RED}❌ Échec du téléchargement du kernel${NC}"
        echo -e "${YELLOW}URL alternative...${NC}"
        # Alternative: kernel depuis GitHub
        curl -fsSL "https://github.com/firecracker-microvm/firecracker/raw/main/resources/kernel/vmlinux-4.20.0" \
            -o "$KERNEL_FILE" 2>/dev/null || {
            echo -e "${RED}❌ Impossible de télécharger le kernel${NC}"
            exit 1
        }
    }
    echo -e "${GREEN}✅ Kernel téléchargé ($(du -h "$KERNEL_FILE" | cut -f1))${NC}"
else
    echo -e "${GREEN}✅ Kernel déjà présent${NC}"
fi

# ==============================================================================
# Création du Rootfs (Alpine Linux)
# ==============================================================================

echo ""
echo -e "${YELLOW}📦 Création du rootfs Alpine Linux...${NC}"

ROOTFS_FILE="$WORKDIR/rootfs.ext4"
ROOTFS_SIZE_MB=50

if [ ! -f "$ROOTFS_FILE" ]; then
    echo -e "${BLUE}Création d'un rootfs ext4 de ${ROOTFS_SIZE_MB}MB...${NC}"
    
    # Créer une image disque vide
    dd if=/dev/zero of="$ROOTFS_FILE" bs=1M count=$ROOTFS_SIZE_MB 2>/dev/null
    
    # Créer un système de fichiers ext4
    mkfs.ext4 -F "$ROOTFS_FILE" >/dev/null 2>&1
    
    # Monter le rootfs
    MOUNT_DIR="$WORKDIR/rootfs_mount"
    mkdir -p "$MOUNT_DIR"
    sudo mount -o loop "$ROOTFS_FILE" "$MOUNT_DIR"
    
    # Créer la structure minimale
    echo -e "${BLUE}Installation Alpine Linux minimal...${NC}"
    
    # Télécharger Alpine minirootfs
    ALPINE_VERSION="3.18"
    ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/x86_64/alpine-minirootfs-${ALPINE_VERSION}.0-x86_64.tar.gz"
    
    curl -fsSL "$ALPINE_URL" | sudo tar -xz -C "$MOUNT_DIR" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Téléchargement Alpine échoué, création manuelle...${NC}"
        # Créer structure minimale manuelle
        sudo mkdir -p "$MOUNT_DIR"/{bin,dev,etc,proc,sys,tmp,usr/bin,var}
        echo "#!/bin/sh" | sudo tee "$MOUNT_DIR/init" >/dev/null
        echo "mount -t proc none /proc" | sudo tee -a "$MOUNT_DIR/init" >/dev/null
        echo "mount -t sysfs none /sys" | sudo tee -a "$MOUNT_DIR/init" >/dev/null
        echo "echo 'MicroVM Alpine Started'" | sudo tee -a "$MOUNT_DIR/init" >/dev/null
        echo "exec /bin/sh" | sudo tee -a "$MOUNT_DIR/init" >/dev/null
        sudo chmod +x "$MOUNT_DIR/init"
    }
    
    # Créer script de démarrage
    cat | sudo tee "$MOUNT_DIR/startup.sh" >/dev/null << 'SCRIPT'
#!/bin/sh
echo "🚀 [FIRECRACKER MICROVM] Démarrage..."
echo "[MICROVM] Alpine Linux $(cat /etc/alpine-release 2>/dev/null || echo 'minimal')"
echo "[MICROVM] Kernel: $(uname -r)"
echo "[MICROVM] RAM: $(free -m | awk '/Mem:/ {print $2}') MB"

# Boucle infinie avec charge CPU légère
iteration=0
while true; do
    i=0
    while [ $i -lt 5000 ]; do
        result=$((i * i))
        i=$((i + 1))
    done
    iteration=$((iteration + 1))
    if [ $((iteration % 50)) -eq 0 ]; then
        echo "[MICROVM-FIRECRACKER] $iteration itérations | CPU: Optimisé"
    fi
    sleep 1
done
SCRIPT
    
    sudo chmod +x "$MOUNT_DIR/startup.sh"
    
    # Démonter
    sudo umount "$MOUNT_DIR"
    rmdir "$MOUNT_DIR"
    
    echo -e "${GREEN}✅ Rootfs créé (${ROOTFS_SIZE_MB}MB)${NC}"
else
    echo -e "${GREEN}✅ Rootfs déjà présent${NC}"
fi

# ==============================================================================
# Création de la Configuration Firecracker
# ==============================================================================

echo ""
echo -e "${YELLOW}⚙️  Création de la configuration Firecracker...${NC}"

CONFIG_FILE="$WORKDIR/microvm-config.json"

cat > "$CONFIG_FILE" << EOF
{
  "boot-source": {
    "kernel_image_path": "${KERNEL_FILE}",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "${ROOTFS_FILE}",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "machine-config": {
    "vcpu_count": 1,
    "mem_size_mib": 128,
    "ht_enabled": false
  },
  "logger": {
    "log_path": "${WORKDIR}/firecracker.log",
    "level": "Info",
    "show_level": true,
    "show_log_origin": false
  }
}
EOF

echo -e "${GREEN}✅ Configuration Firecracker créée${NC}"

# ==============================================================================
# Script de Lancement de la MicroVM
# ==============================================================================

echo ""
echo -e "${YELLOW}🚀 Création du script de lancement...${NC}"

LAUNCH_SCRIPT="$WORKDIR/launch-microvm.sh"

cat > "$LAUNCH_SCRIPT" << 'EOF'
#!/bin/bash

WORKDIR="/workspaces/Optivolt-automation/microvms"
FIRECRACKER_BIN="/workspaces/Optivolt-automation/release-v1.13.1-x86_64/firecracker-v1.13.1-x86_64"
CONFIG_FILE="$WORKDIR/microvm-config.json"
SOCKET_PATH="$WORKDIR/firecracker.socket"

# Nettoyer le socket précédent
rm -f "$SOCKET_PATH"

echo "🚀 Lancement MicroVM Firecracker..."
echo "   Kernel: $WORKDIR/vmlinux.bin"
echo "   Rootfs: $WORKDIR/rootfs.ext4"
echo "   Config: $CONFIG_FILE"
echo ""

# Lancer Firecracker
sudo "$FIRECRACKER_BIN" \
    --api-sock "$SOCKET_PATH" \
    --config-file "$CONFIG_FILE"
EOF

chmod +x "$LAUNCH_SCRIPT"

echo -e "${GREEN}✅ Script de lancement créé : $LAUNCH_SCRIPT${NC}"

# ==============================================================================
# Résumé et Instructions
# ==============================================================================

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✅ VRAIE MicroVM Firecracker Prête !                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📦 Fichiers créés :${NC}"
echo -e "  • Kernel     : $KERNEL_FILE ($(du -h "$KERNEL_FILE" 2>/dev/null | cut -f1 || echo 'N/A'))"
echo -e "  • Rootfs     : $ROOTFS_FILE (${ROOTFS_SIZE_MB}MB)"
echo -e "  • Config     : $CONFIG_FILE"
echo -e "  • Launcher   : $LAUNCH_SCRIPT"
echo ""
echo -e "${GREEN}⚙️  Configuration MicroVM :${NC}"
echo -e "  • vCPUs      : 1"
echo -e "  • RAM        : 128 MB"
echo -e "  • Disk       : ${ROOTFS_SIZE_MB} MB (ext4)"
echo -e "  • OS         : Alpine Linux 3.18"
echo ""
echo -e "${YELLOW}🚀 Pour lancer la MicroVM :${NC}"
echo -e "  bash $LAUNCH_SCRIPT"
echo ""
echo -e "${YELLOW}📊 Différences vs Containers Docker :${NC}"
echo -e "  ✅ Isolation matérielle (KVM hypervisor)"
echo -e "  ✅ Boot time <125ms (vs ~1s Docker)"
echo -e "  ✅ Overhead minimal (~5MB vs ~100MB Docker)"
echo -e "  ✅ Sécurité maximale (VM complète)"
echo ""
echo -e "${BLUE}📚 Documentation :${NC}"
echo -e "  • Firecracker : https://firecracker-microvm.github.io"
echo -e "  • AWS Lambda utilise cette technologie"
echo -e "  • Boot time record: 125ms (8MB RAM)"
echo ""
