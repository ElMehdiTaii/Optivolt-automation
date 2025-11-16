#!/bin/bash
set -e

# =============================================================================
# OptiVolt - Web API Load Testing and Benchmarking
# Teste les performances de l'API sur les 4 plateformes
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"

# Test configuration
DURATION=60  # Duration in seconds
CONCURRENT_USERS=50
REQUESTS_PER_SECOND=100

# Endpoints to test
ENDPOINTS=(
    "/"
    "/api/light"
    "/api/heavy"
    "/api/slow"
)

# Platforms to test
declare -A PLATFORMS=(
    ["standard"]="http://localhost:8001"
    ["microvm"]="http://localhost:8002"
    ["minimal"]="http://localhost:8003"
    ["unikernel"]="http://localhost:8004"
)

RESULTS_DIR="/workspaces/Optivolt-automation/results/webapi_benchmark_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           OptiVolt - Web API Load Testing                    ║"
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

# =============================================================================
# 1. INSTALL DEPENDENCIES
# =============================================================================
install_dependencies() {
    log_step "Checking dependencies..."
    
    # Install Apache Bench (ab)
    if ! command -v ab &> /dev/null; then
        log_step "Installing Apache Bench..."
        sudo apt-get update -qq
        sudo apt-get install -y apache2-utils
    fi
    
    # Install hey (modern load testing tool)
    if ! command -v hey &> /dev/null; then
        log_step "Installing hey..."
        wget -q https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -O /tmp/hey
        sudo chmod +x /tmp/hey
        sudo mv /tmp/hey /usr/local/bin/
    fi
    
    log_success "Dependencies installed"
}

# =============================================================================
# 2. TEST SINGLE ENDPOINT
# =============================================================================
test_endpoint() {
    local platform=$1
    local endpoint=$2
    local url="${PLATFORMS[$platform]}${endpoint}"
    local output_file="$RESULTS_DIR/${platform}_${endpoint//\//_}.json"
    
    echo -n "  Testing $platform ${endpoint}... "
    
    # Check if endpoint is available
    if ! curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${RED}SKIP (not available)${NC}"
        return
    fi
    
    # Run load test with hey
    hey -z ${DURATION}s \
        -c $CONCURRENT_USERS \
        -q $REQUESTS_PER_SECOND \
        -o csv \
        "$url" > "$output_file" 2>&1
    
    # Parse results
    local total_requests=$(grep -o 'requests: [0-9]*' "$output_file" | awk '{print $2}')
    local avg_latency=$(grep -o 'Average: [0-9.]*' "$output_file" | awk '{print $2}')
    
    echo -e "${GREEN}OK${NC} (${total_requests} req, ${avg_latency}ms avg)"
}

# =============================================================================
# 3. RUN BENCHMARKS
# =============================================================================
run_benchmarks() {
    log_step "Running load tests..."
    echo ""
    
    for platform in "${!PLATFORMS[@]}"; do
        log_step "Testing $platform platform..."
        
        for endpoint in "${ENDPOINTS[@]}"; do
            test_endpoint "$platform" "$endpoint"
        done
        
        echo ""
    done
    
    log_success "Benchmarks completed"
}

# =============================================================================
# 4. COLLECT METRICS FROM PROMETHEUS
# =============================================================================
collect_metrics() {
    log_step "Collecting metrics from Prometheus..."
    
    # CPU usage
    curl -s "http://localhost:9090/api/v1/query?query=rate(container_cpu_usage_seconds_total{name=~\"optivolt-webapi.*\"}[5m])" \
        | jq '.' > "$RESULTS_DIR/cpu_metrics.json"
    
    # Memory usage
    curl -s "http://localhost:9090/api/v1/query?query=container_memory_working_set_bytes{name=~\"optivolt-webapi.*\"}" \
        | jq '.' > "$RESULTS_DIR/memory_metrics.json"
    
    # Network I/O
    curl -s "http://localhost:9090/api/v1/query?query=rate(container_network_receive_bytes_total{name=~\"optivolt-webapi.*\"}[5m])" \
        | jq '.' > "$RESULTS_DIR/network_rx_metrics.json"
    
    curl -s "http://localhost:9090/api/v1/query?query=rate(container_network_transmit_bytes_total{name=~\"optivolt-webapi.*\"}[5m])" \
        | jq '.' > "$RESULTS_DIR/network_tx_metrics.json"
    
    log_success "Metrics collected"
}

# =============================================================================
# 5. GENERATE SUMMARY REPORT
# =============================================================================
generate_report() {
    log_step "Generating summary report..."
    
    local report_file="$RESULTS_DIR/SUMMARY.md"
    
    cat > "$report_file" << EOF
# OptiVolt Web API Benchmark Report
**Date:** $(date)
**Duration:** ${DURATION}s per endpoint
**Concurrent Users:** $CONCURRENT_USERS
**Requests/sec:** $REQUESTS_PER_SECOND

## Test Configuration

### Platforms Tested
- **Standard Docker** (512MB RAM, 2 CPUs) - Port 8001
- **MicroVM Docker** (256MB RAM, 1 CPU) - Port 8002
- **Minimal Docker** (128MB RAM, 0.5 CPU) - Port 8003
- **Unikraft Unikernel** (64MB RAM) - Port 8004

### Endpoints Tested
EOF

    for endpoint in "${ENDPOINTS[@]}"; do
        echo "- \`$endpoint\`" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Results Summary

### Performance Comparison

| Platform | Total Requests | Avg Latency (ms) | Requests/sec | Success Rate |
|----------|---------------|------------------|--------------|--------------|
EOF

    # Parse results for each platform
    for platform in standard microvm minimal unikernel; do
        local result_file="$RESULTS_DIR/${platform}__.json"
        if [ -f "$result_file" ]; then
            # Extract metrics (simplified - would need proper parsing)
            echo "| $platform | - | - | - | - |" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## Resource Consumption

### CPU Usage
See \`cpu_metrics.json\`

### Memory Usage
See \`memory_metrics.json\`

### Network I/O
- RX: See \`network_rx_metrics.json\`
- TX: See \`network_tx_metrics.json\`

## Files Generated
EOF

    # List all files
    for file in "$RESULTS_DIR"/*; do
        echo "- \`$(basename "$file")\`" >> "$report_file"
    done
    
    log_success "Report generated: $report_file"
}

# =============================================================================
# 6. SIMPLE QUICK TEST
# =============================================================================
quick_test() {
    log_step "Running quick test (10s each)..."
    
    for platform in "${!PLATFORMS[@]}"; do
        local url="${PLATFORMS[$platform]}/"
        
        echo -n "  $platform: "
        
        if ! curl -s -f "$url" > /dev/null 2>&1; then
            echo -e "${RED}NOT AVAILABLE${NC}"
            continue
        fi
        
        # Quick 10-second test
        local result=$(ab -t 10 -c 10 -q "$url" 2>&1 | grep "Requests per second")
        echo -e "${GREEN}$result${NC}"
    done
}

# =============================================================================
# 7. STRESS TEST
# =============================================================================
stress_test() {
    log_step "Running stress test (high load)..."
    
    DURATION=30
    CONCURRENT_USERS=200
    REQUESTS_PER_SECOND=500
    
    run_benchmarks
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    print_header
    
    case "${1:-full}" in
        install)
            install_dependencies
            ;;
        
        quick)
            quick_test
            ;;
        
        full)
            install_dependencies
            run_benchmarks
            collect_metrics
            generate_report
            log_success "Results saved to: $RESULTS_DIR"
            ;;
        
        stress)
            install_dependencies
            stress_test
            collect_metrics
            generate_report
            ;;
        
        *)
            echo "Usage: $0 {install|quick|full|stress}"
            echo ""
            echo "Commands:"
            echo "  install - Install testing dependencies"
            echo "  quick   - Quick 10-second test per platform"
            echo "  full    - Full benchmark suite (60s per endpoint)"
            echo "  stress  - High-load stress test (30s)"
            exit 1
            ;;
    esac
}

main "$@"
