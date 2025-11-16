# Dashboard Scripts

This directory contains Grafana dashboard management scripts.

## Main Script

- **create-dashboard.sh** - Production dashboard (clean, refactored)
  - Real-time Docker metrics
  - Unikraft benchmark values
  - Organized by sections
  - Calculated optimizations

## Usage

```bash
# Create/update the main dashboard
bash dashboards/create-dashboard.sh
```

## Archived Scripts

Old dashboard versions have been moved to `scripts/archive/` for reference.
