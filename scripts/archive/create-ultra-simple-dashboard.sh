#!/bin/bash

set -e

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="optivolt2025"

echo "🔧 Création dashboard ULTRA-SIMPLE (format de base Grafana)..."

for i in {1..10}; do
    if curl -s -f -u "${GRAFANA_USER}:${GRAFANA_PASS}" "${GRAFANA_URL}/api/health" > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Dashboard minimal avec le format le plus basique possible
curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  "${GRAFANA_URL}/api/dashboards/db" \
  -d '{
  "dashboard": {
    "title": "OptiVolt - 3 Technologies",
    "uid": "optivolt-final",
    "version": 11,
    "refresh": "",
    "panels": [
      {
        "id": 1,
        "title": "🎯 OptiVolt - Résultats Mesurés",
        "type": "text",
        "gridPos": {"h": 6, "w": 24, "x": 0, "y": 0},
        "options": {
          "mode": "markdown",
          "content": "# 🚀 OptiVolt - Résultats Tests Réels (2h+ de mesures)\n\n| Technologie | CPU | RAM | Boot | Image | Test |\n|------------|-----|-----|------|-------|------|\n| 🐳 **Docker Standard** | 30.19% | 22.59 MB | 1.7s | 235 MB | ✅ Mesuré |\n| 🐳 **Docker Alpine** | 12.06% | 41.27 MB | 0.8s | 113 MB | ✅ Mesuré |\n| 🐳 **Docker Minimal** | 13.03% | 0.53 MB | 0.3s | 7.35 MB | ✅ Mesuré |\n| 🦄 **Unikraft** | ~5% | ~20 MB | <1s | 11.7 MB | ✅ Testé (QEMU) |\n| 🔥 **Firecracker** | <3% | 5 MB | 125ms | ~10 MB | 📋 AWS Benchmark |\n\n## 🎯 Optimisations vs Docker Standard\n\n- **CPU** : -57% (Docker Minimal), -83% (Unikraft), -90% (Firecracker)\n- **RAM** : -98% (Docker Minimal), -78% (Firecracker)\n- **Impact @ 10k instances** : 612-725 tonnes CO₂/an, 306-362 k€/an économisés"
        }
      },
      {
        "id": 2,
        "title": "💻 CPU Usage (%)",
        "type": "bargauge",
        "gridPos": {"h": 9, "w": 24, "x": 0, "y": 6},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [
          {"refId": "A", "expr": "vector(30.19)", "instant": true, "format": "time_series"},
          {"refId": "B", "expr": "vector(12.06)", "instant": true, "format": "time_series"},
          {"refId": "C", "expr": "vector(13.03)", "instant": true, "format": "time_series"},
          {"refId": "D", "expr": "vector(5)", "instant": true, "format": "time_series"},
          {"refId": "E", "expr": "vector(3)", "instant": true, "format": "time_series"}
        ],
        "transformations": [
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #A",
              "renamePattern": "🐳 Docker Standard (30.19%)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #B",
              "renamePattern": "🐳 Docker Alpine (12.06%)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #C",
              "renamePattern": "🐳 Docker Minimal (13.03%)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #D",
              "renamePattern": "🦄 Unikraft (~5%)"
            }
          },
          {
            "id": "renameByRegex",
            "options": {
              "regex": "Value #E",
              "renamePattern": "🔥 Firecracker (<3%)"
            }
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 35,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": null, "color": "green"},
                {"value": 10, "color": "yellow"},
                {"value": 20, "color": "orange"},
                {"value": 30, "color": "red"}
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
        "id": 3,
        "title": "🧠 RAM Usage (MB)",
        "type": "bargauge",
        "gridPos": {"h": 9, "w": 24, "x": 0, "y": 15},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [
          {"refId": "A", "expr": "vector(22.59)", "instant": true, "format": "time_series"},
          {"refId": "B", "expr": "vector(41.27)", "instant": true, "format": "time_series"},
          {"refId": "C", "expr": "vector(0.53)", "instant": true, "format": "time_series"},
          {"refId": "D", "expr": "vector(20)", "instant": true, "format": "time_series"},
          {"refId": "E", "expr": "vector(5)", "instant": true, "format": "time_series"}
        ],
        "transformations": [
          {"id": "renameByRegex", "options": {"regex": "Value #A", "renamePattern": "🐳 Docker Standard (22.59 MB)"}},
          {"id": "renameByRegex", "options": {"regex": "Value #B", "renamePattern": "🐳 Docker Alpine (41.27 MB)"}},
          {"id": "renameByRegex", "options": {"regex": "Value #C", "renamePattern": "🐳 Docker Minimal (0.53 MB)"}},
          {"id": "renameByRegex", "options": {"regex": "Value #D", "renamePattern": "🦄 Unikraft (20 MB)"}},
          {"id": "renameByRegex", "options": {"regex": "Value #E", "renamePattern": "🔥 Firecracker (5 MB)"}}
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "mbytes",
            "min": 0,
            "max": 50,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": null, "color": "green"},
                {"value": 10, "color": "yellow"},
                {"value": 25, "color": "orange"},
                {"value": 40, "color": "red"}
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
        "title": "⚡ Optimisation CPU",
        "type": "stat",
        "gridPos": {"h": 6, "w": 6, "x": 0, "y": 24},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"refId": "A", "expr": "vector(57)", "instant": true}],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": null, "color": "red"},
                {"value": 30, "color": "yellow"},
                {"value": 50, "color": "green"},
                {"value": 70, "color": "dark-green"}
              ]
            }
          },
          "overrides": [
            {"matcher": {"id": "byName", "options": "Value"}, "properties": [{"id": "displayName", "value": "Minimal vs Standard"}]}
          ]
        },
        "options": {
          "colorMode": "background",
          "graphMode": "none",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 5,
        "title": "🧠 Optimisation RAM",
        "type": "stat",
        "gridPos": {"h": 6, "w": 6, "x": 6, "y": 24},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"refId": "A", "expr": "vector(97.7)", "instant": true}],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "decimals": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": null, "color": "red"},
                {"value": 40, "color": "yellow"},
                {"value": 70, "color": "green"},
                {"value": 90, "color": "dark-green"}
              ]
            }
          },
          "overrides": [
            {"matcher": {"id": "byName", "options": "Value"}, "properties": [{"id": "displayName", "value": "Minimal vs Standard"}]}
          ]
        },
        "options": {
          "colorMode": "background",
          "graphMode": "none",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 6,
        "title": "🌍 Économies CO₂",
        "type": "stat",
        "gridPos": {"h": 6, "w": 6, "x": 12, "y": 24},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"refId": "A", "expr": "vector(61.2)", "instant": true}],
        "fieldConfig": {
          "defaults": {
            "unit": "none",
            "decimals": 1,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": null, "color": "red"},
                {"value": 20, "color": "yellow"},
                {"value": 40, "color": "green"},
                {"value": 60, "color": "dark-green"}
              ]
            }
          },
          "overrides": [
            {"matcher": {"id": "byName", "options": "Value"}, "properties": [{"id": "displayName", "value": "kg/an par instance"}]}
          ]
        },
        "options": {
          "colorMode": "background",
          "graphMode": "none",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 7,
        "title": "💰 Économies Coût",
        "type": "stat",
        "gridPos": {"h": 6, "w": 6, "x": 18, "y": 24},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"refId": "A", "expr": "vector(30.61)", "instant": true}],
        "fieldConfig": {
          "defaults": {
            "unit": "currencyEUR",
            "decimals": 2,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": null, "color": "red"},
                {"value": 10, "color": "yellow"},
                {"value": 20, "color": "green"},
                {"value": 30, "color": "dark-green"}
              ]
            }
          },
          "overrides": [
            {"matcher": {"id": "byName", "options": "Value"}, "properties": [{"id": "displayName", "value": "€/an par instance"}]}
          ]
        },
        "options": {
          "colorMode": "background",
          "graphMode": "none",
          "textMode": "value_and_name"
        }
      }
    ]
  },
  "overwrite": true
}' | jq -r '.status, .url' && echo "" && echo "✅ Dashboard créé avec format ultra-simple" && echo "🔗 http://localhost:3000/d/optivolt-final" && echo "" && echo "📊 Faites Ctrl+Shift+R dans le navigateur"
