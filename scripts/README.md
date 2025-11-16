# OptiVolt Scripts Directory

Organized scripts for the OptiVolt automation project.

## Directory Structure

```
scripts/
├── config.sh                    # Central configuration file
├── common.sh                    # Shared utility functions
├── dashboards/                  # Grafana dashboard scripts
│   ├── create-dashboard.sh     # Main production dashboard
│   └── README.md
├── deployment/                  # Container deployment scripts
│   ├── deploy_docker.sh
│   ├── deploy_microvm.sh
│   ├── deploy_unikernel.sh
│   └── deploy_web_api.sh
├── monitoring/                  # Metrics collection & validation
│   ├── collect_metrics.sh
│   ├── collect_system_metrics.py
│   └── validate_metrics.sh
├── benchmarks/                  # Performance testing
│   ├── benchmark_api.sh
│   ├── run_test_api.sh
│   ├── run_test_cpu.sh
│   ├── run_test_db.sh
│   ├── workload_benchmark.py
│   └── compare_environments.py
└── archive/                     # Old/deprecated scripts
    └── (legacy dashboard versions)
```

## Quick Start

### 1. Source Configuration

```bash
source scripts/config.sh
```

This loads:
- Grafana/Prometheus URLs
- Container names
- Benchmark values
- Helper functions

### 2. Create Dashboard

```bash
bash scripts/dashboards/create-dashboard.sh
```

### 3. Deploy Containers

```bash
bash scripts/deployment/deploy_docker.sh
bash scripts/deployment/deploy_microvm.sh
bash scripts/deployment/deploy_unikernel.sh
```

### 4. Run Benchmarks

```bash
bash scripts/benchmarks/benchmark_api.sh
```

## Configuration

All configuration is centralized in `config.sh`:

- **Grafana**: URL, credentials, datasource UID
- **Prometheus**: URL
- **Containers**: Names and images
- **Benchmarks**: Unikraft values, optimization metrics

## Helper Functions

Available from `config.sh`:

```bash
check_dependencies    # Verify curl, jq, docker
check_grafana        # Test Grafana connection
check_prometheus     # Test Prometheus connection
check_containers     # Verify containers are running
log_success "msg"    # Green output
log_error "msg"      # Red output
log_info "msg"       # Blue output
log_warning "msg"    # Yellow output
```

## Archive

Old scripts moved to `archive/` for reference:
- 15+ legacy dashboard versions
- Deprecated Python generators
- Experimental scripts

These are kept for historical reference but should not be used in production.

## Best Practices

1. **Always source config.sh** before running scripts
2. **Use the main dashboard script** (dashboards/create-dashboard.sh)
3. **Check logs** for errors
4. **Run checks** (check_grafana, check_prometheus) before operations

## Troubleshooting

### Dashboard shows "No data"
```bash
source scripts/config.sh
check_prometheus
check_containers
```

### Grafana not accessible
```bash
docker ps | grep grafana
docker logs optivolt-grafana
```

### Containers not running
```bash
docker-compose -f docker-compose-real-benchmark.yml up -d
```
