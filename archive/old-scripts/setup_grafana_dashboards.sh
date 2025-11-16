#!/bin/bash

# ==============================================================================
# Configuration automatique Grafana pour OptiVolt Codespaces
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Configuration Grafana - OptiVolt Dashboards         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}\n"

# ==============================================================================
# Attendre que Grafana soit prêt
# ==============================================================================
echo -e "${YELLOW}[1/5] Vérification Grafana...${NC}"
for i in {1..30}; do
    if curl -s "$GRAFANA_URL/api/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Grafana actif${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}✗ Grafana non accessible${NC}"
        exit 1
    fi
    sleep 1
done

# ==============================================================================
# Créer datasource Prometheus si nécessaire
# ==============================================================================
echo -e "\n${YELLOW}[2/5] Configuration datasource Prometheus...${NC}"

DATASOURCE_ID=$(curl -s -X POST "$GRAFANA_URL/api/datasources" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://prometheus:9090",
        "access": "proxy",
        "isDefault": true,
        "jsonData": {
            "timeInterval": "15s"
        }
    }' 2>/dev/null | jq -r '.datasource.uid // .uid // empty' || echo "exists")

if [ "$DATASOURCE_ID" == "exists" ] || [ -z "$DATASOURCE_ID" ]; then
    echo -e "${YELLOW}  Datasource Prometheus déjà configurée${NC}"
else
    echo -e "${GREEN}✓ Datasource Prometheus créée (UID: $DATASOURCE_ID)${NC}"
fi

# ==============================================================================
# Créer Dashboard OptiVolt Comparison
# ==============================================================================
echo -e "\n${YELLOW}[3/5] Création Dashboard OptiVolt Comparison...${NC}"

cat > /tmp/grafana_dashboard.json <<'DASHBOARD'
{
  "dashboard": {
    "title": "OptiVolt - Docker vs MicroVM vs Unikernel",
    "tags": ["optivolt", "benchmark", "comparison"],
    "timezone": "browser",
    "refresh": "10s",
    "time": {
      "from": "now-5m",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "📊 CPU Usage - Containers Comparison",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"optivolt.*\"}[1m]) * 100",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "custom": {
              "axisLabel": "CPU %"
            }
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
            "expr": "container_memory_usage_bytes{name=~\"optivolt.*\"} / 1024 / 1024",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "decmbytes",
            "custom": {
              "axisLabel": "Memory (MB)"
            }
          }
        }
      },
      {
        "id": 3,
        "title": "Docker - Current CPU",
        "type": "stat",
        "gridPos": {"h": 6, "w": 8, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-test-app\"}[1m]) * 100",
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
            }
          }
        },
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 4,
        "title": "MicroVM - Current CPU",
        "type": "stat",
        "gridPos": {"h": 6, "w": 8, "x": 8, "y": 8},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-microvm-test\"}[1m]) * 100",
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
            }
          }
        },
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 5,
        "title": "Unikernel - Current CPU",
        "type": "stat",
        "gridPos": {"h": 6, "w": 8, "x": 16, "y": 8},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=\"optivolt-unikernel-test\"}[1m]) * 100",
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
            }
          }
        },
        "options": {
          "colorMode": "value",
          "graphMode": "area",
          "textMode": "value_and_name"
        }
      },
      {
        "id": 6,
        "title": "📈 All Containers - CPU & Memory Overview",
        "type": "table",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 14},
        "targets": [
          {
            "expr": "container_memory_usage_bytes{name=~\"optivolt.*\"}",
            "format": "table",
            "instant": true,
            "refId": "A"
          }
        ]
      }
    ]
  },
  "overwrite": true
}
DASHBOARD

DASHBOARD_RESULT=$(curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d @/tmp/grafana_dashboard.json 2>/dev/null)

if echo "$DASHBOARD_RESULT" | grep -q "success"; then
    DASHBOARD_UID=$(echo "$DASHBOARD_RESULT" | jq -r '.uid')
    echo -e "${GREEN}✓ Dashboard créé avec succès${NC}"
    echo -e "  UID: $DASHBOARD_UID"
else
    echo -e "${YELLOW}  Dashboard existe déjà ou erreur création${NC}"
fi

# ==============================================================================
# Créer Dashboard System Overview
# ==============================================================================
echo -e "\n${YELLOW}[4/5] Création Dashboard System Overview...${NC}"

cat > /tmp/grafana_system_dashboard.json <<'SYSTEM_DASH'
{
  "dashboard": {
    "title": "OptiVolt - System Metrics",
    "tags": ["optivolt", "system", "monitoring"],
    "timezone": "browser",
    "refresh": "5s",
    "panels": [
      {
        "id": 1,
        "title": "Node CPU Usage",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[1m])) * 100)",
            "legendFormat": "CPU Usage %",
            "refId": "A"
          }
        ]
      },
      {
        "id": 2,
        "title": "Node Memory Usage",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
            "legendFormat": "Memory Usage %",
            "refId": "A"
          }
        ]
      },
      {
        "id": 3,
        "title": "Total Containers Running",
        "type": "stat",
        "gridPos": {"h": 6, "w": 8, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "count(container_last_seen{name=~\"optivolt.*\"})",
            "refId": "A"
          }
        ],
        "options": {
          "colorMode": "value",
          "textMode": "value_and_name"
        }
      }
    ]
  },
  "overwrite": true
}
SYSTEM_DASH

curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d @/tmp/grafana_system_dashboard.json > /dev/null 2>&1

echo -e "${GREEN}✓ Dashboard System créé${NC}"

# ==============================================================================
# Afficher URL d'accès Codespaces
# ==============================================================================
echo -e "\n${YELLOW}[5/5] Informations d'accès...${NC}"

# Détecter URL Codespaces
CODESPACE_NAME="${CODESPACE_NAME:-unknown}"
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-/workspaces/Optivolt-automation}"

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Grafana Configuré !                         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}✅ Dashboards créés:${NC}"
echo -e "  1. OptiVolt - Docker vs MicroVM vs Unikernel"
echo -e "  2. OptiVolt - System Metrics"
echo ""

echo -e "${YELLOW}📍 Accès Grafana dans Codespaces:${NC}"
echo -e "\n  ${GREEN}Option 1 - Port Forwarding automatique:${NC}"
echo -e "    1. VS Code → PORTS (onglet en bas)"
echo -e "    2. Trouver port 3000 (Grafana)"
echo -e "    3. Cliquer sur l'icône 🌐 (globe)"
echo -e "    4. Ou copier l'URL affichée"
echo ""
echo -e "  ${GREEN}Option 2 - URL directe:${NC}"
echo -e "    https://<CODESPACE>-3000.app.github.dev"
echo -e "    (Remplacer <CODESPACE> par votre nom de codespace)"
echo ""
echo -e "  ${GREEN}Option 3 - Commande pour obtenir l'URL:${NC}"
echo -e "    gh codespace ports --codespace \$CODESPACE_NAME | grep 3000"
echo ""

echo -e "${YELLOW}🔐 Identifiants:${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}admin${NC}"
echo -e "  (Changer au premier login recommandé)"
echo ""

echo -e "${YELLOW}📊 Navigation:${NC}"
echo -e "  1. Login avec admin/admin"
echo -e "  2. Menu → Dashboards → Browse"
echo -e "  3. Chercher 'OptiVolt'"
echo -e "  4. Cliquer sur le dashboard"
echo ""

echo -e "${YELLOW}🔍 Requêtes Prometheus utiles:${NC}"
echo -e "  Menu → Explore → Datasource: Prometheus"
echo -e ""
echo -e "  ${BLUE}# CPU par container${NC}"
echo -e "  rate(container_cpu_usage_seconds_total{name=~\"optivolt.*\"}[1m])*100"
echo -e ""
echo -e "  ${BLUE}# Mémoire par container${NC}"
echo -e "  container_memory_usage_bytes{name=~\"optivolt.*\"}/1024/1024"
echo -e ""

# Vérifier les containers actifs
ACTIVE_CONTAINERS=$(docker ps --filter "name=optivolt" --format "{{.Names}}" | wc -l)
echo -e "${YELLOW}📦 Containers OptiVolt actifs: ${GREEN}$ACTIVE_CONTAINERS${NC}"
if [ "$ACTIVE_CONTAINERS" -gt 0 ]; then
    echo -e "  ${GREEN}✓ Métriques disponibles en temps réel${NC}"
    docker ps --filter "name=optivolt" --format "  - {{.Names}} ({{.Status}})"
else
    echo -e "  ${YELLOW}⚠ Aucun container actif${NC}"
    echo -e "  Lancer: ${BLUE}bash scripts/run_real_benchmark.sh 60${NC}"
fi

echo -e "\n${GREEN}✅ Configuration terminée !${NC}\n"
