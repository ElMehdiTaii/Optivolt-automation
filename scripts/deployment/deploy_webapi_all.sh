#!/bin/bash
set -e

# =============================================================================
# OptiVolt - Deploy and Test Web API
# Déploie l'API web sur Docker (3 variantes), MicroVM et Unikraft
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"

WEB_API_DIR="/workspaces/Optivolt-automation/web_api"
API_PORT=8000

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           OptiVolt - Web API Deployment                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# =============================================================================
# 1. BUILD DOCKER IMAGES
# =============================================================================
build_docker_images() {
    log_step "Building Docker images..."
    cd "$WEB_API_DIR"
    
    # Build standard variant
    log_step "Building standard variant..."
    docker build --target standard -t optivolt-webapi-standard:latest . || {
        log_error "Failed to build standard variant"
        return 1
    }
    log_success "Standard variant built"
    
    # Build microvm variant
    log_step "Building microvm variant..."
    docker build --target microvm -t optivolt-webapi-microvm:latest . || {
        log_error "Failed to build microvm variant"
        return 1
    }
    log_success "MicroVM variant built"
    
    # Build minimal variant
    log_step "Building minimal variant..."
    docker build --target minimal -t optivolt-webapi-minimal:latest . || {
        log_error "Failed to build minimal variant"
        return 1
    }
    log_success "Minimal variant built"
    
    log_success "All Docker images built successfully"
}

# =============================================================================
# 2. DEPLOY DOCKER CONTAINERS
# =============================================================================
deploy_docker() {
    log_step "Deploying Docker containers..."
    
    # Standard on port 8001
    log_step "Starting standard container on port 8001..."
    docker rm -f optivolt-webapi-standard 2>/dev/null || true
    docker run -d \
        --name optivolt-webapi-standard \
        --label="optivolt.type=webapi" \
        --label="optivolt.variant=standard" \
        -p 8001:8000 \
        --memory="512m" \
        --cpus="2.0" \
        optivolt-webapi-standard:latest
    log_success "Standard container started (http://localhost:8001)"
    
    # MicroVM on port 8002
    log_step "Starting microvm container on port 8002..."
    docker rm -f optivolt-webapi-microvm 2>/dev/null || true
    docker run -d \
        --name optivolt-webapi-microvm \
        --label="optivolt.type=webapi" \
        --label="optivolt.variant=microvm" \
        -p 8002:8000 \
        --memory="256m" \
        --cpus="1.0" \
        optivolt-webapi-microvm:latest
    log_success "MicroVM container started (http://localhost:8002)"
    
    # Minimal on port 8003
    log_step "Starting minimal container on port 8003..."
    docker rm -f optivolt-webapi-minimal 2>/dev/null || true
    docker run -d \
        --name optivolt-webapi-minimal \
        --label="optivolt.type=webapi" \
        --label="optivolt.variant=minimal" \
        -p 8003:8000 \
        --memory="128m" \
        --cpus="0.5" \
        optivolt-webapi-minimal:latest
    log_success "Minimal container started (http://localhost:8003)"
    
    log_success "All Docker containers deployed"
}

# =============================================================================
# 3. DEPLOY UNIKRAFT UNIKERNEL
# =============================================================================
deploy_unikraft() {
    log_step "Deploying Unikraft unikernel..."
    
    # Check if kraft is installed
    if ! command -v kraft &> /dev/null; then
        log_warning "Kraft not installed. Installing..."
        curl --proto '=https' --tlsv1.2 -sSf https://get.kraftkit.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    cd "$WEB_API_DIR"
    
    # Build unikernel
    log_step "Building unikernel with Kraft..."
    kraft build --no-cache || {
        log_warning "Kraft build failed, skipping unikernel deployment"
        return 1
    }
    
    # Stop existing unikernel
    kraft stop optivolt-webapi-unikernel 2>/dev/null || true
    kraft remove optivolt-webapi-unikernel 2>/dev/null || true
    
    # Run unikernel on port 8004
    log_step "Starting unikernel on port 8004..."
    kraft run \
        --name optivolt-webapi-unikernel \
        --port 8004:8000 \
        --memory 64M \
        . || {
        log_warning "Failed to start unikernel"
        return 1
    }
    
    log_success "Unikernel deployed (http://localhost:8004)"
}

# =============================================================================
# 4. HEALTH CHECKS
# =============================================================================
check_health() {
    log_step "Running health checks..."
    
    sleep 5  # Wait for containers to start
    
    # Check each endpoint
    for port in 8001 8002 8003; do
        if curl -s -f "http://localhost:$port/" > /dev/null 2>&1; then
            log_success "Port $port is healthy"
        else
            log_error "Port $port is not responding"
        fi
    done
    
    # Check unikernel if deployed
    if curl -s -f "http://localhost:8004/" > /dev/null 2>&1; then
        log_success "Unikernel (port 8004) is healthy"
    else
        log_warning "Unikernel (port 8004) is not responding"
    fi
}

# =============================================================================
# 5. SHOW STATUS
# =============================================================================
show_status() {
    log_step "Deployment Status:"
    echo ""
    echo -e "${GREEN}Docker Containers:${NC}"
    docker ps --filter "label=optivolt.type=webapi" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo -e "${GREEN}Endpoints:${NC}"
    echo "  Standard (Docker):  http://localhost:8001"
    echo "  MicroVM (Docker):   http://localhost:8002"
    echo "  Minimal (Docker):   http://localhost:8003"
    echo "  Unikernel (Kraft):  http://localhost:8004"
    echo ""
    
    echo -e "${GREEN}API Documentation:${NC}"
    echo "  Swagger UI:  http://localhost:8001/docs"
    echo "  ReDoc:       http://localhost:8001/redoc"
    echo ""
}

# =============================================================================
# 6. CLEANUP
# =============================================================================
cleanup() {
    log_step "Cleaning up..."
    
    # Stop Docker containers
    docker rm -f optivolt-webapi-standard 2>/dev/null || true
    docker rm -f optivolt-webapi-microvm 2>/dev/null || true
    docker rm -f optivolt-webapi-minimal 2>/dev/null || true
    
    # Stop unikernel
    kraft stop optivolt-webapi-unikernel 2>/dev/null || true
    kraft remove optivolt-webapi-unikernel 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    print_header
    
    case "${1:-deploy}" in
        deploy)
            build_docker_images
            deploy_docker
            deploy_unikraft || log_warning "Unikernel deployment skipped"
            check_health
            show_status
            ;;
        
        build)
            build_docker_images
            ;;
        
        start)
            deploy_docker
            deploy_unikraft || log_warning "Unikernel deployment skipped"
            check_health
            show_status
            ;;
        
        stop)
            cleanup
            ;;
        
        status)
            show_status
            ;;
        
        *)
            echo "Usage: $0 {deploy|build|start|stop|status}"
            echo ""
            echo "Commands:"
            echo "  deploy  - Build and deploy all variants"
            echo "  build   - Build Docker images only"
            echo "  start   - Start all containers"
            echo "  stop    - Stop and remove all containers"
            echo "  status  - Show deployment status"
            exit 1
            ;;
    esac
}

main "$@"
