#!/bin/bash

echo "========================================="
echo "  OptiVolt - Setup Local Unikernel"
echo "========================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Vérifier les prérequis
check_dependencies() {
    info "Vérification des dépendances..."
    
    local missing=()
    
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi
    
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        missing+=("qemu-system-x86_64")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        warn "Dépendances manquantes: ${missing[*]}"
        read -p "Installer les dépendances? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies
        else
            error "Impossible de continuer sans les dépendances"
            exit 1
        fi
    else
        info "✓ Toutes les dépendances sont installées"
    fi
}

install_dependencies() {
    info "Installation des dépendances..."
    sudo apt-get update
    sudo apt-get install -y docker.io qemu-system-x86 qemu-utils bridge-utils
    sudo usermod -aG docker $USER
    info "✓ Dépendances installées"
    warn "Vous devrez peut-être vous reconnecter pour que les changements prennent effet"
}

# Option 1: Container Docker simulant un unikernel
setup_docker_unikernel() {
    info "Configuration d'un container Docker comme unikernel de test..."
    
    # Arrêter et supprimer le container existant
    docker rm -f unikernel-test 2>/dev/null
    
    # Créer un Dockerfile minimal
    cat > /tmp/Dockerfile.unikernel <<EOF
FROM alpine:latest

RUN apk add --no-cache openssh bash python3 py3-pip && \\
    ssh-keygen -A && \\
    adduser -D optivolt && \\
    echo 'optivolt:optivolt' | chpasswd && \\
    mkdir -p /home/optivolt/.ssh /home/optivolt/optivolt-tests && \\
    chown -R optivolt:optivolt /home/optivolt

# Permettre la connexion SSH avec mot de passe pour les tests
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \\
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D", "-e"]
EOF

    info "Construction de l'image unikernel-test..."
    docker build -t unikernel-test:latest -f /tmp/Dockerfile.unikernel /tmp
    
    info "Démarrage du container..."
    docker run -d --name unikernel-test \
        --hostname unikernel-test \
        -p 2223:22 \
        --privileged \
        unikernel-test:latest
    
    # Attendre que SSH soit prêt
    sleep 3
    
    info "✓ Container unikernel-test démarré sur le port 2223"
    info "Connexion: ssh -p 2223 optivolt@localhost (mot de passe: optivolt)"
}

# Option 2: QEMU avec Alpine Linux
setup_qemu_unikernel() {
    info "Configuration d'une VM QEMU légère..."
    
    local VM_DIR="$HOME/unikernel-vm"
    mkdir -p "$VM_DIR"
    cd "$VM_DIR"
    
    # Télécharger Alpine si nécessaire
    if [ ! -f "alpine-virt.iso" ]; then
        info "Téléchargement d'Alpine Linux..."
        wget -O alpine-virt.iso \
            https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-virt-3.18.4-x86_64.iso
    fi
    
    # Créer le disque si nécessaire
    if [ ! -f "alpine-unikernel.qcow2" ]; then
        info "Création du disque virtuel..."
        qemu-img create -f qcow2 alpine-unikernel.qcow2 2G
    fi
    
    info "Démarrage de la VM QEMU..."
    info "Port SSH: 2224"
    info "Pour arrêter: Ctrl+A puis X"
    
    qemu-system-x86_64 \
        -m 512 \
        -hda alpine-unikernel.qcow2 \
        -cdrom alpine-virt.iso \
        -net nic -net user,hostfwd=tcp::2224-:22 \
        -nographic
}

# Configuration du fichier hosts.json
update_hosts_config() {
    local PORT=$1
    local CONFIG_FILE="config/hosts.json"
    
    info "Mise à jour de $CONFIG_FILE..."
    
    # Créer une sauvegarde
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    
    # Mettre à jour la configuration
    cat > "$CONFIG_FILE" <<EOF
{
  "hosts": {
    "docker": {
      "hostname": "localhost",
      "ip": "localhost",
      "user": "root",
      "port": 2222,
      "workdir": "/tmp/optivolt-tests"
    },
    "microvm": {
      "hostname": "microvm-test",
      "ip": "192.168.1.101",
      "user": "optivolt",
      "port": 22,
      "workdir": "/home/optivolt/optivolt-tests"
    },
    "unikernel": {
      "hostname": "unikernel-test",
      "ip": "localhost",
      "user": "optivolt",
      "port": $PORT,
      "workdir": "/home/optivolt/optivolt-tests"
    },
    "localhost": {
      "hostname": "localhost",
      "ip": "127.0.0.1",
      "user": "root",
      "port": 22,
      "workdir": "/tmp/optivolt-tests"
    }
  },
  "scripts": {
    "docker_deploy": "scripts/deploy_docker.sh",
    "microvm_deploy": "scripts/deploy_microvm.sh",
    "unikernel_deploy": "scripts/deploy_unikernel.sh"
  }
}
EOF
    
    info "✓ Configuration mise à jour (sauvegarde: $CONFIG_FILE.bak)"
}

# Test de connexion
test_connection() {
    local PORT=$1
    
    info "Test de connexion SSH..."
    
    if timeout 5 bash -c "echo > /dev/tcp/localhost/$PORT" 2>/dev/null; then
        info "✓ Port $PORT est accessible"
        
        # Tester SSH avec sshpass si disponible
        if command -v sshpass &> /dev/null; then
            if sshpass -p 'optivolt' ssh -o StrictHostKeyChecking=no -p $PORT optivolt@localhost "echo 'SSH OK'" 2>/dev/null; then
                info "✓ Connexion SSH réussie"
                return 0
            fi
        else
            warn "Installez 'sshpass' pour tester automatiquement: sudo apt-get install sshpass"
        fi
        
        info "Testez manuellement: ssh -p $PORT optivolt@localhost"
    else
        warn "Port $PORT non accessible"
    fi
}

# Menu principal
show_menu() {
    echo ""
    echo "Choisissez une option:"
    echo "  1) Container Docker (Rapide, recommandé pour les tests)"
    echo "  2) VM QEMU avec Alpine Linux (Plus proche d'un vrai unikernel)"
    echo "  3) Installer Unikraft (Vrai unikernel, avancé)"
    echo "  4) Quitter"
    echo ""
    read -p "Option [1-4]: " choice
    
    case $choice in
        1)
            check_dependencies
            setup_docker_unikernel
            update_hosts_config 2223
            test_connection 2223
            ;;
        2)
            check_dependencies
            setup_qemu_unikernel
            update_hosts_config 2224
            ;;
        3)
            info "Installation d'Unikraft..."
            info "Voir la documentation complète: docs/UNIKERNEL_SETUP.md"
            sudo apt-get install -y build-essential libncurses-dev libyaml-dev flex \
                git wget socat bison unzip uuid-runtime qemu-kvm qemu-system-x86
            pip3 install --user kraft
            info "✓ Unikraft installé. Utilisez 'kraft' pour créer des unikernels"
            ;;
        4)
            info "Au revoir!"
            exit 0
            ;;
        *)
            error "Option invalide"
            show_menu
            ;;
    esac
}

# Point d'entrée
main() {
    cd "$(dirname "$0")/.."
    
    echo "Ce script va configurer un environnement unikernel local pour OptiVolt"
    echo ""
    
    show_menu
    
    echo ""
    echo "========================================="
    info "Configuration terminée!"
    echo "========================================="
    echo ""
    echo "Prochaines étapes:"
    echo "  1. Tester la connexion SSH"
    echo "  2. Déployer avec: cd publish && dotnet OptiVoltCLI.dll deploy --environment unikernel"
    echo "  3. Lancer des tests: dotnet OptiVoltCLI.dll test --environment unikernel --type cpu"
    echo ""
}

main "$@"
