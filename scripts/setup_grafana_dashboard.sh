#!/bin/bash

echo "========================================="
echo "  Configuration Dashboard Grafana"
echo "========================================="

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="optivolt2025"

echo ""
echo "📊 Création du dashboard OptiVolt..."

# Dashboard JSON
cat > /tmp/optivolt-dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "OptiVolt - Comparaison Performances",
    "tags": ["optivolt", "performance", "energy"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "refresh": "5s",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage - Docker vs Unikernel",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "rate(process_cpu_seconds_total{job=\"docker\"}[1m])*100",
            "legendFormat": "Docker CPU",
            "refId": "A"
          },
          {
            "expr": "rate(process_cpu_seconds_total{job=\"unikernel\"}[1m])*100",
            "legendFormat": "Unikernel CPU",
            "refId": "B"
          }
        ],
        "yaxes": [
          {"format": "percent", "label": "CPU %"},
          {"format": "short"}
        ]
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes",
            "legendFormat": "Memory Used",
            "refId": "A"
          }
        ],
        "yaxes": [
          {"format": "bytes", "label": "Memory"},
          {"format": "short"}
        ]
      },
      {
        "id": 3,
        "title": "Network I/O",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "rate(node_network_receive_bytes_total[1m])",
            "legendFormat": "RX {{device}}",
            "refId": "A"
          },
          {
            "expr": "rate(node_network_transmit_bytes_total[1m])",
            "legendFormat": "TX {{device}}",
            "refId": "B"
          }
        ],
        "yaxes": [
          {"format": "Bps", "label": "Bytes/sec"},
          {"format": "short"}
        ]
      },
      {
        "id": 4,
        "title": "Container Statistics",
        "type": "table",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "container_memory_usage_bytes{name=~\"unikernel.*|docker.*\"}",
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
EOF

# Import du dashboard
echo "📤 Import dans Grafana..."
curl -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  "$GRAFANA_URL/api/dashboards/db" \
  -d @/tmp/optivolt-dashboard.json \
  2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Dashboard créé avec succès!"
    echo ""
    echo "🔗 Accédez à: $GRAFANA_URL/d/optivolt/optivolt-comparaison-performances"
else
    echo "⚠️  Erreur lors de la création. Vérifiez que Grafana est accessible."
fi

echo ""
echo "========================================="
echo "📚 GUIDE GRAFANA"
echo "========================================="
echo ""
echo "1️⃣  Accéder à Grafana:"
echo "   URL: http://localhost:3000"
echo "   User: admin"
echo "   Pass: optivolt2025"
echo ""
echo "2️⃣  Créer un Dashboard manuellement:"
echo "   a) Cliquer sur '+' → Dashboard"
echo "   b) Add visualization"
echo "   c) Sélectionner 'Prometheus' comme source"
echo "   d) Ajouter une requête (exemple):"
echo "      - node_cpu_seconds_total"
echo "      - container_memory_usage_bytes"
echo "      - rate(node_network_receive_bytes_total[1m])"
echo ""
echo "3️⃣  Requêtes Prometheus utiles:"
echo ""
echo "   CPU:"
echo "   • 100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
echo "   • container_cpu_usage_seconds_total"
echo ""
echo "   Mémoire:"
echo "   • node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100"
echo "   • container_memory_usage_bytes"
echo ""
echo "   Réseau:"
echo "   • rate(node_network_receive_bytes_total[1m])"
echo "   • rate(container_network_transmit_bytes_total[1m])"
echo ""
echo "   Disque:"
echo "   • node_filesystem_avail_bytes"
echo "   • rate(node_disk_io_time_seconds_total[1m])"
echo ""
echo "4️⃣  Dashboards pré-configurés à importer:"
echo "   • Node Exporter: ID 1860"
echo "   • Docker: ID 193"
echo "   • cAdvisor: ID 14282"
echo ""
echo "   Import: Dashboards → Import → Entrer l'ID"
echo ""
echo "========================================="

rm -f /tmp/optivolt-dashboard.json
