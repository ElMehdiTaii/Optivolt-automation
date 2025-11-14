#!/usr/bin/env python3
"""
Génère un dashboard Grafana complet pour comparer Docker vs Unikernel
"""

import json
import requests
import sys

GRAFANA_URL = "http://localhost:3000"
GRAFANA_USER = "admin"
GRAFANA_PASS = "optivolt2025"

def create_dashboard():
    """Crée un dashboard comparatif Docker vs Unikernel"""
    
    dashboard = {
        "dashboard": {
            "title": "OptiVolt - Docker vs Unikernel Comparison",
            "tags": ["optivolt", "comparison", "docker", "unikernel"],
            "timezone": "browser",
            "schemaVersion": 38,
            "version": 0,
            "refresh": "5s",
            "time": {
                "from": "now-15m",
                "to": "now"
            },
            "panels": [
                # Header / Title
                {
                    "id": 1,
                    "type": "text",
                    "gridPos": {"h": 3, "w": 24, "x": 0, "y": 0},
                    "options": {
                        "mode": "markdown",
                        "content": "# 🚀 OptiVolt - Comparaison Docker vs Unikernel\n\nAnalyse en temps réel des performances et de la consommation énergétique"
                    }
                },
                
                # CPU Comparison
                {
                    "id": 2,
                    "title": "🔥 CPU Usage Comparison",
                    "type": "timeseries",
                    "gridPos": {"h": 9, "w": 12, "x": 0, "y": 3},
                    "fieldConfig": {
                        "defaults": {
                            "unit": "percent",
                            "color": {"mode": "palette-classic"}
                        }
                    },
                    "targets": [
                        {
                            "expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".*docker.*\"}[1m])) * 100",
                            "legendFormat": "Docker CPU %",
                            "refId": "A"
                        },
                        {
                            "expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".*unikernel.*\"}[1m])) * 100",
                            "legendFormat": "Unikernel CPU %",
                            "refId": "B"
                        }
                    ],
                    "options": {
                        "legend": {"displayMode": "list", "placement": "bottom"}
                    }
                },
                
                # CPU Gauge Comparison
                {
                    "id": 3,
                    "title": "CPU Usage Now",
                    "type": "gauge",
                    "gridPos": {"h": 9, "w": 12, "x": 12, "y": 3},
                    "fieldConfig": {
                        "defaults": {
                            "unit": "percent",
                            "min": 0,
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
                    },
                    "targets": [
                        {
                            "expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".*docker.*\"}[1m])) * 100",
                            "legendFormat": "Docker",
                            "refId": "A"
                        },
                        {
                            "expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".*unikernel.*\"}[1m])) * 100",
                            "legendFormat": "Unikernel",
                            "refId": "B"
                        }
                    ]
                },
                
                # Memory Comparison
                {
                    "id": 4,
                    "title": "💾 Memory Usage Comparison",
                    "type": "timeseries",
                    "gridPos": {"h": 9, "w": 12, "x": 0, "y": 12},
                    "fieldConfig": {
                        "defaults": {
                            "unit": "bytes",
                            "color": {"mode": "palette-classic"}
                        }
                    },
                    "targets": [
                        {
                            "expr": "container_memory_usage_bytes{name=~\".*docker.*\"}",
                            "legendFormat": "Docker Memory",
                            "refId": "A"
                        },
                        {
                            "expr": "container_memory_usage_bytes{name=~\".*unikernel.*\"}",
                            "legendFormat": "Unikernel Memory",
                            "refId": "B"
                        }
                    ]
                },
                
                # Memory Stats Table
                {
                    "id": 5,
                    "title": "Memory Statistics",
                    "type": "stat",
                    "gridPos": {"h": 9, "w": 12, "x": 12, "y": 12},
                    "fieldConfig": {
                        "defaults": {
                            "unit": "bytes",
                            "color": {"mode": "thresholds"}
                        }
                    },
                    "targets": [
                        {
                            "expr": "container_memory_usage_bytes{name=~\".*docker.*\"}",
                            "legendFormat": "Docker",
                            "refId": "A"
                        },
                        {
                            "expr": "container_memory_usage_bytes{name=~\".*unikernel.*\"}",
                            "legendFormat": "Unikernel",
                            "refId": "B"
                        }
                    ],
                    "options": {
                        "graphMode": "area",
                        "orientation": "auto"
                    }
                },
                
                # Network I/O
                {
                    "id": 6,
                    "title": "🌐 Network I/O",
                    "type": "timeseries",
                    "gridPos": {"h": 8, "w": 12, "x": 0, "y": 21},
                    "fieldConfig": {
                        "defaults": {
                            "unit": "Bps",
                            "color": {"mode": "palette-classic"}
                        }
                    },
                    "targets": [
                        {
                            "expr": "rate(container_network_receive_bytes_total{name=~\".*docker.*\"}[1m])",
                            "legendFormat": "Docker RX",
                            "refId": "A"
                        },
                        {
                            "expr": "rate(container_network_transmit_bytes_total{name=~\".*docker.*\"}[1m])",
                            "legendFormat": "Docker TX",
                            "refId": "B"
                        },
                        {
                            "expr": "rate(container_network_receive_bytes_total{name=~\".*unikernel.*\"}[1m])",
                            "legendFormat": "Unikernel RX",
                            "refId": "C"
                        },
                        {
                            "expr": "rate(container_network_transmit_bytes_total{name=~\".*unikernel.*\"}[1m])",
                            "legendFormat": "Unikernel TX",
                            "refId": "D"
                        }
                    ]
                },
                
                # Container Info
                {
                    "id": 7,
                    "title": "📦 Container Information",
                    "type": "table",
                    "gridPos": {"h": 8, "w": 12, "x": 12, "y": 21},
                    "targets": [
                        {
                            "expr": "container_memory_usage_bytes{name=~\".*docker.*|.*unikernel.*\"}",
                            "format": "table",
                            "instant": True,
                            "refId": "A"
                        }
                    ],
                    "transformations": [
                        {
                            "id": "organize",
                            "options": {
                                "excludeByName": {
                                    "Time": True,
                                    "__name__": True
                                }
                            }
                        }
                    ]
                },
                
                # System CPU
                {
                    "id": 8,
                    "title": "🖥️ System CPU (All Cores)",
                    "type": "timeseries",
                    "gridPos": {"h": 8, "w": 12, "x": 0, "y": 29},
                    "fieldConfig": {
                        "defaults": {
                            "unit": "percent",
                            "color": {"mode": "palette-classic"}
                        }
                    },
                    "targets": [
                        {
                            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[1m])) * 100)",
                            "legendFormat": "Total CPU Usage",
                            "refId": "A"
                        }
                    ]
                },
                
                # System Memory
                {
                    "id": 9,
                    "title": "💽 System Memory",
                    "type": "timeseries",
                    "gridPos": {"h": 8, "w": 12, "x": 12, "y": 29},
                    "fieldConfig": {
                        "defaults": {
                            "unit": "bytes",
                            "color": {"mode": "palette-classic"}
                        }
                    },
                    "targets": [
                        {
                            "expr": "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes",
                            "legendFormat": "Used Memory",
                            "refId": "A"
                        },
                        {
                            "expr": "node_memory_MemAvailable_bytes",
                            "legendFormat": "Available Memory",
                            "refId": "B"
                        }
                    ]
                },
                
                # Performance Score
                {
                    "id": 10,
                    "title": "🏆 Performance Winner",
                    "type": "text",
                    "gridPos": {"h": 5, "w": 24, "x": 0, "y": 37},
                    "options": {
                        "mode": "markdown",
                        "content": """
## 📊 Comparaison en temps réel

### Métriques Collectées:
- **CPU**: Utilisation moyenne et pics
- **Mémoire**: Consommation et empreinte
- **Réseau**: Débit entrant/sortant
- **I/O**: Opérations disque

### Interprétation:
- 🟢 **Vert**: Performance optimale (< 50%)
- 🟡 **Jaune**: Utilisation modérée (50-80%)
- 🔴 **Rouge**: Charge élevée (> 80%)

### 💡 Astuce:
Lancez des tests avec `dotnet OptiVoltCLI.dll test --environment <env> --type all` pour voir les différences en action !
"""
                    }
                }
            ]
        },
        "overwrite": True,
        "message": "Dashboard créé par OptiVolt"
    }
    
    return dashboard

def import_dashboard(dashboard_json):
    """Importe le dashboard dans Grafana"""
    
    try:
        response = requests.post(
            f"{GRAFANA_URL}/api/dashboards/db",
            json=dashboard_json,
            auth=(GRAFANA_USER, GRAFANA_PASS),
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Dashboard créé avec succès!")
            print(f"🔗 URL: {GRAFANA_URL}{result.get('url', '')}")
            return True
        else:
            print(f"❌ Erreur {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def main():
    print("=" * 60)
    print("  OptiVolt - Création Dashboard Grafana")
    print("=" * 60)
    print()
    
    print("📊 Génération du dashboard Docker vs Unikernel...")
    dashboard = create_dashboard()
    
    print("📤 Import dans Grafana...")
    success = import_dashboard(dashboard)
    
    if success:
        print()
        print("=" * 60)
        print("✨ Dashboard créé avec succès!")
        print("=" * 60)
        print()
        print(f"🌐 Accédez à Grafana: {GRAFANA_URL}")
        print(f"👤 Identifiants: {GRAFANA_USER} / {GRAFANA_PASS}")
        print()
        print("📊 Le dashboard contient:")
        print("  • Comparaison CPU en temps réel")
        print("  • Utilisation mémoire Docker vs Unikernel")
        print("  • Trafic réseau (RX/TX)")
        print("  • Métriques système globales")
        print("  • Tableau récapitulatif des containers")
        print()
        print("💡 Conseil: Lancez des tests pour voir les graphiques s'animer!")
        print("   cd publish && dotnet OptiVoltCLI.dll test --environment unikernel --type cpu")
        print()
        return 0
    else:
        print()
        print("⚠️  Impossible de créer le dashboard")
        print("Vérifiez que Grafana est accessible sur", GRAFANA_URL)
        return 1

if __name__ == "__main__":
    sys.exit(main())
