#!/bin/bash

# Dashboard avec métriques RÉELLES en temps réel (pas de vector)
# Utilise les données cAdvisor directement

DATASOURCE_UID="PBFA97CFB590B2093"
DASHBOARD_UID="optivolt-final"

echo "Creating dashboard with REAL-TIME metrics from cAdvisor..."

curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "admin:optivolt2025" \
  "http://localhost:3000/api/dashboards/db" \
  -d '{
  "dashboard": {
    "uid": "'"$DASHBOARD_UID"'",
    "title": "OptiVolt - Real-Time Performance Monitoring",
    "tags": ["optivolt", "real-time", "cadvisor", "live"],
    "timezone": "browser",
    "schemaVersion": 39,
    "version": 15,
    "refresh": "5s",
    "editable": true,
    "panels": [
      {
        "id": 1,
        "type": "text",
        "title": "Live Monitoring Dashboard",
        "gridPos": {"h": 4, "w": 24, "x": 0, "y": 0},
        "options": {
          "mode": "markdown",
          "content": "# OptiVolt - Real-Time Performance Monitoring\n\n**Data Source:** Live metrics from cAdvisor\n\n**Monitored Containers:**\n- **optivolt-docker** (python:3.11-slim) - Standard Docker container\n- **optivolt-microvm** (python:3.11-alpine) - Alpine-based optimized container\n- **optivolt-unikernel** (alpine:3.18) - Minimal Alpine container\n\n**Refresh Rate:** 5 seconds | **Metrics:** CPU usage (rate), Memory working set\n\n---\n*All data is collected in real-time from running containers*"
        }
      },
      {
        "id": 2,
        "type": "timeseries",
        "title": "CPU Usage - Real Time (%)",
        "description": "Live CPU usage calculated with rate() over 1 minute",
        "gridPos": {"h": 10, "w": 12, "x": 0, "y": 4},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "legendFormat": "Docker Standard",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "legendFormat": "Docker MicroVM",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "C",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "legendFormat": "Docker Minimal",
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
              "fillOpacity": 20,
              "drawStyle": "line",
              "lineInterpolation": "smooth",
              "showPoints": "auto",
              "spanNulls": false
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
              "matcher": {"id": "byName", "options": "Docker Standard"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "red"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Docker MicroVM"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "orange"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Docker Minimal"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}]
            }
          ]
        }
      },
      {
        "id": 3,
        "type": "timeseries",
        "title": "Memory Usage - Real Time (MB)",
        "description": "Live memory working set from cAdvisor",
        "gridPos": {"h": 10, "w": 12, "x": 12, "y": 4},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-docker\"} / 1024 / 1024",
            "legendFormat": "Docker Standard",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "B",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-microvm\"} / 1024 / 1024",
            "legendFormat": "Docker MicroVM",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          },
          {
            "refId": "C",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024",
            "legendFormat": "Docker Minimal",
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
              "fillOpacity": 20,
              "drawStyle": "line",
              "lineInterpolation": "smooth",
              "showPoints": "auto",
              "spanNulls": false
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
              "matcher": {"id": "byName", "options": "Docker Standard"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "blue"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Docker MicroVM"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "purple"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Docker Minimal"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}]
            }
          ]
        }
      },
      {
        "id": 4,
        "type": "stat",
        "title": "Docker Standard - CPU",
        "description": "Current CPU usage percentage",
        "gridPos": {"h": 5, "w": 4, "x": 0, "y": 14},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
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
            "unit": "percent",
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
        "id": 5,
        "type": "stat",
        "title": "Docker Standard - RAM",
        "description": "Current memory usage",
        "gridPos": {"h": 5, "w": 4, "x": 4, "y": 14},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-docker\"} / 1024 / 1024",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
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
            "unit": "decmbytes",
            "decimals": 2,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 100, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 6,
        "type": "stat",
        "title": "Docker MicroVM - CPU",
        "description": "Current CPU usage percentage",
        "gridPos": {"h": 5, "w": 4, "x": 8, "y": 14},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
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
            "unit": "percent",
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
        "title": "Docker MicroVM - RAM",
        "description": "Current memory usage",
        "gridPos": {"h": 5, "w": 4, "x": 12, "y": 14},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-microvm\"} / 1024 / 1024",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
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
            "unit": "decmbytes",
            "decimals": 2,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 100, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 8,
        "type": "stat",
        "title": "Docker Minimal - CPU",
        "description": "Current CPU usage percentage",
        "gridPos": {"h": 5, "w": 4, "x": 16, "y": 14},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
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
            "unit": "percent",
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
        "title": "Docker Minimal - RAM",
        "description": "Current memory usage",
        "gridPos": {"h": 5, "w": 4, "x": 20, "y": 14},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
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
            "unit": "decmbytes",
            "decimals": 2,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 100, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 10,
        "type": "bargauge",
        "title": "Current CPU Comparison",
        "description": "Real-time CPU usage across all containers",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 19},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"optivolt-.*\"}[1m]) * 100",
            "legendFormat": "{{name}}",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true,
          "text": {"valueSize": 20}
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
                {"value": 50, "color": "yellow"},
                {"value": 80, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 11,
        "type": "bargauge",
        "title": "Current Memory Comparison",
        "description": "Real-time memory usage across all containers",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 19},
        "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_working_set_bytes{name=~\"optivolt-.*\"} / 1024 / 1024",
            "legendFormat": "{{name}}",
            "datasource": {"type": "prometheus", "uid": "'"$DATASOURCE_UID"'"}
          }
        ],
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true,
          "text": {"valueSize": 20}
        },
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "decimals": 2,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 100, "color": "red"}
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
  echo "✓ Real-time dashboard created successfully"
  echo "→ Access: http://localhost:3000/d/$DASHBOARD_UID"
  echo ""
  echo "Dashboard Features:"
  echo "  • Live CPU monitoring with rate() calculation"
  echo "  • Live memory monitoring from cAdvisor"
  echo "  • 6 stat panels showing current values"
  echo "  • 2 bargauge panels for instant comparison"
  echo "  • Auto-refresh every 5 seconds"
  echo ""
  echo "No vector() - Only REAL metrics from containers!"
else
  echo "✗ Error creating dashboard"
  exit 1
fi
