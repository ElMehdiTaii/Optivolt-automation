#!/bin/bash
#
# common.sh - Fonctions communes pour les scripts OptiVolt
#
# Usage: source scripts/common.sh
#

# ========================================
# Couleurs et Formatage
# ========================================

readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'

# ========================================
# Fonctions de Logging
# ========================================

log_info() {
  echo -e "${COLOR_BLUE}ℹ️  [INFO]${COLOR_RESET} $*"
}

log_success() {
  echo -e "${COLOR_GREEN}✅ [SUCCESS]${COLOR_RESET} $*"
}

log_warning() {
  echo -e "${COLOR_YELLOW}⚠️  [WARNING]${COLOR_RESET} $*"
}

log_error() {
  echo -e "${COLOR_RED}❌ [ERROR]${COLOR_RESET} $*" >&2
}

log_step() {
  echo -e "${COLOR_CYAN}${COLOR_BOLD}▶ $*${COLOR_RESET}"
}

log_section() {
  echo ""
  echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
  echo -e "${COLOR_BOLD}  $*${COLOR_RESET}"
  echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
  echo ""
}

# ========================================
# Vérifications de Dépendances
# ========================================

check_command() {
  local cmd=$1
  local install_hint=$2
  
  if ! command -v "$cmd" &> /dev/null; then
    log_error "$cmd n'est pas installé"
    if [ -n "$install_hint" ]; then
      log_info "Installation: $install_hint"
    fi
    return 1
  fi
  return 0
}

check_docker() {
  if ! check_command "docker" "curl -fsSL https://get.docker.com | sh"; then
    exit 1
  fi
  
  if ! docker ps &> /dev/null; then
    log_error "Docker daemon non accessible"
    log_info "Essayez: sudo systemctl start docker"
    exit 1
  fi
  
  log_success "Docker disponible (version $(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1))"
}

check_python() {
  if ! check_command "python3" "sudo apt install python3"; then
    exit 1
  fi
  log_success "Python disponible (version $(python3 --version | grep -oP '\d+\.\d+\.\d+'))"
}

check_dotnet() {
  if ! check_command "dotnet" "wget https://dot.net/v1/dotnet-install.sh && bash dotnet-install.sh"; then
    exit 1
  fi
  log_success ".NET disponible (version $(dotnet --version))"
}

# ========================================
# Gestion des Containers Docker
# ========================================

docker_stop_container() {
  local container_name=$1
  
  if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
    log_info "Arrêt du container $container_name..."
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true
    log_success "Container $container_name nettoyé"
  fi
}

docker_cleanup_network() {
  local network_name=$1
  
  if docker network ls --format '{{.Name}}' | grep -q "^${network_name}$"; then
    log_info "Suppression du réseau $network_name..."
    docker network rm "$network_name" 2>/dev/null || true
  fi
}

docker_wait_healthy() {
  local container_name=$1
  local max_wait=${2:-60}
  local interval=2
  local elapsed=0
  
  log_info "Attente que $container_name soit prêt..."
  
  while [ $elapsed -lt $max_wait ]; do
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
      log_success "$container_name est démarré"
      return 0
    fi
    sleep $interval
    elapsed=$((elapsed + interval))
  done
  
  log_error "$container_name n'a pas démarré après ${max_wait}s"
  return 1
}

# ========================================
# Gestion des Services
# ========================================

wait_for_service() {
  local service_url=$1
  local service_name=${2:-"service"}
  local max_retries=${3:-30}
  local retry_count=0
  
  log_info "Attente que $service_name soit accessible ($service_url)..."
  
  while [ $retry_count -lt $max_retries ]; do
    if curl -s -f "$service_url" > /dev/null 2>&1; then
      log_success "$service_name est prêt"
      return 0
    fi
    retry_count=$((retry_count + 1))
    sleep 2
  done
  
  log_error "$service_name n'est pas accessible après $((max_retries * 2))s"
  return 1
}

check_service_health() {
  local url=$1
  local service_name=$2
  
  if curl -s -f "$url" > /dev/null 2>&1; then
    log_success "$service_name: accessible"
    return 0
  else
    log_warning "$service_name: non accessible"
    return 1
  fi
}

# ========================================
# Gestion des Fichiers
# ========================================

create_directory() {
  local dir_path=$1
  
  if [ ! -d "$dir_path" ]; then
    mkdir -p "$dir_path"
    log_success "Répertoire créé: $dir_path"
  fi
}

backup_file() {
  local file_path=$1
  
  if [ -f "$file_path" ]; then
    local backup_path="${file_path}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$file_path" "$backup_path"
    log_info "Backup créé: $backup_path"
  fi
}

# ========================================
# Gestion des Erreurs
# ========================================

exit_on_error() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    log_error "Commande échouée avec code $exit_code"
    exit $exit_code
  fi
}

cleanup_on_exit() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    log_error "Script interrompu (code: $exit_code)"
  fi
}

trap cleanup_on_exit EXIT

# ========================================
# Utilitaires
# ========================================

get_timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

get_timestamp_filename() {
  date +"%Y%m%d_%H%M%S"
}

confirm_action() {
  local message=$1
  local default=${2:-"n"}
  
  if [ "$default" = "y" ]; then
    read -p "$message [Y/n]: " -n 1 -r
  else
    read -p "$message [y/N]: " -n 1 -r
  fi
  
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}

print_banner() {
  local title=$1
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  printf "║  %-58s  ║\n" "$title"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
}

# ========================================
# Variables d'Environnement Communes
# ========================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly RESULTS_DIR="$PROJECT_ROOT/results"
readonly CONFIG_DIR="$PROJECT_ROOT/config"

# Créer les répertoires de base
create_directory "$RESULTS_DIR"

# ========================================
# Export des fonctions
# ========================================

export -f log_info log_success log_warning log_error log_step log_section
export -f check_command check_docker check_python check_dotnet
export -f docker_stop_container docker_cleanup_network docker_wait_healthy
export -f wait_for_service check_service_health
export -f create_directory backup_file
export -f get_timestamp get_timestamp_filename confirm_action print_banner
