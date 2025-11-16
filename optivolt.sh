#!/bin/bash

# OptiVolt - Main CLI
# Unified entry point for all OptiVolt operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/config.sh"
source "$SCRIPT_DIR/scripts/common.sh"

show_usage() {
    cat << EOF
OptiVolt - Container Optimization Platform

Usage: ./optivolt.sh <command> [options]

Commands:
  deploy <target>       Deploy containers
                        Targets: docker, microvm, minimal, all
  
  monitor <action>      Monitoring operations
                        Actions: start, stop, status, dashboard
  
  benchmark <type>      Run benchmarks
                        Types: cpu, ram, api, full
  
  dashboard <action>    Dashboard operations
                        Actions: create, update, delete
  
  validate             Validate entire setup
  
  clean                Clean up containers and data
  
  help                 Show this help message

Examples:
  ./optivolt.sh deploy all
  ./optivolt.sh monitor dashboard
  ./optivolt.sh benchmark full
  ./optivolt.sh validate

EOF
}

deploy_containers() {
    local target="$1"
    log_info "Deploying: $target"
    
    case "$target" in
        docker)
            bash "$SCRIPT_DIR/deployment/deploy_docker.sh"
            ;;
        microvm)
            bash "$SCRIPT_DIR/deployment/deploy_microvm.sh"
            ;;
        minimal)
            bash "$SCRIPT_DIR/deployment/deploy_unikernel.sh"
            ;;
        all)
            bash "$SCRIPT_DIR/deployment/deploy_docker.sh"
            bash "$SCRIPT_DIR/deployment/deploy_microvm.sh"
            bash "$SCRIPT_DIR/deployment/deploy_unikernel.sh"
            ;;
        *)
            log_error "Unknown target: $target"
            log_info "Available targets: docker, microvm, minimal, all"
            exit 1
            ;;
    esac
}

monitor_operations() {
    local action="$1"
    
    case "$action" in
        start)
            log_info "Starting monitoring stack..."
            docker-compose -f docker-compose-monitoring.yml up -d
            ;;
        stop)
            log_info "Stopping monitoring stack..."
            docker-compose -f docker-compose-monitoring.yml down
            ;;
        status)
            log_info "Checking monitoring services..."
            check_grafana || log_warning "Grafana not running"
            check_prometheus || log_warning "Prometheus not running"
            
            if curl -s -f "$CADVISOR_URL/healthz" >/dev/null 2>&1; then
                log_success "cAdvisor is running"
            else
                log_warning "cAdvisor not running"
            fi
            ;;
        dashboard)
            log_info "Creating Grafana dashboard..."
            bash "$SCRIPT_DIR/dashboards/create-dashboard.sh"
            log_success "Dashboard available at: $GRAFANA_URL/d/$GRAFANA_DASHBOARD_UID"
            ;;
        *)
            log_error "Unknown action: $action"
            log_info "Available actions: start, stop, status, dashboard"
            exit 1
            ;;
    esac
}

run_benchmarks() {
    local type="$1"
    
    case "$type" in
        cpu)
            bash "$SCRIPT_DIR/benchmarks/run_test_cpu.sh"
            ;;
        ram)
            log_info "Running memory benchmark..."
            bash "$SCRIPT_DIR/monitoring/collect_metrics.sh"
            ;;
        api)
            bash "$SCRIPT_DIR/benchmarks/run_test_api.sh"
            ;;
        full)
            log_info "Running full benchmark suite..."
            bash "$SCRIPT_DIR/benchmarks/run_test_cpu.sh"
            bash "$SCRIPT_DIR/benchmarks/run_test_api.sh"
            bash "$SCRIPT_DIR/monitoring/validate_metrics.sh"
            ;;
        *)
            log_error "Unknown benchmark type: $type"
            log_info "Available types: cpu, ram, api, full"
            exit 1
            ;;
    esac
}

dashboard_operations() {
    local action="$1"
    
    case "$action" in
        create|update)
            bash "$SCRIPT_DIR/dashboards/create-dashboard.sh"
            ;;
        delete)
            log_warning "Deleting dashboard: $GRAFANA_DASHBOARD_UID"
            grafana_api "DELETE" "/api/dashboards/uid/$GRAFANA_DASHBOARD_UID"
            log_success "Dashboard deleted"
            ;;
        *)
            log_error "Unknown action: $action"
            log_info "Available actions: create, update, delete"
            exit 1
            ;;
    esac
}

validate_setup() {
    log_info "Validating OptiVolt setup..."
    
    log_info "Checking Docker..."
    docker --version || { log_error "Docker not found"; exit 1; }
    
    log_info "Checking monitoring services..."
    check_grafana || log_warning "Grafana not running"
    check_prometheus || log_warning "Prometheus not running"
    
    if curl -s -f "$CADVISOR_URL/healthz" >/dev/null 2>&1; then
        log_success "cAdvisor is running"
    else
        log_warning "cAdvisor not running"
    fi
    
    log_info "Checking containers..."
    docker ps --filter "name=optivolt" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    
    log_success "Validation complete"
}

clean_up() {
    log_warning "Cleaning up OptiVolt containers and data..."
    
    log_info "Stopping containers..."
    docker-compose -f docker-compose-real-benchmark.yml down 2>/dev/null || true
    docker-compose -f docker-compose-monitoring.yml down 2>/dev/null || true
    
    log_info "Removing OptiVolt containers..."
    docker ps -a --filter "name=optivolt" -q | xargs -r docker rm -f
    
    log_success "Cleanup complete"
}

# Main command handler
main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        deploy)
            deploy_containers "$@"
            ;;
        monitor)
            monitor_operations "$@"
            ;;
        benchmark)
            run_benchmarks "$@"
            ;;
        dashboard)
            dashboard_operations "$@"
            ;;
        validate)
            validate_setup
            ;;
        clean)
            clean_up
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
