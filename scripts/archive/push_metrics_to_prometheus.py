#!/usr/bin/env python3
"""
Script pour envoyer les métriques de benchmark vers Prometheus Pushgateway
et les rendre visibles dans Grafana
"""

import json
import sys
import requests
from datetime import datetime

PROMETHEUS_PUSHGATEWAY = "http://localhost:9091"  # Si pushgateway installé
PROMETHEUS_URL = "http://localhost:9090"

def push_metrics_to_file(comparison_file):
    """
    Génère un fichier de métriques au format Prometheus text
    qui peut être scraped ou importé
    """
    
    with open(comparison_file, 'r') as f:
        data = json.load(f)
    
    timestamp = int(datetime.now().timestamp() * 1000)
    
    metrics_output = []
    
    # Pour chaque environnement
    for env_name, env_data in data['results'].items():
        metrics = env_data['metrics']
        
        # CPU Usage
        metrics_output.append(
            f'optivolt_cpu_usage_percent{{environment="{env_name}"}} {metrics["cpu_usage_percent"]} {timestamp}'
        )
        
        # Memory Usage
        metrics_output.append(
            f'optivolt_memory_used_mb{{environment="{env_name}"}} {metrics["memory_used_mb"]} {timestamp}'
        )
        
        metrics_output.append(
            f'optivolt_memory_percent{{environment="{env_name}"}} {metrics["memory_percent"]} {timestamp}'
        )
        
        # Duration
        metrics_output.append(
            f'optivolt_test_duration_seconds{{environment="{env_name}"}} {metrics["duration_seconds"]} {timestamp}'
        )
    
    # Écrire dans un fichier que Prometheus peut scraper
    metrics_file = "results/prometheus_metrics.txt"
    with open(metrics_file, 'w') as f:
        f.write('\n'.join(metrics_output))
        f.write('\n')
    
    print(f"✓ Métriques Prometheus générées: {metrics_file}")
    print("\nMétriques disponibles:")
    print("  - optivolt_cpu_usage_percent")
    print("  - optivolt_memory_used_mb")
    print("  - optivolt_memory_percent")
    print("  - optivolt_test_duration_seconds")
    print("\nLabels: environment={docker,microvm,unikernel}")
    
    return metrics_file

def generate_grafana_dashboard_data(comparison_file):
    """
    Génère des données formatées pour l'import dans Grafana
    """
    
    with open(comparison_file, 'r') as f:
        data = json.load(f)
    
    # Créer un fichier JSON pour Grafana
    grafana_data = {
        "dashboard": {
            "title": "OptiVolt Real Benchmark Comparison",
            "panels": [
                {
                    "title": "CPU Usage by Environment",
                    "targets": [
                        {
                            "expr": 'optivolt_cpu_usage_percent',
                            "legendFormat": "{{environment}}"
                        }
                    ]
                },
                {
                    "title": "Memory Usage by Environment",
                    "targets": [
                        {
                            "expr": 'optivolt_memory_used_mb',
                            "legendFormat": "{{environment}}"
                        }
                    ]
                }
            ]
        },
        "data": data
    }
    
    grafana_file = "results/grafana_import.json"
    with open(grafana_file, 'w') as f:
        json.dump(grafana_data, f, indent=2)
    
    print(f"\n✓ Données Grafana générées: {grafana_file}")
    print("\nPour importer dans Grafana:")
    print("  1. Ouvrir http://localhost:3000")
    print("  2. Dashboards > Import")
    print(f"  3. Upload {grafana_file}")
    
    return grafana_file

def display_comparison(comparison_file):
    """
    Affiche une comparaison visuelle dans le terminal
    """
    
    with open(comparison_file, 'r') as f:
        data = json.load(f)
    
    print("\n" + "="*60)
    print("           COMPARAISON DES PERFORMANCES")
    print("="*60 + "\n")
    
    # Tableau comparatif
    print(f"{'Environnement':<15} {'CPU (%)':<12} {'Mémoire (MB)':<15} {'Durée (s)':<12}")
    print("-" * 60)
    
    results = []
    for env_name, env_data in data['results'].items():
        metrics = env_data['metrics']
        results.append({
            'env': env_name,
            'cpu': metrics['cpu_usage_percent'],
            'mem': metrics['memory_used_mb'],
            'duration': metrics['duration_seconds']
        })
        
        print(f"{env_name:<15} {metrics['cpu_usage_percent']:<12.2f} {metrics['memory_used_mb']:<15} {metrics['duration_seconds']:<12}")
    
    print("-" * 60)
    
    # Analyse
    print("\n📊 ANALYSE:")
    
    # Environnement le plus efficace en CPU
    min_cpu = min(results, key=lambda x: x['cpu'])
    print(f"  • CPU le plus efficace: {min_cpu['env']} ({min_cpu['cpu']:.2f}%)")
    
    # Environnement utilisant le moins de mémoire
    min_mem = min(results, key=lambda x: x['mem'])
    print(f"  • Mémoire la plus faible: {min_mem['env']} ({min_mem['mem']} MB)")
    
    print("\n" + "="*60 + "\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 push_metrics_to_prometheus.py <comparison.json>")
        sys.exit(1)
    
    comparison_file = sys.argv[1]
    
    try:
        # Afficher comparaison
        display_comparison(comparison_file)
        
        # Générer métriques Prometheus
        push_metrics_to_file(comparison_file)
        
        # Générer données Grafana
        generate_grafana_dashboard_data(comparison_file)
        
        print("\n✅ Traitement terminé avec succès!")
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        sys.exit(1)
