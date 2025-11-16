#!/bin/bash

# ==============================================================================
# Script de Mise à Jour des Dashboards Grafana
# Met à jour les requêtes PromQL pour utiliser les bons noms de containers
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="optivolt2025"

echo -e "${YELLOW}🔄 Mise à jour des dashboards Grafana...${NC}"

# ==============================================================================
# Dashboard: OptiVolt - Docker vs MicroVM vs Unikernel
# ==============================================================================

DASHBOARD_JSON=$(cat <<'EOF'
{
  "dashboard": {
    "title": "OptiVolt - Docker vs MicroVM vs Unikernel",
    "tags": ["optivolt", "comparison", "benchmark"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "refresh": "10s",
    "panels": [
      {
        "id": 1,
        "title": "📊 CPU Usage - Containers Comparison",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "legendFormat": "Docker",
            "refId": "A"
          },
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "legendFormat": "MicroVM",
            "refId": "B"
          },
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "legendFormat": "Unikernel",
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 10
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "Docker"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "blue"}}]
            },
            {
              "matcher": {"id": "byName", "options": "MicroVM"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Unikernel"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "orange"}}]
            }
          ]
        },
        "options": {
          "legend": {
            "displayMode": "list",
            "placement": "bottom"
          }
        }
      },
      {
        "id": 2,
        "title": "💾 Memory Usage - Containers Comparison",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "container_memory_usage_bytes{name=\"optivolt-docker\"} / 1024 / 1024",
            "legendFormat": "Docker",
            "refId": "A"
          },
          {
            "expr": "container_memory_usage_bytes{name=\"optivolt-microvm\"} / 1024 / 1024",
            "legendFormat": "MicroVM",
            "refId": "B"
          },
          {
            "expr": "container_memory_usage_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024",
            "legendFormat": "Unikernel",
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 10
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "Docker"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "blue"}}]
            },
            {
              "matcher": {"id": "byName", "options": "MicroVM"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Unikernel"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "orange"}}]
            }
          ]
        },
        "options": {
          "legend": {
            "displayMode": "list",
            "placement": "bottom"
          }
        }
      },
      {
        "id": 3,
        "title": "🐳 Docker - Current CPU",
        "type": "gauge",
        "gridPos": {"h": 6, "w": 8, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 50, "color": "yellow"},
                {"value": 80, "color": "red"}
              ]
            },
            "max": 100,
            "min": 0
          }
        },
        "options": {
          "showThresholdLabels": false,
          "showThresholdMarkers": true
        }
      },
      {
        "id": 4,
        "title": "⚡ MicroVM - Current CPU",
        "type": "gauge",
        "gridPos": {"h": 6, "w": 8, "x": 8, "y": 8},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 30, "color": "yellow"},
                {"value": 60, "color": "red"}
              ]
            },
            "max": 100,
            "min": 0
          }
        },
        "options": {
          "showThresholdLabels": false,
          "showThresholdMarkers": true
        }
      },
      {
        "id": 5,
        "title": "🚀 Unikernel - Current CPU",
        "type": "gauge",
        "gridPos": {"h": 6, "w": 8, "x": 16, "y": 8},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 20, "color": "yellow"},
                {"value": 40, "color": "red"}
              ]
            },
            "max": 100,
            "min": 0
          }
        },
        "options": {
          "showThresholdLabels": false,
          "showThresholdMarkers": true
        }
      },
      {
        "id": 6,
        "title": "📈 Summary - CPU & Memory",
        "type": "table",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 14},
        "targets": [
          {
            "expr": "container_cpu_usage_seconds_total{name=~\"optivolt-(docker|microvm|unikernel)\"}",
            "format": "table",
            "instant": true,
            "refId": "A"
          },
          {
            "expr": "container_memory_usage_bytes{name=~\"optivolt-(docker|microvm|unikernel)\"}",
            "format": "table",
            "instant": true,
            "refId": "B"
          }
        ],
        "transformations": [
          {
            "id": "merge",
            "options": {}
          }
        ],
        "fieldConfig": {
          "defaults": {},
          "overrides": []
        }
      }
    ]
  },
  "overwrite": true
}
EOF
)

echo -e "${YELLOW}📤 Envoi du dashboard à Grafana...${NC}"

RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  -d "$DASHBOARD_JSON" \
  "${GRAFANA_URL}/api/dashboards/db")

if echo "$RESPONSE" | grep -q '"status":"success"'; then
    echo -e "${GREEN}✅ Dashboard mis à jour avec succès !${NC}"
    DASHBOARD_UID=$(echo "$RESPONSE" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}   UID: $DASHBOARD_UID${NC}"
    echo -e "${GREEN}   URL: ${GRAFANA_URL}/d/${DASHBOARD_UID}${NC}"
else
    echo -e "${RED}❌ Erreur lors de la mise à jour du dashboard${NC}"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Dashboard mis à jour pour les containers persistants !${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Noms de containers utilisés dans les requêtes PromQL :"
echo "  • optivolt-docker     (au lieu de optivolt-test-app)"
echo "  • optivolt-microvm    (au lieu de optivolt-microvm-test)"
echo "  • optivolt-unikernel  (au lieu de optivolt-unikernel-test)"
echo ""
echo "Ces containers doivent être lancés avec :"
echo "  bash scripts/start-benchmark-containers.sh"
echo ""
