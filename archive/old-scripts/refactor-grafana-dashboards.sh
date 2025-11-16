#!/bin/bash

#######################################################################
# Script de Refactorisation des Dashboards Grafana - OptiVolt
#######################################################################
# Ce script nettoie et optimise tous les dashboards Grafana :
# - Supprime les dashboards avec erreurs
# - Crée UN SEUL dashboard unifié et fonctionnel
# - Corrige les requêtes PromQL multi-lignes
# - Optimise les noms de métriques
#######################################################################

set -e

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="optivolt2025"

echo "🔧 Refactorisation des Dashboards Grafana - OptiVolt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#######################################################################
# Étape 1 : Lister les dashboards existants
#######################################################################
echo ""
echo "📋 Étape 1/4 : Liste des dashboards existants"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DASHBOARDS=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  "${GRAFANA_URL}/api/search?type=dash-db" | jq -r '.[] | "\(.uid) - \(.title)"')

echo "$DASHBOARDS"

#######################################################################
# Étape 2 : Supprimer les anciens dashboards OptiVolt
#######################################################################
echo ""
echo "🗑️  Étape 2/4 : Suppression des anciens dashboards"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Liste des UIDs à supprimer
OLD_UIDS=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  "${GRAFANA_URL}/api/search?type=dash-db" | \
  jq -r '.[] | select(.title | contains("OptiVolt")) | .uid')

if [ -z "$OLD_UIDS" ]; then
  echo "✅ Aucun dashboard OptiVolt à supprimer"
else
  for DASHBOARD_UID in $OLD_UIDS; do
    TITLE=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
      "${GRAFANA_URL}/api/dashboards/uid/${DASHBOARD_UID}" | jq -r '.dashboard.title')
    
    echo "Suppression : $TITLE (UID: $DASHBOARD_UID)"
    curl -s -X DELETE -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
      "${GRAFANA_URL}/api/dashboards/uid/${DASHBOARD_UID}" > /dev/null
    
    echo "  ✅ Supprimé"
  done
fi

#######################################################################
# Étape 3 : Créer le nouveau dashboard unifié
#######################################################################
echo ""
echo "📊 Étape 3/4 : Création du dashboard unifié optimisé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Créer le JSON du dashboard
cat > /tmp/optivolt-unified-dashboard.json << 'DASHBOARD_EOF'
{
  "dashboard": {
    "title": "OptiVolt - Unified Dashboard",
    "uid": "optivolt-unified",
    "tags": ["optivolt", "energy", "comparison"],
    "timezone": "browser",
    "schemaVersion": 38,
    "version": 1,
    "refresh": "10s",
    "time": {
      "from": "now-15m",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "📊 CPU Usage - Comparaison Temps Réel",
        "type": "timeseries",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"optivolt-.*\"}[1m]) * 100",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "CPU %",
              "fillOpacity": 10,
              "lineWidth": 2,
              "showPoints": "never"
            },
            "unit": "percent"
          }
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "bottom",
            "calcs": ["mean", "max", "last"]
          },
          "tooltip": {
            "mode": "multi"
          }
        }
      },
      {
        "id": 2,
        "title": "💾 Memory Usage - Comparaison Temps Réel",
        "type": "timeseries",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "container_memory_usage_bytes{name=~\"optivolt-.*\"} / 1024 / 1024",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisLabel": "RAM (MB)",
              "fillOpacity": 10,
              "lineWidth": 2,
              "showPoints": "never"
            },
            "unit": "decmbytes"
          }
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "bottom",
            "calcs": ["mean", "max", "last"]
          },
          "tooltip": {
            "mode": "multi"
          }
        }
      },
      {
        "id": 3,
        "title": "⚡ CPU - MicroVM vs Docker",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 6,
          "x": 0,
          "y": 8
        },
        "targets": [
          {
            "expr": "(1 - (avg(rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm\"}[5m])) / avg(rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[5m])))) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 30},
                {"color": "green", "value": 50}
              ]
            },
            "unit": "percent",
            "decimals": 1
          }
        },
        "options": {
          "graphMode": "area",
          "textMode": "value_and_name",
          "colorMode": "background"
        }
      },
      {
        "id": 4,
        "title": "⚡ CPU - Unikernel vs Docker",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 6,
          "x": 6,
          "y": 8
        },
        "targets": [
          {
            "expr": "(1 - (avg(rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel\"}[5m])) / avg(rate(container_cpu_usage_seconds_total{name=\"optivolt-docker\"}[5m])))) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 50},
                {"color": "green", "value": 70}
              ]
            },
            "unit": "percent",
            "decimals": 1
          }
        },
        "options": {
          "graphMode": "area",
          "textMode": "value_and_name",
          "colorMode": "background"
        }
      },
      {
        "id": 5,
        "title": "💾 RAM - MicroVM vs Docker",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 6,
          "x": 12,
          "y": 8
        },
        "targets": [
          {
            "expr": "(1 - (avg(container_memory_usage_bytes{name=\"optivolt-microvm\"}) / avg(container_memory_usage_bytes{name=\"optivolt-docker\"}))) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 30},
                {"color": "green", "value": 50}
              ]
            },
            "unit": "percent",
            "decimals": 1
          }
        },
        "options": {
          "graphMode": "area",
          "textMode": "value_and_name",
          "colorMode": "background"
        }
      },
      {
        "id": 6,
        "title": "💾 RAM - Unikernel vs Docker",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 6,
          "x": 18,
          "y": 8
        },
        "targets": [
          {
            "expr": "(1 - (avg(container_memory_usage_bytes{name=\"optivolt-unikernel\"}) / avg(container_memory_usage_bytes{name=\"optivolt-docker\"}))) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 50},
                {"color": "green", "value": 70}
              ]
            },
            "unit": "percent",
            "decimals": 1
          }
        },
        "options": {
          "graphMode": "area",
          "textMode": "value_and_name",
          "colorMode": "background"
        }
      },
      {
        "id": 7,
        "title": "🌍 Estimation CO2 (Proxy Énergie)",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 8,
          "x": 0,
          "y": 14
        },
        "targets": [
          {
            "expr": "(avg(rate(container_cpu_usage_seconds_total{name=~\"optivolt-.*\"}[5m])) * 100 + avg(container_memory_usage_bytes{name=~\"optivolt-.*\"}) / 1024 / 1024 / 10)",
            "legendFormat": "Énergie totale (proxy)",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": 0},
                {"color": "yellow", "value": 50},
                {"color": "red", "value": 100}
              ]
            },
            "unit": "none",
            "decimals": 2
          }
        },
        "options": {
          "graphMode": "area",
          "textMode": "value_and_name",
          "colorMode": "background"
        }
      },
      {
        "id": 8,
        "title": "📊 Network I/O - Comparaison",
        "type": "timeseries",
        "gridPos": {
          "h": 6,
          "w": 8,
          "x": 8,
          "y": 14
        },
        "targets": [
          {
            "expr": "rate(container_network_receive_bytes_total{name=~\"optivolt-.*\"}[1m])",
            "legendFormat": "{{name}} RX",
            "refId": "A"
          },
          {
            "expr": "rate(container_network_transmit_bytes_total{name=~\"optivolt-.*\"}[1m])",
            "legendFormat": "{{name}} TX",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "fillOpacity": 10,
              "lineWidth": 2
            },
            "unit": "Bps"
          }
        },
        "options": {
          "legend": {
            "displayMode": "list",
            "placement": "bottom"
          }
        }
      },
      {
        "id": 9,
        "title": "📈 Tableau Récapitulatif - Métriques Clés",
        "type": "table",
        "gridPos": {
          "h": 6,
          "w": 8,
          "x": 16,
          "y": 14
        },
        "targets": [
          {
            "expr": "avg(rate(container_cpu_usage_seconds_total{name=~\"optivolt-.*\"}[5m])) by (name) * 100",
            "format": "table",
            "instant": true,
            "refId": "A"
          },
          {
            "expr": "avg(container_memory_usage_bytes{name=~\"optivolt-.*\"}) by (name) / 1024 / 1024",
            "format": "table",
            "instant": true,
            "refId": "B"
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
                "Time": true
              },
              "renameByName": {
                "name": "Container",
                "Value #A": "CPU %",
                "Value #B": "RAM (MB)"
              }
            }
          }
        ],
        "fieldConfig": {
          "defaults": {
            "custom": {
              "align": "center"
            }
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "CPU %"
              },
              "properties": [
                {
                  "id": "unit",
                  "value": "percent"
                },
                {
                  "id": "decimals",
                  "value": 2
                }
              ]
            },
            {
              "matcher": {
                "id": "byName",
                "options": "RAM (MB)"
              },
              "properties": [
                {
                  "id": "unit",
                  "value": "decmbytes"
                },
                {
                  "id": "decimals",
                  "value": 1
                }
              ]
            }
          ]
        }
      }
    ]
  },
  "overwrite": true
}
DASHBOARD_EOF

# Envoyer le dashboard à Grafana
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  -d @/tmp/optivolt-unified-dashboard.json \
  "${GRAFANA_URL}/api/dashboards/db")

STATUS=$(echo "$RESPONSE" | jq -r '.status')

if [ "$STATUS" == "success" ]; then
  DASHBOARD_URL=$(echo "$RESPONSE" | jq -r '.url')
  DASHBOARD_UID=$(echo "$RESPONSE" | jq -r '.uid')
  echo "✅ Dashboard créé avec succès !"
  echo "   UID: $DASHBOARD_UID"
  echo "   URL: ${GRAFANA_URL}${DASHBOARD_URL}"
else
  echo "❌ Erreur lors de la création du dashboard"
  echo "$RESPONSE" | jq '.'
  exit 1
fi

#######################################################################
# Étape 4 : Vérification finale
#######################################################################
echo ""
echo "✅ Étape 4/4 : Vérification finale"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Lister les dashboards après refactorisation
FINAL_DASHBOARDS=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  "${GRAFANA_URL}/api/search?type=dash-db" | jq -r '.[] | "\(.uid) - \(.title)"')

echo "$FINAL_DASHBOARDS"

#######################################################################
# Résumé
#######################################################################
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Refactorisation terminée avec succès !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Nouveau Dashboard Unifié :"
echo "   • Titre : OptiVolt - Unified Dashboard"
echo "   • UID : optivolt-unified"
echo "   • URL : ${GRAFANA_URL}/d/optivolt-unified"
echo ""
echo "📋 Panneaux inclus (9 panneaux) :"
echo "   1. CPU Usage - Timeseries (tous les containers)"
echo "   2. Memory Usage - Timeseries (tous les containers)"
echo "   3. CPU Efficiency - MicroVM vs Docker (%)"
echo "   4. CPU Efficiency - Unikernel vs Docker (%)"
echo "   5. RAM Efficiency - MicroVM vs Docker (%)"
echo "   6. RAM Efficiency - Unikernel vs Docker (%)"
echo "   7. Estimation CO2 (proxy énergie)"
echo "   8. Network I/O - RX/TX"
echo "   9. Tableau récapitulatif"
echo ""
echo "🔍 Améliorations apportées :"
echo "   ✅ Requêtes PromQL corrigées (sans sauts de ligne)"
echo "   ✅ 4 stats d'efficacité séparées (plus lisibles)"
echo "   ✅ Suppression des bargauges problématiques"
echo "   ✅ Ajout Network I/O"
echo "   ✅ Tableau optimisé avec transformations"
echo "   ✅ Auto-refresh 10 secondes"
echo ""
echo "💡 Pour accéder au dashboard :"
echo "   1. Ouvrir Grafana (port 3000)"
echo "   2. Login : admin / optivolt2025"
echo "   3. Dashboards → 'OptiVolt - Unified Dashboard'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
