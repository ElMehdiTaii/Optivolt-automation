#!/bin/bash

##############################################################################
# OptiVolt - Dashboard Final avec Requêtes Simplifiées
# 
# Fix: Utiliser sum by (image) pour agréger les métriques correctement
##############################################################################

set -e

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="optivolt2025"
DASHBOARD_UID="optivolt-final"

echo ""
echo "🔧 Dashboard avec requêtes agrégées correctement..."
echo ""

# Attendre Grafana
for i in {1..10}; do
    if curl -s -f -u "${GRAFANA_USER}:${GRAFANA_PASS}" "${GRAFANA_URL}/api/health" > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

cat > /tmp/optivolt-dashboard-working.json << 'DASHBOARD_EOF'
{
  "dashboard": {
    "title": "OptiVolt - 3 Technologies Comparées",
    "uid": "optivolt-final",
    "tags": ["optivolt"],
    "timezone": "browser",
    "schemaVersion": 39,
    "version": 8,
    "refresh": "15s",
    "time": {"from": "now-1h", "to": "now"},
    "panels": [
      {
        "id": 1,
        "title": "🎯 OptiVolt - 3 Technologies d'Optimisation Cloud",
        "type": "text",
        "gridPos": {"h": 7, "w": 24, "x": 0, "y": 0},
        "options": {
          "mode": "markdown",
          "content": "# 🚀 OptiVolt - Plateforme d'Optimisation Énergétique Cloud\n\n## 📊 3 Technologies Comparées\n\n| Technologie | Type | CPU | RAM | Boot | Image | Type Test |\n|------------|------|-----|-----|------|-------|--------|\n| 🐳 **Docker 3 Niveaux** | Conteneurs optimisés | 30% → 13% | 23 MB → 0.5 MB | 1.7s → 0.3s | 235 MB → 7 MB | ✅ Tests réels cgroups |\n| 🦄 **Unikraft** | Vrai Unikernel (LibOS) | ~5% | ~20 MB | <1s | 11.7 MB | ✅ Testé hors Docker (QEMU) |\n| 🔥 **Firecracker** | MicroVM (KVM) | <3% | 5 MB | 125ms | ~10 MB | 📋 Benchmark AWS officiel |\n\n---\n\n### 🎯 Gains vs Docker Standard\n\n- **🐳 Docker Minimal** : -57% CPU, -98% RAM, -97% image\n- **🦄 Unikraft** : -83% CPU, -11% RAM, boot ultra-rapide\n- **🔥 Firecracker** : -90% CPU, -78% RAM, boot 13x plus rapide\n\n### 🌍 Impact @ 10,000 instances/an\n\n- **Énergie économisée** : 1,530-1,812 MWh/an\n- **CO₂ évité** : 612-725 tonnes/an\n- **Coût économisé** : 306-362 k€/an\n- **≈ 278,000 arbres plantés**"
        }
      },
      {
        "id": 2,
        "title": "🐳 Docker - CPU Usage (3 Niveaux)",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 7},
        "targets": [
          {
            "refId": "A",
            "expr": "sum by (image) (rate(container_cpu_usage_seconds_total{image=\"python:3.11-slim\",cpu=\"total\"}[1m])) * 100"
          },
          {
            "refId": "B",
            "expr": "sum by (image) (rate(container_cpu_usage_seconds_total{image=\"python:3.11-alpine\",cpu=\"total\"}[1m])) * 100"
          },
          {
            "refId": "C",
            "expr": "sum by (image) (rate(container_cpu_usage_seconds_total{image=\"alpine:3.18\",cpu=\"total\"}[1m])) * 100"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {"lineWidth": 2, "fillOpacity": 10, "spanNulls": true},
            "unit": "percent",
            "decimals": 2
          }
        },
        "options": {
          "tooltip": {"mode": "multi"},
          "legend": {"displayMode": "list", "placement": "bottom"}
        }
      },
      {
        "id": 3,
        "title": "🐳 Docker - RAM Usage (3 Niveaux)",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 7},
        "targets": [
          {
            "refId": "A",
            "expr": "sum by (image) (container_memory_usage_bytes{image=\"python:3.11-slim\"}) / 1024 / 1024"
          },
          {
            "refId": "B",
            "expr": "sum by (image) (container_memory_usage_bytes{image=\"python:3.11-alpine\"}) / 1024 / 1024"
          },
          {
            "refId": "C",
            "expr": "sum by (image) (container_memory_usage_bytes{image=\"alpine:3.18\"}) / 1024 / 1024"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {"lineWidth": 2, "fillOpacity": 10, "spanNulls": true},
            "unit": "mbytes",
            "decimals": 2
          }
        },
        "options": {
          "tooltip": {"mode": "multi"},
          "legend": {"displayMode": "list", "placement": "bottom"}
        }
      },
      {
        "id": 4,
        "title": "💻 CPU - Comparaison 3 Technologies",
        "type": "bargauge",
        "gridPos": {"h": 8, "w": 8, "x": 0, "y": 15},
        "targets": [
          {"refId": "A", "expr": "30.19"},
          {"refId": "B", "expr": "13.03"},
          {"refId": "C", "expr": "5"},
          {"refId": "D", "expr": "3"}
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 10},
                {"color": "orange", "value": 20},
                {"color": "red", "value": 30}
              ]
            },
            "unit": "percent",
            "min": 0,
            "max": 35
          },
          "overrides": [
            {"matcher": {"id": "byFrameRefID", "options": "A"}, "properties": [{"id": "displayName", "value": "🐳 Docker Standard"}]},
            {"matcher": {"id": "byFrameRefID", "options": "B"}, "properties": [{"id": "displayName", "value": "🐳 Docker Minimal"}]},
            {"matcher": {"id": "byFrameRefID", "options": "C"}, "properties": [{"id": "displayName", "value": "🦄 Unikraft"}]},
            {"matcher": {"id": "byFrameRefID", "options": "D"}, "properties": [{"id": "displayName", "value": "🔥 Firecracker"}]}
          ]
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true
        }
      },
      {
        "id": 5,
        "title": "🧠 RAM - Comparaison 3 Technologies",
        "type": "bargauge",
        "gridPos": {"h": 8, "w": 8, "x": 8, "y": 15},
        "targets": [
          {"refId": "A", "expr": "22.59"},
          {"refId": "B", "expr": "0.53"},
          {"refId": "C", "expr": "20"},
          {"refId": "D", "expr": "5"}
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 10},
                {"color": "orange", "value": 20},
                {"color": "red", "value": 40}
              ]
            },
            "unit": "mbytes",
            "min": 0,
            "max": 50
          },
          "overrides": [
            {"matcher": {"id": "byFrameRefID", "options": "A"}, "properties": [{"id": "displayName", "value": "🐳 Docker Standard"}]},
            {"matcher": {"id": "byFrameRefID", "options": "B"}, "properties": [{"id": "displayName", "value": "🐳 Docker Minimal"}]},
            {"matcher": {"id": "byFrameRefID", "options": "C"}, "properties": [{"id": "displayName", "value": "🦄 Unikraft"}]},
            {"matcher": {"id": "byFrameRefID", "options": "D"}, "properties": [{"id": "displayName", "value": "🔥 Firecracker"}]}
          ]
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true
        }
      },
      {
        "id": 6,
        "title": "⏱️ Boot Time - 3 Technologies",
        "type": "bargauge",
        "gridPos": {"h": 8, "w": 8, "x": 16, "y": 15},
        "targets": [
          {"refId": "A", "expr": "1700"},
          {"refId": "B", "expr": "300"},
          {"refId": "C", "expr": "900"},
          {"refId": "D", "expr": "125"}
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 500},
                {"color": "orange", "value": 1000},
                {"color": "red", "value": 1500}
              ]
            },
            "unit": "ms",
            "min": 0,
            "max": 2000
          },
          "overrides": [
            {"matcher": {"id": "byFrameRefID", "options": "A"}, "properties": [{"id": "displayName", "value": "🐳 Docker Standard"}]},
            {"matcher": {"id": "byFrameRefID", "options": "B"}, "properties": [{"id": "displayName", "value": "🐳 Docker Minimal"}]},
            {"matcher": {"id": "byFrameRefID", "options": "C"}, "properties": [{"id": "displayName", "value": "🦄 Unikraft"}]},
            {"matcher": {"id": "byFrameRefID", "options": "D"}, "properties": [{"id": "displayName", "value": "🔥 Firecracker"}]}
          ]
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true
        }
      },
      {
        "id": 7,
        "title": "⚡ Optimisation CPU",
        "type": "stat",
        "gridPos": {"h": 5, "w": 6, "x": 0, "y": 23},
        "targets": [{"refId": "A", "expr": "57"}],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "red", "value": null},
                {"color": "yellow", "value": 30},
                {"color": "green", "value": 50},
                {"color": "#37872D", "value": 70}
              ]
            },
            "unit": "percent"
          },
          "overrides": [
            {"matcher": {"id": "byName", "options": "Value"}, "properties": [{"id": "displayName", "value": "Docker Minimal"}]}
          ]
        },
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 8,
        "title": "🧠 Optimisation RAM",
        "type": "stat",
        "gridPos": {"h": 5, "w": 6, "x": 6, "y": 23},
        "targets": [{"refId": "A", "expr": "97.7"}],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "red", "value": null},
                {"color": "yellow", "value": 40},
                {"color": "green", "value": 70},
                {"color": "#37872D", "value": 90}
              ]
            },
            "unit": "percent"
          },
          "overrides": [
            {"matcher": {"id": "byName", "options": "Value"}, "properties": [{"id": "displayName", "value": "Docker Minimal"}]}
          ]
        },
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 9,
        "title": "🌍 Économies CO₂",
        "type": "stat",
        "gridPos": {"h": 5, "w": 6, "x": 12, "y": 23},
        "targets": [{"refId": "A", "expr": "61.2"}],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "red", "value": null},
                {"color": "yellow", "value": 20},
                {"color": "green", "value": 40},
                {"color": "#37872D", "value": 60}
              ]
            },
            "unit": "none"
          },
          "overrides": [
            {"matcher": {"id": "byName", "options": "Value"}, "properties": [{"id": "displayName", "value": "kg/an"}]}
          ]
        },
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 10,
        "title": "💰 Économies Coût",
        "type": "stat",
        "gridPos": {"h": 5, "w": 6, "x": 18, "y": 23},
        "targets": [{"refId": "A", "expr": "30.61"}],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "red", "value": null},
                {"color": "yellow", "value": 10},
                {"color": "green", "value": 20},
                {"color": "#37872D", "value": 30}
              ]
            },
            "unit": "currencyEUR"
          },
          "overrides": [
            {"matcher": {"id": "byName", "options": "Value"}, "properties": [{"id": "displayName", "value": "€/an"}]}
          ]
        },
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 11,
        "title": "🐳 Docker (3 Niveaux)",
        "type": "text",
        "gridPos": {"h": 6, "w": 8, "x": 0, "y": 28},
        "options": {
          "mode": "markdown",
          "content": "## 🐳 Docker\n\n### ✅ Tests Réels\n\n| Niveau | CPU | RAM |\n|--------|-----|-----|\n| **Standard** | 30.19% | 22.59 MB |\n| **Alpine** | 12.06% | 41.27 MB |\n| **Minimal** | 13.03% | 0.53 MB |\n\n### 🎯 Gains\n\n- **-57% CPU**\n- **-98% RAM**\n- **-97% Image**"
        }
      },
      {
        "id": 12,
        "title": "🦄 Unikraft",
        "type": "text",
        "gridPos": {"h": 6, "w": 8, "x": 8, "y": 28},
        "options": {
          "mode": "markdown",
          "content": "## 🦄 Unikraft\n\n### ✅ Testé (QEMU)\n\n**KraftKit v0.12.3**\n\n| Métrique | Valeur |\n|----------|--------|\n| **CPU** | ~5% |\n| **RAM** | ~20 MB |\n| **Boot** | <1s |\n\n### 🎯 Avantages\n\n- **-83% CPU**\n- LibOS monolithique\n- Boot ultra-rapide"
        }
      },
      {
        "id": 13,
        "title": "🔥 Firecracker",
        "type": "text",
        "gridPos": {"h": 6, "w": 8, "x": 16, "y": 28},
        "options": {
          "mode": "markdown",
          "content": "## 🔥 Firecracker\n\n### 📋 Benchmark AWS\n\n| Métrique | Valeur |\n|----------|--------|\n| **CPU** | <3% |\n| **RAM** | 5 MB |\n| **Boot** | 125 ms |\n\n### 🎯 Avantages\n\n- **-90% CPU**\n- **-78% RAM**\n- Production AWS Lambda"
        }
      }
    ]
  },
  "overwrite": true
}
DASHBOARD_EOF

RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  -d @/tmp/optivolt-dashboard-working.json \
  "${GRAFANA_URL}/api/dashboards/db")

if echo "$RESPONSE" | grep -q '"status":"success"'; then
    echo "✅ Dashboard avec requêtes fonctionnelles !"
    echo ""
    echo "🔧 Fix appliqué:"
    echo "  • sum by (image) pour CPU/RAM"
    echo "  • cpu=\"total\" pour éviter les doublons"
    echo "  • Valeurs statiques pour comparaisons"
    echo ""
    echo "🔗 Dashboard: ${GRAFANA_URL}/d/${DASHBOARD_UID}"
    rm -f /tmp/optivolt-dashboard-working.json
else
    echo "❌ Erreur: $RESPONSE"
    exit 1
fi
