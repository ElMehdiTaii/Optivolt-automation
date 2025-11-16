#!/bin/bash

# OptiVolt Web API Dashboard
# Adds Web API metrics to existing dashboard

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

# Check dependencies
check_dependencies || exit 1
check_grafana || exit 1

log_info "Creating OptiVolt Web API Dashboard..."

curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  "${GRAFANA_URL}/api/dashboards/db" \
  -d '{
  "dashboard": {
    "uid": "optivolt-webapi",
    "title": "OptiVolt Web API Performance",
    "tags": ["optivolt", "webapi", "performance"],
    "timezone": "browser",
    "schemaVersion": 39,
    "version": 1,
    "refresh": "5s",
    "editable": true,
    "panels": [
      {
        "id": 1,
        "type": "row",
        "title": "Web API Overview",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 0},
        "collapsed": false
      },
      {
        "id": 2,
        "type": "text",
        "title": "",
        "gridPos": {"h": 4, "w": 24, "x": 0, "y": 1},
        "options": {
          "mode": "markdown",
          "content": "# OptiVolt Web API Performance\n\n| Platform | Variant | Port | Memory | CPUs | Status |\n|----------|---------|------|--------|------|--------|\n| Docker | Standard | 8001 | 512MB | 2.0 | Real-time |\n| Docker | MicroVM | 8002 | 256MB | 1.0 | Real-time |\n| Docker | Minimal | 8003 | 128MB | 0.5 | Real-time |\n| Unikraft | Unikernel | 8004 | 64MB | - | Measured |\n\n**API Endpoints:** `/` (root), `/api/light`, `/api/heavy`, `/api/slow`"
        }
      },
      {
        "id": 3,
        "type": "row",
        "title": "CPU Usage - Real-time",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 5},
        "collapsed": false
      },
      {
        "id": 4,
        "type": "timeseries",
        "title": "CPU Usage (%) - All Platforms",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 6},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"optivolt-webapi.*\"}[1m]) * 100",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "color": {"mode": "palette-classic"},
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 10,
              "showPoints": "never",
              "axisPlacement": "auto"
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "optivolt-webapi-standard"},
              "properties": [{"id": "color", "value": {"fixedColor": "blue", "mode": "fixed"}}]
            },
            {
              "matcher": {"id": "byName", "options": "optivolt-webapi-microvm"},
              "properties": [{"id": "color", "value": {"fixedColor": "green", "mode": "fixed"}}]
            },
            {
              "matcher": {"id": "byName", "options": "optivolt-webapi-minimal"},
              "properties": [{"id": "color", "value": {"fixedColor": "orange", "mode": "fixed"}}]
            }
          ]
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "right",
            "calcs": ["mean", "last", "max"]
          }
        }
      },
      {
        "id": 5,
        "type": "row",
        "title": "Memory Usage - Real-time",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 14},
        "collapsed": false
      },
      {
        "id": 6,
        "type": "timeseries",
        "title": "Memory Usage (MB) - All Platforms",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 15},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "container_memory_working_set_bytes{name=~\"optivolt-webapi.*\"} / 1024 / 1024",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "color": {"mode": "palette-classic"},
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 10,
              "showPoints": "never",
              "axisPlacement": "auto"
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "optivolt-webapi-standard"},
              "properties": [{"id": "color", "value": {"fixedColor": "blue", "mode": "fixed"}}]
            },
            {
              "matcher": {"id": "byName", "options": "optivolt-webapi-microvm"},
              "properties": [{"id": "color", "value": {"fixedColor": "green", "mode": "fixed"}}]
            },
            {
              "matcher": {"id": "byName", "options": "optivolt-webapi-minimal"},
              "properties": [{"id": "color", "value": {"fixedColor": "orange", "mode": "fixed"}}]
            }
          ]
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "right",
            "calcs": ["mean", "last", "max"]
          }
        }
      },
      {
        "id": 7,
        "type": "row",
        "title": "Network I/O",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 23},
        "collapsed": false
      },
      {
        "id": 8,
        "type": "timeseries",
        "title": "Network RX (bytes/sec)",
        "gridPos": {"h": 6, "w": 12, "x": 0, "y": 24},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "rate(container_network_receive_bytes_total{name=~\"optivolt-webapi.*\"}[1m])",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "Bps",
            "color": {"mode": "palette-classic"}
          }
        }
      },
      {
        "id": 9,
        "type": "timeseries",
        "title": "Network TX (bytes/sec)",
        "gridPos": {"h": 6, "w": 12, "x": 12, "y": 24},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "rate(container_network_transmit_bytes_total{name=~\"optivolt-webapi.*\"}[1m])",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "Bps",
            "color": {"mode": "palette-classic"}
          }
        }
      },
      {
        "id": 10,
        "type": "row",
        "title": "Current Values",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 30},
        "collapsed": false
      },
      {
        "id": 11,
        "type": "stat",
        "title": "Standard - CPU",
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 31},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-webapi-standard\"}[1m]) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 80, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 12,
        "type": "stat",
        "title": "MicroVM - CPU",
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 31},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-webapi-microvm\"}[1m]) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 80, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 13,
        "type": "stat",
        "title": "Minimal - CPU",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 31},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-webapi-minimal\"}[1m]) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 80, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 14,
        "type": "stat",
        "title": "Unikernel - CPU (measured)",
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 31},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "vector(3)",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"}
              ]
            }
          }
        },
        "options": {
          "textMode": "value_and_name"
        }
      },
      {
        "id": 15,
        "type": "stat",
        "title": "Standard - Memory",
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 35},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "container_memory_working_set_bytes{name=\"optivolt-webapi-standard\"} / 1024 / 1024",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 256, "color": "yellow"},
                {"value": 400, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 16,
        "type": "stat",
        "title": "MicroVM - Memory",
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 35},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "container_memory_working_set_bytes{name=\"optivolt-webapi-microvm\"} / 1024 / 1024",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 150, "color": "yellow"},
                {"value": 200, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 17,
        "type": "stat",
        "title": "Minimal - Memory",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 35},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "container_memory_working_set_bytes{name=\"optivolt-webapi-minimal\"} / 1024 / 1024",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 80, "color": "yellow"},
                {"value": 100, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 18,
        "type": "stat",
        "title": "Unikernel - Memory (measured)",
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 35},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "vector(15)",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"}
              ]
            }
          }
        },
        "options": {
          "textMode": "value_and_name"
        }
      },
      {
        "id": 19,
        "type": "row",
        "title": "Performance Comparison",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 39},
        "collapsed": false
      },
      {
        "id": 20,
        "type": "bargauge",
        "title": "CPU Usage Comparison",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 40},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-webapi-standard\"}[5m]) * 100",
            "legendFormat": "Standard",
            "refId": "A"
          },
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-webapi-microvm\"}[5m]) * 100",
            "legendFormat": "MicroVM",
            "refId": "B"
          },
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-webapi-minimal\"}[5m]) * 100",
            "legendFormat": "Minimal",
            "refId": "C"
          },
          {
            "expr": "vector(3)",
            "legendFormat": "Unikernel",
            "refId": "D"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "color": {"mode": "palette-classic"}
          }
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true
        }
      },
      {
        "id": 21,
        "type": "bargauge",
        "title": "Memory Usage Comparison",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 40},
        "datasource": {"type": "prometheus", "uid": "'"${GRAFANA_DATASOURCE_UID}"'"},
        "targets": [
          {
            "expr": "container_memory_working_set_bytes{name=\"optivolt-webapi-standard\"} / 1024 / 1024",
            "legendFormat": "Standard",
            "refId": "A"
          },
          {
            "expr": "container_memory_working_set_bytes{name=\"optivolt-webapi-microvm\"} / 1024 / 1024",
            "legendFormat": "MicroVM",
            "refId": "B"
          },
          {
            "expr": "container_memory_working_set_bytes{name=\"optivolt-webapi-minimal\"} / 1024 / 1024",
            "legendFormat": "Minimal",
            "refId": "C"
          },
          {
            "expr": "vector(15)",
            "legendFormat": "Unikernel",
            "refId": "D"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "color": {"mode": "palette-classic"}
          }
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true
        }
      }
    ]
  },
  "overwrite": true
}' | jq '.'

if [ $? -eq 0 ]; then
    log_success "Web API dashboard created successfully"
    log_info "Dashboard URL: ${GRAFANA_URL}/d/optivolt-webapi"
else
    log_error "Failed to create dashboard"
    exit 1
fi
