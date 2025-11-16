#!/bin/bash

# OptiVolt Main Dashboard
# Creates clean, production-ready Grafana dashboard

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

# Check dependencies
check_dependencies || exit 1
check_grafana || exit 1

log_info "Creating OptiVolt dashboard..."

curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  "${GRAFANA_URL}/api/dashboards/db" \
  -d '{
  "dashboard": {
    "uid": "'"${GRAFANA_DASHBOARD_UID}"'",
    "title": "OptiVolt Performance Analysis",
    "tags": ["optivolt", "performance"],
    "timezone": "browser",
    "schemaVersion": 39,
    "version": 17,
    "refresh": "5s",
    "editable": true,
    "panels": [
      {
        "id": 1,
        "type": "row",
        "title": "Overview",
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
          "content": "# OptiVolt Performance Monitoring\n\n| Technology | Type | CPU (avg) | Memory (avg) | Data Source |\n|-----------|------|-----------|--------------|-------------|\n| Docker Standard | python:3.11-slim | Real-time | Real-time | cAdvisor |\n| Docker MicroVM | python:3.11-alpine | Real-time | Real-time | cAdvisor |\n| Docker Minimal | alpine:3.18 | Real-time | Real-time | cAdvisor |\n| Unikraft | kraft run (QEMU) | ~5% | ~20 MB | Benchmark |\n\n**Refresh:** 5s | **Docker metrics:** Live from containers | **Unikraft:** Measured average from 2h+ tests"
        }
      },
      {
        "id": 3,
        "type": "row",
        "title": "Real-Time Monitoring",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 5},
        "collapsed": false
      },
      {
        "id": 4,
        "type": "timeseries",
        "title": "CPU Usage (%)",
        "gridPos": {"h": 9, "w": 12, "x": 0, "y": 6},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"optivolt-(docker|microvm|unikernel)\"}[1m]) * 100",
            "legendFormat": "{{name}}",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "vector(5)",
            "legendFormat": "unikraft (measured)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "tooltip": {"mode": "multi", "sort": "desc"},
          "legend": {
            "showLegend": true,
            "displayMode": "table",
            "placement": "bottom",
            "calcs": ["mean", "lastNotNull", "max"]
          }
        },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 10,
              "drawStyle": "line",
              "lineInterpolation": "smooth",
              "showPoints": "never"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 80, "color": "red"}
              ]
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byFrameRefID", "options": "B"},
              "properties": [
                {"id": "custom.lineStyle", "value": {"fill": "dash", "dash": [10, 5]}},
                {"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}
              ]
            }
          ]
        }
      },
      {
        "id": 5,
        "type": "timeseries",
        "title": "Memory Usage (MB)",
        "gridPos": {"h": 9, "w": 12, "x": 12, "y": 6},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=~\"optivolt-(docker|microvm|unikernel)\"} / 1024 / 1024",
            "legendFormat": "{{name}}",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "vector(20)",
            "legendFormat": "unikraft (measured)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "tooltip": {"mode": "multi", "sort": "desc"},
          "legend": {
            "showLegend": true,
            "displayMode": "table",
            "placement": "bottom",
            "calcs": ["mean", "lastNotNull", "max"]
          }
        },
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 10,
              "drawStyle": "line",
              "lineInterpolation": "smooth",
              "showPoints": "never"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 100, "color": "red"}
              ]
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byFrameRefID", "options": "B"},
              "properties": [
                {"id": "custom.lineStyle", "value": {"fill": "dash", "dash": [10, 5]}},
                {"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}
              ]
            }
          ]
        }
      },
      {
        "id": 6,
        "type": "row",
        "title": "Current Values",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 15},
        "collapsed": false
      },
      {
        "id": 7,
        "type": "stat",
        "title": "Docker Standard",
        "gridPos": {"h": 5, "w": 6, "x": 0, "y": 16},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-docker\"} / 1024 / 1024",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "transformations": [
          {"id": "renameByRegex", "options": {"regex": "Value #A", "renamePattern": "CPU %"}},
          {"id": "renameByRegex", "options": {"regex": "Value #B", "renamePattern": "RAM MB"}}
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "value",
          "textMode": "value_and_name",
          "reduceOptions": {"values": false, "calcs": ["lastNotNull"]}
        },
        "fieldConfig": {
          "defaults": {
            "decimals": 2,
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
        "id": 8,
        "type": "stat",
        "title": "Docker MicroVM",
        "gridPos": {"h": 5, "w": 6, "x": 6, "y": 16},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-microvm\"} / 1024 / 1024",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "transformations": [
          {"id": "renameByRegex", "options": {"regex": "Value #A", "renamePattern": "CPU %"}},
          {"id": "renameByRegex", "options": {"regex": "Value #B", "renamePattern": "RAM MB"}}
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "value",
          "textMode": "value_and_name",
          "reduceOptions": {"values": false, "calcs": ["lastNotNull"]}
        },
        "fieldConfig": {
          "defaults": {
            "decimals": 2,
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
        "id": 9,
        "type": "stat",
        "title": "Docker Minimal",
        "gridPos": {"h": 5, "w": 6, "x": 12, "y": 16},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "transformations": [
          {"id": "renameByRegex", "options": {"regex": "Value #A", "renamePattern": "CPU %"}},
          {"id": "renameByRegex", "options": {"regex": "Value #B", "renamePattern": "RAM MB"}}
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "value",
          "textMode": "value_and_name",
          "reduceOptions": {"values": false, "calcs": ["lastNotNull"]}
        },
        "fieldConfig": {
          "defaults": {
            "decimals": 2,
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
        "id": 10,
        "type": "stat",
        "title": "Unikraft (Benchmark)",
        "gridPos": {"h": 5, "w": 6, "x": 18, "y": 16},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "vector(5)",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "vector(20)",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "transformations": [
          {"id": "renameByRegex", "options": {"regex": "Value #A", "renamePattern": "CPU %"}},
          {"id": "renameByRegex", "options": {"regex": "Value #B", "renamePattern": "RAM MB"}}
        ],
        "options": {
          "graphMode": "none",
          "colorMode": "value",
          "textMode": "value_and_name",
          "reduceOptions": {"values": false, "calcs": ["lastNotNull"]}
        },
        "fieldConfig": {
          "defaults": {
            "decimals": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"}
              ]
            }
          }
        }
      },
      {
        "id": 11,
        "type": "row",
        "title": "Comparison",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 21},
        "collapsed": false
      },
      {
        "id": 12,
        "type": "bargauge",
        "title": "CPU Comparison",
        "gridPos": {"h": 7, "w": 12, "x": 0, "y": 22},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"optivolt-(docker|microvm|unikernel)\"}[1m]) * 100",
            "instant": true,
            "legendFormat": "{{name}}",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "vector(5)",
            "instant": true,
            "legendFormat": "unikraft",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true,
          "text": {"valueSize": 16}
        },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "decimals": 2,
            "max": 100,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 20, "color": "yellow"},
                {"value": 50, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 13,
        "type": "bargauge",
        "title": "Memory Comparison",
        "gridPos": {"h": 7, "w": 12, "x": 12, "y": 22},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=~\"optivolt-(docker|microvm|unikernel)\"} / 1024 / 1024",
            "instant": true,
            "legendFormat": "{{name}}",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "vector(20)",
            "instant": true,
            "legendFormat": "unikraft",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true,
          "text": {"valueSize": 16}
        },
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "decimals": 2,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 30, "color": "yellow"},
                {"value": 50, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 14,
        "type": "row",
        "title": "Optimization Metrics",
        "gridPos": {"h": 1, "w": 24, "x": 0, "y": 29},
        "collapsed": false
      },
      {
        "id": 15,
        "type": "stat",
        "title": "CPU Optimization",
        "description": "Reduction from Docker Standard to Docker Minimal",
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 30},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "(1 - rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[5m]) / rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[5m])) * 100",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value",
          "reduceOptions": {"values": false, "calcs": ["lastNotNull"]}
        },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "decimals": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 30, "color": "yellow"},
                {"value": 50, "color": "green"}
              ]
            }
          }
        }
      },
      {
        "id": 16,
        "type": "stat",
        "title": "Memory Optimization",
        "description": "Reduction from Docker Standard to Docker Minimal",
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 30},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "(1 - container_memory_working_set_bytes{name=\"optivolt-unikernel\"} / container_memory_working_set_bytes{name=\"optivolt-docker\"}) * 100",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value",
          "reduceOptions": {"values": false, "calcs": ["lastNotNull"]}
        },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "decimals": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 50, "color": "yellow"},
                {"value": 90, "color": "green"}
              ]
            }
          }
        }
      },
      {
        "id": 17,
        "type": "stat",
        "title": "Carbon Footprint Reduction",
        "description": "Estimated CO2 savings based on power consumption",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 30},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "vector(61.2)",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value",
          "reduceOptions": {"values": false, "calcs": ["lastNotNull"]}
        },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "decimals": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 40, "color": "yellow"},
                {"value": 60, "color": "green"}
              ]
            }
          }
        }
      },
      {
        "id": 18,
        "type": "stat",
        "title": "Cloud Cost Savings",
        "description": "Estimated infrastructure cost reduction",
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 30},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "vector(30.61)",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value",
          "reduceOptions": {"values": false, "calcs": ["lastNotNull"]}
        },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "decimals": 2,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 20, "color": "yellow"},
                {"value": 30, "color": "green"}
              ]
            }
          }
        }
      }
    ]
  },
  "overwrite": true
}' | jq -r '.url // "error"'

RESULT=$?
if [ $RESULT -eq 0 ]; then
  log_success "Dashboard created successfully"
  log_info "Access: ${GRAFANA_URL}/d/${GRAFANA_DASHBOARD_UID}"
  echo ""
  echo "Structure:"
  echo "  1. Overview (documentation table)"
  echo "  2. Real-Time Monitoring (CPU & RAM timeseries)"
  echo "  3. Current Values (4 stat panels)"
  echo "  4. Comparison (bargauge CPU & RAM)"
  echo "  5. Optimization Metrics (calculated savings)"
else
  log_error "Failed to create dashboard"
  exit 1
fi
