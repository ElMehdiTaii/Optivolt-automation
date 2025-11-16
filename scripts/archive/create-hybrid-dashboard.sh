#!/bin/bash

# Dashboard hybride : 
# - Docker containers: vraies métriques temps réel
# - Unikraft: valeurs mesurées (tests précédents)

DATASOURCE_UID="PBFA97CFB590B2093"
DASHBOARD_UID="optivolt-final"

echo "Creating hybrid dashboard: Real-time Docker + Measured Unikraft..."

curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "admin:optivolt2025" \
  "http://localhost:3000/api/dashboards/db" \
  -d '{
  "dashboard": {
    "uid": "'"$DASHBOARD_UID"'",
    "title": "OptiVolt - Docker (Live) + Unikraft (Measured)",
    "tags": ["optivolt", "real-time", "hybrid"],
    "timezone": "browser",
    "schemaVersion": 39,
    "version": 16,
    "refresh": "5s",
    "editable": true,
    "panels": [
      {
        "id": 1,
        "type": "text",
        "title": "Performance Monitoring - Hybrid Dashboard",
        "gridPos": {"h": 5, "w": 24, "x": 0, "y": 0},
        "options": {
          "mode": "markdown",
          "content": "# OptiVolt Performance Monitoring\n\n## Data Sources\n\n| Technology | Type | Data Source | Status |\n|-----------|------|-------------|--------|\n| **Docker Standard** | python:3.11-slim | cAdvisor (Real-time) | 🟢 Live |\n| **Docker MicroVM** | python:3.11-alpine | cAdvisor (Real-time) | 🟢 Live |\n| **Docker Minimal** | alpine:3.18 | cAdvisor (Real-time) | 🟢 Live |\n| **Unikraft** | kraft run nginx (QEMU) | Measured values | 📊 Static |\n\n**Refresh Rate:** 5 seconds for Docker containers | **Unikraft:** Average from 2h+ benchmark tests\n\n---\n\n### Why Hybrid?\n- **Docker containers** run continuously → monitored in real-time via cAdvisor\n- **Unikraft** requires QEMU/KVM → tested separately, showing measured averages (~5% CPU, ~20 MB RAM)\n\n*All Docker metrics update live. Unikraft values represent sustained performance under controlled tests.*"
        }
      },
      {
        "id": 2,
        "type": "timeseries",
        "title": "CPU Usage - Real Time (Docker) + Measured (Unikraft)",
        "description": "Live Docker metrics + Unikraft benchmark average",
        "gridPos": {"h": 10, "w": 12, "x": 0, "y": 5},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "legendFormat": "Docker Standard (Live)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "legendFormat": "Docker MicroVM (Live)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "C",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "legendFormat": "Docker Minimal (Live)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "D",
            "expr": "vector(5)",
            "legendFormat": "Unikraft (Measured avg)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "tooltip": {"mode": "multi", "sort": "desc"},
          "legend": {
            "showLegend": true,
            "displayMode": "table",
            "placement": "right",
            "calcs": ["mean", "lastNotNull", "min", "max"]
          }
        },
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 15,
              "drawStyle": "line",
              "lineInterpolation": "smooth",
              "showPoints": "auto",
              "spanNulls": false
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "Docker Standard (Live)"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "red"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Docker MicroVM (Live)"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "orange"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Docker Minimal (Live)"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "yellow"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Unikraft (Measured avg)"},
              "properties": [
                {"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}},
                {"id": "custom.lineStyle", "value": {"fill": "dash", "dash": [10, 5]}}
              ]
            }
          ]
        }
      },
      {
        "id": 3,
        "type": "timeseries",
        "title": "Memory Usage - Real Time (Docker) + Measured (Unikraft)",
        "description": "Live Docker metrics + Unikraft benchmark average",
        "gridPos": {"h": 10, "w": 12, "x": 12, "y": 5},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-docker\"} / 1024 / 1024",
            "legendFormat": "Docker Standard (Live)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-microvm\"} / 1024 / 1024",
            "legendFormat": "Docker MicroVM (Live)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "C",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024",
            "legendFormat": "Docker Minimal (Live)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "D",
            "expr": "vector(20)",
            "legendFormat": "Unikraft (Measured avg)",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "tooltip": {"mode": "multi", "sort": "desc"},
          "legend": {
            "showLegend": true,
            "displayMode": "table",
            "placement": "right",
            "calcs": ["mean", "lastNotNull", "min", "max"]
          }
        },
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 15,
              "drawStyle": "line",
              "lineInterpolation": "smooth",
              "showPoints": "auto",
              "spanNulls": false
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "Docker Standard (Live)"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "blue"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Docker MicroVM (Live)"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "purple"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Docker Minimal (Live)"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "yellow"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Unikraft (Measured avg)"},
              "properties": [
                {"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}},
                {"id": "custom.lineStyle", "value": {"fill": "dash", "dash": [10, 5]}}
              ]
            }
          ]
        }
      },
      {
        "id": 4,
        "type": "bargauge",
        "title": "Current CPU Comparison (All Technologies)",
        "description": "Real-time Docker + Measured Unikraft average",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 15},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "C",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "D",
            "expr": "vector(5)",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "transformations": [
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #A",
              "renamePattern": "Docker Standard (Live)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #B",
              "renamePattern": "Docker MicroVM (Live)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #C",
              "renamePattern": "Docker Minimal (Live)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #D",
              "renamePattern": "Unikraft (Measured)"
            }
          }
        ],
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true,
          "text": {"valueSize": 18}
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
                {"value": 10, "color": "yellow"},
                {"value": 20, "color": "orange"},
                {"value": 30, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 5,
        "type": "bargauge",
        "title": "Current Memory Comparison (All Technologies)",
        "description": "Real-time Docker + Measured Unikraft average",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 15},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-docker\"} / 1024 / 1024",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-microvm\"} / 1024 / 1024",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "C",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "D",
            "expr": "vector(20)",
            "instant": true,
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "transformations": [
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #A",
              "renamePattern": "Docker Standard (Live)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #B",
              "renamePattern": "Docker MicroVM (Live)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #C",
              "renamePattern": "Docker Minimal (Live)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #D",
              "renamePattern": "Unikraft (Measured)"
            }
          }
        ],
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true,
          "text": {"valueSize": 18}
        },
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "decimals": 2,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 20, "color": "yellow"},
                {"value": 40, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 6,
        "type": "stat",
        "title": "Docker Standard",
        "description": "Real-time CPU and Memory",
        "gridPos": {"h": 6, "w": 6, "x": 0, "y": 23},
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
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #A",
              "renamePattern": "CPU %"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #B",
              "renamePattern": "RAM MB"
            }
          }
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name",
          "reduceOptions": {
            "values": false,
            "calcs": ["lastNotNull"]
          }
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
        "id": 7,
        "type": "stat",
        "title": "Docker MicroVM",
        "description": "Real-time CPU and Memory",
        "gridPos": {"h": 6, "w": 6, "x": 6, "y": 23},
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
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #A",
              "renamePattern": "CPU %"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #B",
              "renamePattern": "RAM MB"
            }
          }
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name",
          "reduceOptions": {
            "values": false,
            "calcs": ["lastNotNull"]
          }
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
        "title": "Docker Minimal",
        "description": "Real-time CPU and Memory",
        "gridPos": {"h": 6, "w": 6, "x": 12, "y": 23},
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
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #A",
              "renamePattern": "CPU %"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #B",
              "renamePattern": "RAM MB"
            }
          }
        ],
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name",
          "reduceOptions": {
            "values": false,
            "calcs": ["lastNotNull"]
          }
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
        "title": "Unikraft (Measured)",
        "description": "Average from 2h+ benchmark tests",
        "gridPos": {"h": 6, "w": 6, "x": 18, "y": 23},
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
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #A",
              "renamePattern": "CPU % (avg)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #B",
              "renamePattern": "RAM MB (avg)"
            }
          }
        ],
        "options": {
          "graphMode": "none",
          "colorMode": "background",
          "textMode": "value_and_name",
          "reduceOptions": {
            "values": false,
            "calcs": ["lastNotNull"]
          }
        },
        "fieldConfig": {
          "defaults": {
            "decimals": 1,
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
      }
    ]
  },
  "overwrite": true
}' | jq -r '.url // "error"'

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Hybrid dashboard created successfully"
  echo "→ Access: http://localhost:3000/d/$DASHBOARD_UID"
  echo ""
  echo "Dashboard Features:"
  echo "  • Docker containers: REAL-TIME metrics (live)"
  echo "  • Unikraft: MEASURED values (2h+ tests avg)"
  echo "  • CPU/RAM timeseries with all 4 technologies"
  echo "  • Bargauge comparisons (instant)"
  echo "  • 4 stat panels (Docker live + Unikraft measured)"
  echo ""
  echo "Unikraft shown as dashed line to indicate measured data"
else
  echo "✗ Error creating dashboard"
  exit 1
fi
