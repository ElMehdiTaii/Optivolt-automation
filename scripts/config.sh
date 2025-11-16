#!/bin/bash
# Configuration centralisée pour tous les scripts OptiVolt

# Grafana Configuration
export GRAFANA_URL="http://localhost:3000"
export GRAFANA_USER="admin"
export GRAFANA_PASSWORD="optivolt2025"
export GRAFANA_DATASOURCE_UID="PBFA97CFB590B2093"
export GRAFANA_DASHBOARD_UID="optivolt-final"

# Prometheus Configuration
export PROMETHEUS_URL="http://localhost:9090"

# cAdvisor Configuration
export CADVISOR_URL="http://localhost:8081"

# Container Names
export CONTAINER_DOCKER_STANDARD="optivolt-docker"
export CONTAINER_DOCKER_MICROVM="optivolt-microvm"
export CONTAINER_DOCKER_MINIMAL="optivolt-unikernel"

# Container Images
export IMAGE_DOCKER_STANDARD="python:3.11-slim"
export IMAGE_DOCKER_MICROVM="python:3.11-alpine"
export IMAGE_DOCKER_MINIMAL="alpine:3.18"

# Unikraft Benchmark Values (from 2h+ tests)
export UNIKRAFT_CPU_AVG="5"
export UNIKRAFT_RAM_AVG="20"

# Optimization Metrics (static benchmarks)
export OPTIMIZATION_CPU="57"
export OPTIMIZATION_RAM="97.7"
export OPTIMIZATION_CO2="61.2"
export OPTIMIZATION_COST="30.61"

# Colors for output
export COLOR_GREEN="\033[0;32m"
export COLOR_YELLOW="\033[1;33m"
export COLOR_RED="\033[0;31m"
export COLOR_BLUE="\033[0;34m"
export COLOR_RESET="\033[0m"

# Helper functions
log_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

log_info() {
    echo -e "${COLOR_BLUE}→ $1${COLOR_RESET}"
}

log_warning() {
    echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
}

# Check if required tools are installed
check_dependencies() {
    local deps=("curl" "jq" "docker")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Check if Grafana is accessible
check_grafana() {
    if curl -s -f -u "$GRAFANA_USER:$GRAFANA_PASSWORD" "$GRAFANA_URL/api/health" &> /dev/null; then
        log_success "Grafana is accessible"
        return 0
    else
        log_error "Grafana is not accessible at $GRAFANA_URL"
        return 1
    fi
}

# Check if Prometheus is accessible
check_prometheus() {
    if curl -s -f "$PROMETHEUS_URL/-/healthy" &> /dev/null; then
        log_success "Prometheus is accessible"
        return 0
    else
        log_error "Prometheus is not accessible at $PROMETHEUS_URL"
        return 1
    fi
}

# Check if containers are running
check_containers() {
    local containers=("$CONTAINER_DOCKER_STANDARD" "$CONTAINER_DOCKER_MICROVM" "$CONTAINER_DOCKER_MINIMAL")
    local missing=()
    
    for container in "${containers[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            missing+=("$container")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_warning "Containers not running: ${missing[*]}"
        return 1
    fi
    
    log_success "All containers are running"
    return 0
}
