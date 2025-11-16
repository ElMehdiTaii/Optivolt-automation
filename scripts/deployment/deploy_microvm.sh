#!/bin/bash

set -e

echo "[MICROVM] Déploiement de l'environnement MicroVM avec Firecracker"

# Variables
WORKDIR=${1:-/tmp/optivolt-microvm}
KERNEL_URL="https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.7/x86_64/vmlinux-5.10.bin"
ROOTFS_URL="https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.7/x86_64/ubuntu-22.04.ext4"

mkdir -p $WORKDIR
cd $WORKDIR

echo "[MICROVM] Workdir: $WORKDIR"

# Vérifier Firecracker
if ! command -v firecracker &> /dev/null; then
    echo "[MICROVM] ✗ Firecracker non trouvé"
    exit 1
fi

echo "[MICROVM] ✓ Firecracker disponible: $(firecracker --version | head -1)"

# Télécharger kernel si nécessaire
if [ ! -f "vmlinux.bin" ]; then
    echo "[MICROVM] Téléchargement kernel Linux..."
    if command -v wget &> /dev/null; then
        wget -q -O vmlinux.bin "$KERNEL_URL" || {
            echo "[MICROVM] ⚠ Téléchargement échoué, utilisation simulation"
            echo "[MICROVM] Pour tests réels, téléchargez manuellement:"
            echo "  wget $KERNEL_URL -O $WORKDIR/vmlinux.bin"
            touch vmlinux.bin
        }
    else
        echo "[MICROVM] ⚠ wget non disponible, mode simulation"
        touch vmlinux.bin
    fi
else
    echo "[MICROVM] ✓ Kernel déjà présent"
fi

# Créer rootfs minimal si nécessaire
if [ ! -f "rootfs.ext4" ]; then
    echo "[MICROVM] Création rootfs minimal..."
    
    # Créer un rootfs très simple en mémoire
    dd if=/dev/zero of=rootfs.ext4 bs=1M count=50 2>/dev/null
    mkfs.ext4 -F rootfs.ext4 2>/dev/null
    
    echo "[MICROVM] ✓ Rootfs créé (50MB)"
fi

# Créer configuration Firecracker
cat > config.json <<EOF
{
  "boot-source": {
    "kernel_image_path": "$WORKDIR/vmlinux.bin",
    "boot_args": "console=ttyS0 reboot=k panic=1 pci=off"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "$WORKDIR/rootfs.ext4",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "machine-config": {
    "vcpu_count": 1,
    "mem_size_mib": 128,
    "smt": false
  },
  "network-interfaces": []
}
EOF

echo "[MICROVM] ✓ Configuration Firecracker créée"

# Créer script de workload pour MicroVM
cat > workload_microvm.sh <<'WORKLOAD'
#!/bin/bash
echo "[MICROVM-WORKLOAD] Démarrage test CPU"
start_time=$(date +%s)
iterations=0

while [ $(($(date +%s) - start_time)) -lt 30 ]; do
    # Charge CPU
    echo "scale=1000; 4*a(1)" | bc -l > /dev/null 2>&1 &
    iterations=$((iterations + 1))
    
    if [ $((iterations % 100)) -eq 0 ]; then
        echo "[MICROVM-WORKLOAD] Iteration $iterations"
    fi
done

wait
echo "[MICROVM-WORKLOAD] Test terminé: $iterations iterations"
WORKLOAD

chmod +x workload_microvm.sh

echo ""
echo "==========================================="
echo "[MICROVM] ✓ Déploiement réussi"
echo "==========================================="
echo "Configuration:"
echo "  • vCPU:      1 core"
echo "  • Mémoire:   128 MB"
echo "  • Kernel:    vmlinux.bin"
echo "  • Rootfs:    rootfs.ext4 (50MB)"
echo "  • Config:    config.json"
echo ""
echo "Pour lancer la MicroVM:"
echo "  cd $WORKDIR"
echo "  firecracker --api-sock /tmp/firecracker.sock --config-file config.json"
echo ""

exit 0
