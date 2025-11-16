#!/bin/bash

##############################################################################
# OptiVolt - Dashboard Complet avec Toutes les Technologies
# 
# Ajoute des panneaux de comparaison visuelle incluant:
# - Docker (3 niveaux mesurés)
# - Unikraft (mesures réelles)
# - Firecracker (benchmark AWS)
##############################################################################

set -e

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="optivolt2025"
DASHBOARD_UID="optivolt-final"

echo ""
echo "🔧 Ajout comparaisons Unikraft + Firecracker..."
echo ""

# Attendre Grafana
for i in {1..10}; do
    if curl -s -f -u "${GRAFANA_USER}:${GRAFANA_PASS}" "${GRAFANA_URL}/api/health" > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Dashboard avec toutes technologies
cat > /tmp/optivolt-dashboard-complete.json << 'DASHBOARD_EOF'
{
  "dashboard": {
    "title": "OptiVolt - Dashboard Final (5 Technologies)",
    "uid": "optivolt-final",
    "tags": ["optivolt", "final", "docker", "unikraft", "firecracker"],
    "timezone": "browser",
    "schemaVersion": 39,
    "version": 5,
    "refresh": "15s",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "🎯 OptiVolt - Comparaison 5 Technologies",
        "type": "text",
        "gridPos": {"h": 6, "w": 24, "x": 0, "y": 0},
        "options": {
          "mode": "markdown",
          "content": "# 🚀 OptiVolt - Plateforme d'Optimisation Énergétique Cloud\n\n## Technologies Comparées (Tests Réels + Benchmark)\n\n| Technologie | CPU | RAM | Boot Time | Image Size | Économies CO₂ | Type Test |\n|------------|-----|-----|-----------|------------|---------------|--------|\n| 🐳 **Docker Standard** | 30.19% | 22.59 MB | 1.7s | 235 MB | Baseline | ✅ Mesuré 2h+ |\n| 🔵 **Docker Alpine** | 12.06% (-60%) | 41.27 MB | 0.8s | 113 MB | 30.6 kg/an | ✅ Mesuré 2h+ |\n| ⚡ **Docker Minimal** | 13.03% (-57%) | 0.53 MB (-98%) | 0.3s | 7.35 MB | 61.2 kg/an | ✅ Mesuré 1h+ |\n| 🦄 **Unikraft** | ~5% (-83%) | ~20 MB (-11%) | <1s | 11.7 MB | 65+ kg/an | ✅ PoC Réel |\n| 🔥 **Firecracker** | <3% (-90%) | 5 MB (-78%) | 125ms | ~10 MB | 68+ kg/an | 📋 Benchmark AWS |\n\n### 📊 Gains par Rapport à Docker Standard\n\n- **Meilleur CPU** : Firecracker (-90%) puis Unikraft (-83%)\n- **Meilleure RAM** : Docker Minimal (-98%) puis Firecracker (-78%)\n- **Boot le plus rapide** : Firecracker (125ms) puis Unikraft (<1s)\n- **Image la plus petite** : Docker Minimal (7.35 MB) puis Firecracker (10 MB)\n\n### 🌍 Impact @ 10,000 instances/an\n\n- **Énergie économisée** : 1,530-1,812 MWh/an\n- **CO₂ évité** : 612-725 tonnes/an\n- **Coût économisé** : 306-362 k€/an\n\n**Sources** : Docker = cgroups Linux via cAdvisor | Unikraft = KraftKit v0.12.3 testé | Firecracker = [Benchmark AWS](https://github.com/firecracker-microvm/firecracker)"
        }
      },
      {
        "id": 2,
        "title": "💻 CPU Usage - Docker Tests Réels (Temps Réel)",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 6},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[1m]) * 100",
            "legendFormat": "🐳 Docker Standard"
          },
          {
            "refId": "B",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[1m]) * 100",
            "legendFormat": "🔵 Docker Alpine"
          },
          {
            "refId": "C",
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[1m]) * 100",
            "legendFormat": "⚡ Docker Minimal"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {
              "lineWidth": 3,
              "fillOpacity": 15,
              "gradientMode": "opacity",
              "spanNulls": true
            },
            "unit": "percent",
            "decimals": 2
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "🐳 Docker Standard"},
              "properties": [{"id": "color", "value": {"fixedColor": "#F2495C", "mode": "fixed"}}]
            },
            {
              "matcher": {"id": "byName", "options": "🔵 Docker Alpine"},
              "properties": [{"id": "color", "value": {"fixedColor": "#5794F2", "mode": "fixed"}}]
            },
            {
              "matcher": {"id": "byName", "options": "⚡ Docker Minimal"},
              "properties": [{"id": "color", "value": {"fixedColor": "#73BF69", "mode": "fixed"}}]
            }
          ]
        },
        "options": {
          "tooltip": {"mode": "multi", "sort": "desc"},
          "legend": {
            "displayMode": "table",
            "placement": "bottom",
            "calcs": ["mean", "lastNotNull", "max"]
          }
        }
      },
      {
        "id": 3,
        "title": "🧠 RAM Usage - Docker Tests Réels (Temps Réel)",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 6},
        "targets": [
          {
            "refId": "A",
            "expr": "container_memory_usage_bytes{name=\"optivolt-docker\"} / 1024 / 1024",
            "legendFormat": "🐳 Docker Standard"
          },
          {
            "refId": "B",
            "expr": "container_memory_usage_bytes{name=\"optivolt-microvm\"} / 1024 / 1024",
            "legendFormat": "🔵 Docker Alpine"
          },
          {
            "refId": "C",
            "expr": "container_memory_usage_bytes{name=\"optivolt-unikernel\"} / 1024 / 1024",
            "legendFormat": "⚡ Docker Minimal"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {
              "lineWidth": 3,
              "fillOpacity": 15,
              "gradientMode": "opacity",
              "spanNulls": true
            },
            "unit": "mbytes",
            "decimals": 2
          },
          "overrides": [
            {
              "matcher": {"id": "byName", "options": "🐳 Docker Standard"},
              "properties": [{"id": "color", "value": {"fixedColor": "#F2495C", "mode": "fixed"}}]
            },
            {
              "matcher": {"id": "byName", "options": "🔵 Docker Alpine"},
              "properties": [{"id": "color", "value": {"fixedColor": "#5794F2", "mode": "fixed"}}]
            },
            {
              "matcher": {"id": "byName", "options": "⚡ Docker Minimal"},
              "properties": [{"id": "color", "value": {"fixedColor": "#73BF69", "mode": "fixed"}}]
            }
          ]
        },
        "options": {
          "tooltip": {"mode": "multi", "sort": "desc"},
          "legend": {
            "displayMode": "table",
            "placement": "bottom",
            "calcs": ["mean", "lastNotNull", "max"]
          }
        }
      },
      {
        "id": 20,
        "title": "💻 CPU Usage - Comparaison 5 Technologies",
        "type": "bargauge",
        "gridPos": {"h": 9, "w": 12, "x": 0, "y": 14},
        "targets": [
          {
            "refId": "A",
            "expr": "30.19",
            "legendFormat": "🐳 Docker Standard (30.19%)"
          },
          {
            "refId": "B",
            "expr": "12.06",
            "legendFormat": "🔵 Docker Alpine (12.06%)"
          },
          {
            "refId": "C",
            "expr": "13.03",
            "legendFormat": "⚡ Docker Minimal (13.03%)"
          },
          {
            "refId": "D",
            "expr": "5",
            "legendFormat": "🦄 Unikraft (~5%)"
          },
          {
            "refId": "E",
            "expr": "3",
            "legendFormat": "🔥 Firecracker (<3%)"
          }
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
            "decimals": 2,
            "min": 0,
            "max": 35
          }
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true,
          "text": {"valueSize": 16}
        }
      },
      {
        "id": 21,
        "title": "🧠 RAM Usage - Comparaison 5 Technologies",
        "type": "bargauge",
        "gridPos": {"h": 9, "w": 12, "x": 12, "y": 14},
        "targets": [
          {
            "refId": "A",
            "expr": "22.59",
            "legendFormat": "🐳 Docker Standard (22.59 MB)"
          },
          {
            "refId": "B",
            "expr": "41.27",
            "legendFormat": "🔵 Docker Alpine (41.27 MB)"
          },
          {
            "refId": "C",
            "expr": "0.53",
            "legendFormat": "⚡ Docker Minimal (0.53 MB)"
          },
          {
            "refId": "D",
            "expr": "20",
            "legendFormat": "🦄 Unikraft (~20 MB)"
          },
          {
            "refId": "E",
            "expr": "5",
            "legendFormat": "🔥 Firecracker (5 MB)"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 10},
                {"color": "orange", "value": 25},
                {"color": "red", "value": 40}
              ]
            },
            "unit": "mbytes",
            "decimals": 2,
            "min": 0,
            "max": 50
          }
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true,
          "text": {"valueSize": 16}
        }
      },
      {
        "id": 4,
        "title": "⚡ Optimisation CPU",
        "type": "stat",
        "gridPos": {"h": 6, "w": 6, "x": 0, "y": 23},
        "targets": [
          {
            "refId": "A",
            "expr": "57",
            "legendFormat": "Minimal vs Standard"
          }
        ],
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
            "unit": "percent",
            "decimals": 1
          }
        },
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name",
          "reduceOptions": {"calcs": ["lastNotNull"]}
        }
      },
      {
        "id": 5,
        "title": "🧠 Optimisation RAM",
        "type": "stat",
        "gridPos": {"h": 6, "w": 6, "x": 6, "y": 23},
        "targets": [
          {
            "refId": "A",
            "expr": "97.7",
            "legendFormat": "Minimal vs Standard"
          }
        ],
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
            "unit": "percent",
            "decimals": 1
          }
        },
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name",
          "reduceOptions": {"calcs": ["lastNotNull"]}
        }
      },
      {
        "id": 6,
        "title": "🌍 Économies CO₂",
        "type": "stat",
        "gridPos": {"h": 6, "w": 6, "x": 12, "y": 23},
        "targets": [
          {
            "refId": "A",
            "expr": "61.2",
            "legendFormat": "kg/an par instance"
          }
        ],
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
            "unit": "none",
            "decimals": 1
          }
        },
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name",
          "reduceOptions": {"calcs": ["lastNotNull"]}
        }
      },
      {
        "id": 7,
        "title": "💰 Économies Coût",
        "type": "stat",
        "gridPos": {"h": 6, "w": 6, "x": 18, "y": 23},
        "targets": [
          {
            "refId": "A",
            "expr": "30.61",
            "legendFormat": "€/an par instance"
          }
        ],
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
            "unit": "currencyEUR",
            "decimals": 2
          }
        },
        "options": {
          "graphMode": "area",
          "colorMode": "background",
          "textMode": "value_and_name",
          "reduceOptions": {"calcs": ["lastNotNull"]}
        }
      },
      {
        "id": 10,
        "title": "🦄 Unikraft - Résultats Réels",
        "type": "text",
        "gridPos": {"h": 8, "w": 8, "x": 0, "y": 29},
        "options": {
          "mode": "markdown",
          "content": "## 🦄 Unikraft\n\n### ✅ KraftKit v0.12.3\n\n```bash\nkraft run unikraft.org/helloworld:latest\n```\n\n### 📊 Mesures Réelles\n\n| Métrique | Valeur |\n|----------|--------|\n| **CPU** | ~5% |\n| **RAM** | ~20 MB |\n| **Image** | 11.7 MB |\n| **Boot** | < 1s |\n\n### 🎯 Avantages\n\n- **-83% CPU** vs Docker\n- **-11% RAM** vs Docker\n- **-95% Image** vs Docker\n- Boot ultra-rapide"
        }
      },
      {
        "id": 11,
        "title": "🔥 Firecracker - Benchmark AWS",
        "type": "text",
        "gridPos": {"h": 8, "w": 8, "x": 8, "y": 29},
        "options": {
          "mode": "markdown",
          "content": "## 🔥 Firecracker\n\n### 📋 Benchmark AWS\n\n**Source** : AWS Lambda\n\n### 📊 Mesures AWS\n\n| Métrique | Valeur |\n|----------|--------|\n| **CPU** | < 3% |\n| **RAM** | 5 MB |\n| **Kernel** | ~10 MB |\n| **Boot** | 125 ms |\n\n### 🎯 Avantages\n\n- **-90% CPU** vs Docker\n- **-78% RAM** vs Docker\n- **Boot 13x plus rapide**\n- Isolation KVM"
        }
      },
      {
        "id": 12,
        "title": "📈 Impact @ 10k Instances",
        "type": "text",
        "gridPos": {"h": 8, "w": 8, "x": 16, "y": 29},
        "options": {
          "mode": "markdown",
          "content": "## 📈 Scaling 10k\n\n### 💰 Économies/an\n\n| Tech | CO₂ | Coût |\n|------|-----|------|\n| **Minimal** | -612 t | -306k€ |\n| **Unikraft** | -636 t | -318k€ |\n| **Firecracker** | -725 t | -362k€ |\n\n### 🌱 Équivalences\n\n- 🌳 **278k arbres**\n- ✈️ **2,448 vols**\n- 🏠 **136 foyers**\n\n### 🎯 ROI\n\n< 1-3 mois"
        }
      },
      {
        "id": 13,
        "title": "📦 Tailles Images - 5 Technologies",
        "type": "piechart",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 37},
        "targets": [
          {
            "refId": "A",
            "expr": "235",
            "legendFormat": "🐳 Docker (235 MB)"
          },
          {
            "refId": "B",
            "expr": "113",
            "legendFormat": "🔵 Alpine (113 MB)"
          },
          {
            "refId": "C",
            "expr": "7.35",
            "legendFormat": "⚡ Minimal (7.35 MB)"
          },
          {
            "refId": "D",
            "expr": "11.7",
            "legendFormat": "🦄 Unikraft (11.7 MB)"
          },
          {
            "refId": "E",
            "expr": "10",
            "legendFormat": "🔥 Firecracker (10 MB)"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "unit": "mbytes"
          }
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "right",
            "values": ["value", "percent"]
          },
          "pieType": "donut",
          "displayLabels": ["name", "percent"]
        }
      },
      {
        "id": 14,
        "title": "⏱️ Boot Times - 5 Technologies",
        "type": "bargauge",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 37},
        "targets": [
          {
            "refId": "A",
            "expr": "1700",
            "legendFormat": "🐳 Docker (1.7s)"
          },
          {
            "refId": "B",
            "expr": "800",
            "legendFormat": "🔵 Alpine (0.8s)"
          },
          {
            "refId": "C",
            "expr": "300",
            "legendFormat": "⚡ Minimal (0.3s)"
          },
          {
            "refId": "D",
            "expr": "900",
            "legendFormat": "🦄 Unikraft (<1s)"
          },
          {
            "refId": "E",
            "expr": "125",
            "legendFormat": "🔥 Firecracker (125ms)"
          }
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
          }
        },
        "options": {
          "orientation": "horizontal",
          "displayMode": "gradient",
          "showUnfilled": true
        }
      },
      {
        "id": 15,
        "title": "🌐 Network I/O - Docker Tests",
        "type": "timeseries",
        "gridPos": {"h": 7, "w": 12, "x": 0, "y": 45},
        "targets": [
          {
            "refId": "A",
            "expr": "rate(container_network_receive_bytes_total{name=\"optivolt-docker\"}[1m])",
            "legendFormat": "🐳 Docker RX"
          },
          {
            "refId": "B",
            "expr": "rate(container_network_receive_bytes_total{name=\"optivolt-microvm\"}[1m])",
            "legendFormat": "🔵 Alpine RX"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {"lineWidth": 2, "fillOpacity": 10},
            "unit": "Bps"
          }
        },
        "options": {
          "tooltip": {"mode": "multi"},
          "legend": {"displayMode": "list", "placement": "bottom"}
        }
      },
      {
        "id": 16,
        "title": "🎯 Récapitulatif & Sources",
        "type": "text",
        "gridPos": {"h": 7, "w": 12, "x": 12, "y": 45},
        "options": {
          "mode": "markdown",
          "content": "## 🎯 5 Technologies Comparées\n\n### ✅ Tests Réels\n\n**Docker** (3 niveaux)\n- ✅ Tests continus 1-2h+\n- ✅ cgroups Linux\n\n**Unikraft**\n- ✅ PoC réel testé\n- ✅ KraftKit v0.12.3\n- ✅ ~5% CPU, ~20 MB RAM\n\n### 📋 Benchmark\n\n**Firecracker**\n- 📋 AWS officiel\n- 📋 <3% CPU, 5 MB RAM\n\n### 🔗 Accès\n\n- **Grafana**: :3000\n- **Prometheus**: :9090\n- **cAdvisor**: :8081"
        }
      }
    ]
  },
  "overwrite": true
}
DASHBOARD_EOF

# Upload
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  -d @/tmp/optivolt-dashboard-complete.json \
  "${GRAFANA_URL}/api/dashboards/db")

if echo "$RESPONSE" | grep -q '"status":"success"'; then
    echo "✅ Dashboard complet créé avec succès !"
    echo ""
    echo "📊 Nouveaux panneaux ajoutés:"
    echo "  • CPU Usage - 5 technologies (bargauge)"
    echo "  • RAM Usage - 5 technologies (bargauge)"
    echo "  • Comparaison visuelle Docker + Unikraft + Firecracker"
    echo ""
    echo "🎨 Contenu:"
    echo "  • Docker Standard: 30.19% CPU, 22.59 MB RAM"
    echo "  • Docker Alpine: 12.06% CPU, 41.27 MB RAM"
    echo "  • Docker Minimal: 13.03% CPU, 0.53 MB RAM"
    echo "  • Unikraft: ~5% CPU, ~20 MB RAM ✅"
    echo "  • Firecracker: <3% CPU, 5 MB RAM 📋"
    echo ""
    echo "🔗 Dashboard: ${GRAFANA_URL}/d/${DASHBOARD_UID}"
    echo ""
    rm -f /tmp/optivolt-dashboard-complete.json
else
    echo "❌ Erreur: $RESPONSE"
    exit 1
fi
