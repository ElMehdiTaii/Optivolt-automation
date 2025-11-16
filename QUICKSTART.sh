#!/bin/bash
# ==============================================================================
# Quick Start - OptiVolt sur Ubuntu VirtualBox
# ==============================================================================

cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║         OptiVolt - Démarrage Rapide (5 minutes)          ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

🚀 ACTIONS À FAIRE :

1️⃣  Sur votre MACHINE HÔTE (VM éteinte) :
   
    VBoxManage modifyvm "Ubuntu" --nested-hw-virt on
    
    (ou via GUI : VM → Config → Système → Processeur → ☑ VT-x imbriqué)


2️⃣  Dans la VM Ubuntu (après redémarrage) :
   
    bash scripts/setup_local_vms.sh


3️⃣  Lancer un test rapide :
   
    bash scripts/test_local_setup.sh


4️⃣  Benchmark complet :
   
    bash scripts/run_full_benchmark.sh


📖 Documentation complète :
   
   docs/LOCAL_VM_SETUP.md
   docs/VIRTUALBOX_SETUP_SUMMARY.txt


❓ Besoin d'aide ?
   
   cat docs/VIRTUALBOX_SETUP_SUMMARY.txt

EOF

read -p "Appuyez sur Entrée pour voir le guide complet..." -r
cat docs/VIRTUALBOX_SETUP_SUMMARY.txt
