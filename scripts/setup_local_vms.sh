#!/bin/bash
# ==============================================================================
# Script de configuration locale pour MicroVM et Unikernel sur Ubuntu/VirtualBox
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Configuration MicroVM + Unikernel Local${NC}"
echo -e "${GREEN}========================================${NC}\n"

# ==============================================================================
# 1. Vérifier la virtualisation imbriquée
# ==============================================================================
echo -e "${YELLOW}[1/5] Vérification de la virtualisation...${NC}"

if sudo kvm-ok 2>&1 | grep -q "KVM acceleration can be used"; then
    echo -e "${GREEN}✓ KVM disponible${NC}"
elif sudo kvm-ok 2>&1 | grep -q "KVM acceleration can NOT be used"; then
    echo -e "${RED}✗ Virtualisation imbriquée non activée${NC}"
    echo -e "${YELLOW}Action requise sur votre machine hôte :${NC}"
    echo -e "  VBoxManage modifyvm \"NomDeVotreVM\" --nested-hw-virt on"
    echo -e "  Puis redémarrez la VM\n"
    read -p "Continuer quand même (simulation) ? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    SIMULATION_MODE=true
else
    echo -e "${YELLOW}⚠ kvm-ok non disponible, installation...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y cpu-checker
    SIMULATION_MODE=true
fi

# ==============================================================================
# 2. Installer les outils de virtualisation
# ==============================================================================
echo -e "\n${YELLOW}[2/5] Installation des outils...${NC}"

# QEMU/KVM pour MicroVMs
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "Installation de QEMU/KVM..."
    sudo apt-get update -qq
    sudo apt-get install -y qemu-kvm qemu-system-x86 libvirt-daemon-system libvirt-clients bridge-utils virtinst
    sudo systemctl enable --now libvirtd
    sudo usermod -aG libvirt $USER
    sudo usermod -aG kvm $USER
    echo -e "${GREEN}✓ QEMU/KVM installé${NC}"
else
    echo -e "${GREEN}✓ QEMU/KVM déjà installé${NC}"
fi

# Docker pour conteneurs
if ! command -v docker &> /dev/null; then
    echo "Installation de Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Docker installé${NC}"
else
    echo -e "${GREEN}✓ Docker déjà installé${NC}"
fi

# ==============================================================================
# 3. Configurer Firecracker (MicroVM)
# ==============================================================================
echo -e "\n${YELLOW}[3/5] Configuration Firecracker...${NC}"

FIRECRACKER_VERSION="v1.5.0"
FIRECRACKER_BIN="/usr/local/bin/firecracker"

if [ ! -f "$FIRECRACKER_BIN" ]; then
    echo "Téléchargement de Firecracker ${FIRECRACKER_VERSION}..."
    curl -fsSL "https://github.com/firecracker-microvm/firecracker/releases/download/${FIRECRACKER_VERSION}/firecracker-${FIRECRACKER_VERSION}-x86_64.tgz" -o /tmp/firecracker.tgz
    tar -xzf /tmp/firecracker.tgz -C /tmp
    sudo mv /tmp/release-${FIRECRACKER_VERSION}-x86_64/firecracker-${FIRECRACKER_VERSION}-x86_64 "$FIRECRACKER_BIN"
    sudo chmod +x "$FIRECRACKER_BIN"
    rm -rf /tmp/firecracker.tgz /tmp/release-${FIRECRACKER_VERSION}-x86_64
    echo -e "${GREEN}✓ Firecracker installé${NC}"
else
    echo -e "${GREEN}✓ Firecracker déjà installé${NC}"
fi

firecracker --version

# ==============================================================================
# 4. Configurer OSv (Unikernel)
# ==============================================================================
echo -e "\n${YELLOW}[4/5] Configuration OSv Unikernel...${NC}"

# Utiliser le script existant
if [ -f "scripts/setup_local_unikernel.sh" ]; then
    bash scripts/setup_local_unikernel.sh
else
    echo -e "${YELLOW}⚠ Script setup_local_unikernel.sh non trouvé${NC}"
    echo "Installation manuelle de Capstan..."
    
    if ! command -v capstan &> /dev/null; then
        curl -fsSL https://raw.githubusercontent.com/cloudius-systems/capstan/master/scripts/download | bash
        export PATH="$HOME/.capstan/bin:$PATH"
        echo 'export PATH="$HOME/.capstan/bin:$PATH"' >> ~/.bashrc
        echo -e "${GREEN}✓ Capstan installé${NC}"
    else
        echo -e "${GREEN}✓ Capstan déjà installé${NC}"
    fi
fi

# ==============================================================================
# 5. Mettre à jour la configuration hosts.json
# ==============================================================================
echo -e "\n${YELLOW}[5/5] Configuration hosts.json...${NC}"

cat > config/hosts.json <<EOF
{
  "environments": {
    "docker": {
      "hostname": "localhost",
      "port": 22,
      "username": "$(whoami)",
      "privateKeyPath": "~/.ssh/id_ed25519",
      "workingDirectory": "$(pwd)"
    },
    "microvm": {
      "hostname": "localhost",
      "port": 22,
      "username": "$(whoami)",
      "privateKeyPath": "~/.ssh/id_ed25519",
      "workingDirectory": "$(pwd)",
      "type": "firecracker"
    },
    "unikernel": {
      "hostname": "localhost",
      "port": 22,
      "username": "$(whoami)",
      "privateKeyPath": "~/.ssh/id_ed25519",
      "workingDirectory": "$(pwd)",
      "type": "osv"
    }
  }
}
EOF

echo -e "${GREEN}✓ Configuration mise à jour${NC}"

# ==============================================================================
# Résumé
# ==============================================================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Configuration terminée !${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo "Environnements disponibles :"
echo "  • Docker    : Conteneur standard"
echo "  • MicroVM   : Firecracker (localhost)"
echo "  • Unikernel : OSv avec Capstan (localhost)"
echo ""
echo "Commandes de test :"
echo "  cd publish/"
echo "  ./OptiVoltCLI deploy --environment docker"
echo "  ./OptiVoltCLI deploy --environment microvm"
echo "  ./OptiVoltCLI deploy --environment unikernel"
echo ""

if [ "$SIMULATION_MODE" = true ]; then
    echo -e "${YELLOW}⚠ Mode simulation activé (KVM non disponible)${NC}"
    echo -e "${YELLOW}Pour activer KVM : VBoxManage modifyvm VM --nested-hw-virt on${NC}\n"
fi

echo -e "${GREEN}Prêt pour les benchmarks ! 🚀${NC}\n"
