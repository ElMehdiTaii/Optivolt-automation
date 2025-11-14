#!/bin/bash

echo "========================================="
echo "  Installation de Scaphandre"
echo "========================================="

# Variables
SCAPHANDRE_VERSION="0.5.0"
INSTALL_DIR="/usr/local/bin"

# Détecter l'architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    BINARY_URL="https://github.com/hubblo-org/scaphandre/releases/download/v${SCAPHANDRE_VERSION}/scaphandre-v${SCAPHANDRE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
elif [ "$ARCH" = "aarch64" ]; then
    BINARY_URL="https://github.com/hubblo-org/scaphandre/releases/download/v${SCAPHANDRE_VERSION}/scaphandre-v${SCAPHANDRE_VERSION}-aarch64-unknown-linux-musl.tar.gz"
else
    echo "❌ Architecture non supportée: $ARCH"
    exit 1
fi

echo "📥 Téléchargement de Scaphandre ${SCAPHANDRE_VERSION}..."
cd /tmp
wget -q "$BINARY_URL" -O scaphandre.tar.gz

if [ $? -eq 0 ]; then
    echo "📦 Extraction..."
    tar -xzf scaphandre.tar.gz
    
    echo "📁 Installation dans $INSTALL_DIR..."
    sudo mv scaphandre "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/scaphandre"
    
    echo "🧹 Nettoyage..."
    rm -f scaphandre.tar.gz
    
    echo "✅ Scaphandre installé avec succès!"
    scaphandre --version
else
    echo "❌ Échec du téléchargement"
    exit 1
fi

# Vérifier les permissions pour RAPL
echo ""
echo "🔍 Vérification des permissions RAPL..."
if [ -d "/sys/class/powercap/intel-rapl" ]; then
    echo "✅ RAPL détecté"
    sudo chmod -R 755 /sys/class/powercap/intel-rapl/ 2>/dev/null || true
else
    echo "⚠️  RAPL non disponible (normal dans une VM)"
    echo "   Scaphandre fonctionnera en mode estimation"
fi

echo ""
echo "========================================="
echo "✅ Installation terminée!"
echo "========================================="
echo ""
echo "Utilisation:"
echo "  # Mode Prometheus"
echo "  scaphandre prometheus --port 8080"
echo ""
echo "  # Mode JSON"
echo "  scaphandre json --max-top-consumers 5"
echo ""
