# OptiVolt - Performance and Energy Analysis Platform

## Overview

OptiVolt is an automated platform for comparing performance and energy consumption across different virtualization technologies (Docker, MicroVM, Unikernel). It provides comprehensive tooling for deployment, testing, metrics collection, and visualization.

## Architecture

### Core Components

```
optivolt/
├── OptiVoltCLI/              # .NET 8.0 CLI Application
│   ├── Commands/             # Command implementations
│   ├── Services/             # Business logic services
│   ├── Models/               # Data models
│   └── Program.cs            # Application entry point
├── OptiVoltCLI.Tests/        # Unit test suite (xUnit)
├── scripts/                  # Automation scripts
│   ├── Python/               # Analysis and reporting
│   └── Bash/                 # Deployment and setup
├── monitoring/               # Monitoring stack configuration
│   ├── grafana/              # Dashboards and datasources
│   └── prometheus/           # Metrics collection config
├── config/                   # Environment configurations
├── docs/                     # Technical documentation
└── .gitlab/ci/               # CI/CD pipeline definitions
```

### Technology Stack

- **CLI Framework**: .NET 8.0 with System.CommandLine
- **SSH Client**: SSH.NET library
- **Data Format**: JSON (Newtonsoft.Json)
- **Testing**: xUnit with Moq
- **Monitoring**: Prometheus + Grafana
- **CI/CD**: GitLab CI/CD
- **Scripting**: Python 3, Bash

## Features

### Command-Line Interface

#### Deploy Command
Deploys test environments to target hosts.

```bash
dotnet OptiVoltCLI.dll deploy --environment docker
dotnet OptiVoltCLI.dll deploy --environment unikernel
```

**Capabilities:**
- Automatic local/remote detection
- SSH-based remote deployment
- Script execution and monitoring
- Error handling and logging

#### Test Command
Executes performance tests on deployed environments.

```bash
dotnet OptiVoltCLI.dll test --environment docker --type cpu --duration 30
dotnet OptiVoltCLI.dll test --environment unikernel --type all --duration 60
```

**Test Types:**
- `cpu`: CPU-intensive workload
- `api`: API endpoint stress testing
- `db`: Database operation simulation
- `all`: Sequential execution of all tests

#### Collect Command
Gathers metrics from test executions.

```bash
dotnet OptiVoltCLI.dll collect --environment docker
dotnet OptiVoltCLI.dll collect --environment all
```

**Output**: JSON-formatted test results with metrics

### Monitoring Stack

#### Grafana Dashboards
- Real-time performance visualization
- Docker vs Unikernel comparison
- System resource monitoring
- Custom metric queries

**Access**: http://localhost:3000  
**Credentials**: admin / optivolt2025

#### Prometheus Metrics
- Container resource usage
- System-level metrics
- Network I/O statistics
- Custom application metrics

**Access**: http://localhost:9090

### Continuous Integration

GitLab CI/CD pipeline with 6 stages:
1. **Build**: Compile and package OptiVoltCLI
2. **Deploy**: Deploy to test environments
3. **Test**: Execute performance tests
4. **Metrics**: Collect system metrics
5. **Power Monitoring**: Energy consumption tracking
6. **Report**: Generate analysis reports

## Installation

### Prerequisites

- .NET 8.0 SDK
- Docker and Docker Compose
- Python 3.8+
- SSH access to target hosts

### Setup

1. Clone the repository:
```bash
git clone https://gitlab.com/mehdi_taii/optivolt.git
cd optivolt
```

2. Build the CLI:
```bash
cd OptiVoltCLI
dotnet build -c Release -o ../publish
cd ..
```

3. Configure hosts:
```bash
cp config/hosts.json.example config/hosts.json
# Edit hosts.json with your environment details
```

4. Start monitoring stack:
```bash
./start-monitoring.sh
```

## Configuration

### Host Configuration

File: `config/hosts.json`

```json
{
  "hosts": {
    "docker": {
      "hostname": "docker-host",
      "ip": "192.168.1.100",
      "port": 22,
      "user": "admin",
      "workdir": "/opt/optivolt"
    }
  }
}
```

**Fields:**
- `hostname`: Host identifier
- `ip`: IP address or hostname for SSH connection
- `port`: SSH port (default: 22)
- `user`: SSH username
- `workdir`: Working directory on remote host

### Environment Variables

- `DOTNET_VERSION`: .NET SDK version (default: 8.0)
- `TEST_DURATION`: Default test duration in seconds (default: 30)

## Usage Examples

### Local Testing

```bash
cd publish

# Deploy Docker environment
dotnet OptiVoltCLI.dll deploy --environment docker

# Run CPU test for 60 seconds
dotnet OptiVoltCLI.dll test --environment docker --type cpu --duration 60

# Collect all metrics
dotnet OptiVoltCLI.dll collect --environment all
```

### Comparing Environments

```bash
# Test Docker
dotnet OptiVoltCLI.dll test --environment docker --type all --duration 30

# Test Unikernel
dotnet OptiVoltCLI.dll test --environment unikernel --type all --duration 30

# Generate comparison report
python3 scripts/compare_environments.py publish/ comparison.html
```

### Monitoring

```bash
# Start monitoring stack
./start-monitoring.sh

# Access Grafana
open http://localhost:3000

# View Prometheus metrics
open http://localhost:9090
```

## Development

### Building from Source

```bash
dotnet build OptiVoltCLI/OptiVoltCLI.csproj -c Release
```

### Running Tests

```bash
dotnet test OptiVoltCLI.Tests/OptiVoltCLI.Tests.csproj
```

### Code Quality

- Follow C# coding conventions
- Maintain test coverage above 70%
- Use async/await for I/O operations
- Implement proper error handling
- Document public APIs

## Project Structure

### C# Components

**Models**
- `HostConfig`: Environment configuration
- `TestResult`: Test execution results

**Services**
- `ConfigurationService`: Configuration management
- `SshService`: SSH operations
- `MetricsService`: Metrics collection

**Commands**
- `DeployCommand`: Environment deployment
- `TestCommand`: Test execution
- `CollectCommand`: Metrics gathering

### Python Scripts

- `compare_environments.py`: Performance comparison
- `collect_system_metrics.py`: System metrics collection
- `create_comparison_dashboard.py`: Grafana dashboard generation

### Bash Scripts

- `setup_local_unikernel.sh`: Local unikernel setup
- `start_scaphandre_docker.sh`: Energy monitoring
- `run_test_*.sh`: Test execution scripts

## Troubleshooting

### SSH Connection Issues

1. Verify SSH key configuration:
```bash
ssh -i ~/.ssh/id_rsa user@host -p 22
```

2. Check host configuration in `config/hosts.json`

3. Ensure SSH service is running on target host

### Build Errors

1. Verify .NET SDK version:
```bash
dotnet --version
```

2. Clean and rebuild:
```bash
dotnet clean
dotnet build
```

### Container Issues

1. Check Docker status:
```bash
docker ps
docker logs <container_name>
```

2. Restart monitoring stack:
```bash
docker-compose -f docker-compose-monitoring.yml down
./start-monitoring.sh
```

## Performance Considerations

- SSH connections use connection pooling
- Metrics are collected asynchronously
- Test execution timeout: 300 seconds default
- Local execution bypasses SSH overhead

## Security

- SSH key-based authentication recommended
- Private keys should be stored securely
- Use least-privilege user accounts
- Network isolation for test environments

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## License

Academic use only. Contact maintainers for commercial licensing.

## Support

- Issues: GitLab issue tracker
- Documentation: `docs/` directory
- Email: project maintainer

## Roadmap

- [ ] Support for additional virtualization platforms
- [ ] Enhanced energy monitoring with hardware sensors
- [ ] Machine learning for performance prediction
- [ ] REST API for programmatic access
- [ ] Web-based dashboard interface

## Acknowledgments

- Built with .NET 8.0 and System.CommandLine
- Monitoring powered by Prometheus and Grafana
- Energy tracking via Scaphandre project

---

Project Version: 1.0.0  
Last Updated: November 2025  
Status: Production Ready
