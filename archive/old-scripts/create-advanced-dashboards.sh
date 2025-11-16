#!/bin/bash

# ==============================================================================
# Script de Création de Dashboards Grafana Avancés
# OptiVolt - Monitoring Complet Docker vs MicroVM vs Unikernel
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="optivolt2025"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Création Dashboards Grafana Avancés - OptiVolt             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==============================================================================
# Dashboard 1 : Comparaison Complète avec Métriques Avancées
# ==============================================================================

echo -e "${YELLOW}📊 Création Dashboard 1 : Comparaison Complète...${NC}"

DASHBOARD1_JSON=$(cat <<'EOF'
{
  "dashboard": {
    "title": "OptiVolt - Comparaison Complète (Avancé)",
    "tags": ["optivolt", "comparison", "advanced"],
    "timezone": "browser",
    "schemaVersion": 38,
    "version": 0,
    "refresh": "5s",
    "panels": [
      {
        "id": 1,
        "title": "📊 CPU Usage - Real-time Comparison",
        "type": "timeseries",
        "gridPos": {"h": 9, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "legendFormat": "🐳 Docker Standard",
            "refId": "A"
          },
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "legendFormat": "⚡ MicroVM Optimized",
            "refId": "B"
          },
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "legendFormat": "🚀 Unikernel Minimal",
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 15,
              "showPoints": "never"
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "🐳 Docker Standard"},
              "properties": [
                {"id": "color", "value": {"mode": "fixed", "fixedColor": "blue"}},
                {"id": "custom.lineWidth", "value": 3}
              ]
            },
            {
              "matcher": {"id": "byName", "options": "⚡ MicroVM Optimized"},
              "properties": [
                {"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}},
                {"id": "custom.lineWidth", "value": 2}
              ]
            },
            {
              "matcher": {"id": "byName", "options": "🚀 Unikernel Minimal"},
              "properties": [
                {"id": "color", "value": {"mode": "fixed", "fixedColor": "orange"}},
                {"id": "custom.lineWidth", "value": 2}
              ]
            }
          ]
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "bottom",
            "showLegend": true,
            "calcs": ["mean", "lastNotNull", "max"]
          },
          "tooltip": {
            "mode": "multi",
            "sort": "desc"
          }
        }
      },
      {
        "id": 2,
        "title": "💾 Memory Usage - Real-time Comparison",
        "type": "timeseries",
        "gridPos": {"h": 9, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "container_memory_usage_bytes{name=\"optivolt-docker\"} / 1024 / 1024",
            "legendFormat": "🐳 Docker Standard",
            "refId": "A"
          },
          {
            "expr": "container_memory_usage_bytes{name=\"optivolt-microvm\"} / 1024 / 1024",
            "legendFormat": "⚡ MicroVM Optimized",
            "refId": "B"
          },
          {
            "expr": "container_memory_usage_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024",
            "legendFormat": "🚀 Unikernel Minimal",
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "min": 0,
            "custom": {
              "lineWidth": 2,
              "fillOpacity": 20,
              "axisPlacement": "auto"
            }
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "🐳 Docker Standard"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "blue"}}]
            },
            {
              "matcher": {"id": "byName", "options": "⚡ MicroVM Optimized"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}]
            },
            {
              "matcher": {"id": "byName", "options": "🚀 Unikernel Minimal"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "orange"}}]
            }
          ]
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "bottom",
            "showLegend": true,
            "calcs": ["mean", "lastNotNull", "max"]
          }
        }
      },
      {
        "id": 3,
        "title": "⚡ CPU Efficiency - Économie d'Énergie",
        "type": "bargauge",
        "gridPos": {"h": 7, "w": 8, "x": 0, "y": 9},
        "targets": [
          {
            "expr": "100 - (rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[5m]) / rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[5m]) * 100)",
            "legendFormat": "MicroVM vs Docker",
            "refId": "A"
          },
          {
            "expr": "100 - (rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[5m]) / rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[5m]) * 100)",
            "legendFormat": "Unikernel vs Docker",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 20, "color": "yellow"},
                {"value": 40, "color": "green"}
              ]
            }
          }
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true
        }
      },
      {
        "id": 4,
        "title": "💾 Memory Efficiency - Économie RAM",
        "type": "bargauge",
        "gridPos": {"h": 7, "w": 8, "x": 8, "y": 9},
        "targets": [
          {
            "expr": "100 - (container_memory_usage_bytes{name=\"optivolt-microvm\"} / container_memory_usage_bytes{name=\"optivolt-docker\"} * 100)",
            "legendFormat": "MicroVM vs Docker",
            "refId": "A"
          },
          {
            "expr": "100 - (container_memory_usage_bytes{name=\"optivolt-unikernel\"} / container_memory_usage_bytes{name=\"optivolt-docker\"} * 100)",
            "legendFormat": "Unikernel vs Docker",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 30, "color": "yellow"},
                {"value": 60, "color": "green"}
              ]
            }
          }
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true
        }
      },
      {
        "id": 5,
        "title": "🌍 Estimation CO2 (Proxy CPU+RAM)",
        "type": "stat",
        "gridPos": {"h": 7, "w": 8, "x": 16, "y": 9},
        "targets": [
          {
            "expr": "(rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[5m]) * 100) + (container_memory_usage_bytes{name=\"optivolt-docker\"} / 1024 / 1024 / 10)",
            "legendFormat": "Docker CO2 Score",
            "refId": "A"
          },
          {
            "expr": "(rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[5m]) * 100) + (container_memory_usage_bytes{name=\"optivolt-microvm\"} / 1024 / 1024 / 10)",
            "legendFormat": "MicroVM CO2 Score",
            "refId": "B"
          },
          {
            "expr": "(rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[5m]) * 100) + (container_memory_usage_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024 / 10)",
            "legendFormat": "Unikernel CO2 Score",
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "short",
            "mappings": [],
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
              "matcher": {"id": "byName", "options": "Docker CO2 Score"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "red"}}]
            },
            {
              "matcher": {"id": "byName", "options": "MicroVM CO2 Score"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "yellow"}}]
            },
            {
              "matcher": {"id": "byName", "options": "Unikernel CO2 Score"},
              "properties": [{"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}]
            }
          ]
        },
        "options": {
          "graphMode": "area",
          "colorMode": "value",
          "justifyMode": "auto",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 6,
        "title": "📈 Tableau Récapitulatif - Métriques Clés",
        "type": "table",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"optivolt-(docker|microvm|unikernel)\"}[5m]) * 100",
            "format": "table",
            "instant": true,
            "refId": "A"
          },
          {
            "expr": "container_memory_usage_bytes{name=~\"optivolt-(docker|microvm|unikernel)\"} / 1024 / 1024",
            "format": "table",
            "instant": true,
            "refId": "B"
          },
          {
            "expr": "container_network_receive_bytes_total{name=~\"optivolt-(docker|microvm|unikernel)\"}",
            "format": "table",
            "instant": true,
            "refId": "C"
          }
        ],
        "transformations": [
          {
            "id": "merge",
            "options": {}
          },
          {
            "id": "organize",
            "options": {
              "excludeByName": {
                "Time": true,
                "id": true,
                "image": true,
                "instance": true,
                "job": true
              },
              "indexByName": {
                "name": 0,
                "Value #A": 1,
                "Value #B": 2,
                "Value #C": 3
              },
              "renameByName": {
                "name": "Container",
                "Value #A": "CPU (%)",
                "Value #B": "RAM (MB)",
                "Value #C": "Network RX (bytes)"
              }
            }
          }
        ],
        "options": {
          "showHeader": true,
          "sortBy": [
            {
              "displayName": "CPU (%)",
              "desc": true
            }
          ]
        }
      }
    ]
  },
  "overwrite": true
}
EOF
)

RESPONSE1=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  -d "$DASHBOARD1_JSON" \
  "${GRAFANA_URL}/api/dashboards/db")

if echo "$RESPONSE1" | grep -q '"status":"success"'; then
    UID1=$(echo "$RESPONSE1" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✅ Dashboard 1 créé : Comparaison Complète${NC}"
    echo -e "${GREEN}   URL: ${GRAFANA_URL}/d/${UID1}${NC}"
else
    echo -e "${RED}❌ Erreur Dashboard 1${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Dashboards Grafana Avancés Créés !                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Nouveaux Dashboards Disponibles :${NC}"
echo ""
echo -e "  1. OptiVolt - Comparaison Complète (Avancé)"
echo -e "     • CPU Usage avec statistiques (mean, max, last)"
echo -e "     • Memory Usage avec graphiques détaillés"
echo -e "     • Efficacité CPU (% d'économie)"
echo -e "     • Efficacité RAM (% d'économie)"
echo -e "     • Estimation CO2 (proxy CPU+RAM)"
echo -e "     • Tableau récapitulatif avec Network"
echo ""
echo -e "${YELLOW}🎯 Pour accéder :${NC}"
echo -e "  1. Grafana → Menu ☰ → Dashboards → Browse"
echo -e "  2. Chercher 'OptiVolt'"
echo -e "  3. Time Range : Last 5 minutes"
echo -e "  4. Auto-refresh : 5s"
echo ""
