#!/usr/bin/env python3
"""
OptiVolt Dashboard Generator
Génère un tableau de bord HTML interactif à partir des métriques collectées
"""

import json
import os
import glob
from datetime import datetime
from pathlib import Path
import sys

def load_metrics_files(results_dir):
    """Charge tous les fichiers de métriques JSON"""
    metrics_files = glob.glob(os.path.join(results_dir, "*_metrics_*.json"))
    
    all_metrics = []
    for filepath in metrics_files:
        try:
            with open(filepath, 'r') as f:
                data = json.load(f)
                data['_filepath'] = filepath
                all_metrics.append(data)
        except Exception as e:
            print(f"Erreur lors de la lecture de {filepath}: {e}")
    
    return all_metrics

def calculate_statistics(metrics_list):
    """Calcule les statistiques globales"""
    if not metrics_list:
        return {}
    
    stats = {
        'total_tests': len(metrics_list),
        'environments': {},
        'avg_cpu': 0,
        'avg_memory': 0,
        'total_duration': 0
    }
    
    cpu_sum = 0
    mem_sum = 0
    
    for metric in metrics_list:
        env = metric['metadata']['environment']
        
        if env not in stats['environments']:
            stats['environments'][env] = {
                'count': 0,
                'avg_cpu': 0,
                'avg_memory': 0,
                'total_duration': 0
            }
        
        stats['environments'][env]['count'] += 1
        
        cpu = float(metric['system_metrics']['averages']['cpu_usage_percent'])
        mem = float(metric['system_metrics']['averages']['memory_usage_percent'])
        duration = int(metric['metadata']['duration_seconds'])
        
        stats['environments'][env]['avg_cpu'] += cpu
        stats['environments'][env]['avg_memory'] += mem
        stats['environments'][env]['total_duration'] += duration
        
        cpu_sum += cpu
        mem_sum += mem
        stats['total_duration'] += duration
    
    # Calculer les moyennes
    stats['avg_cpu'] = cpu_sum / len(metrics_list)
    stats['avg_memory'] = mem_sum / len(metrics_list)
    
    for env in stats['environments']:
        count = stats['environments'][env]['count']
        stats['environments'][env]['avg_cpu'] /= count
        stats['environments'][env]['avg_memory'] /= count
    
    return stats

def generate_html(metrics_list, stats, output_file):
    """Génère le fichier HTML du tableau de bord"""
    
    # Préparer les données pour les graphiques
    environments = list(stats['environments'].keys())
    cpu_data = [stats['environments'][env]['avg_cpu'] for env in environments]
    mem_data = [stats['environments'][env]['avg_memory'] for env in environments]
    
    html_content = f"""
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OptiVolt - Tableau de Bord</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }}
        
        .container {{
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }}
        
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }}
        
        .header h1 {{
            font-size: 3em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }}
        
        .header p {{
            font-size: 1.2em;
            opacity: 0.9;
        }}
        
        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            padding: 40px;
            background: #f8f9fa;
        }}
        
        .stat-card {{
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s, box-shadow 0.3s;
        }}
        
        .stat-card:hover {{
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }}
        
        .stat-card h3 {{
            color: #667eea;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }}
        
        .stat-card .value {{
            font-size: 2.5em;
            font-weight: bold;
            color: #333;
            margin: 10px 0;
        }}
        
        .stat-card .label {{
            color: #666;
            font-size: 0.9em;
        }}
        
        .charts-section {{
            padding: 40px;
        }}
        
        .chart-container {{
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }}
        
        .chart-container h2 {{
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.5em;
        }}
        
        .chart-wrapper {{
            position: relative;
            height: 400px;
        }}
        
        .metrics-table {{
            padding: 40px;
        }}
        
        .table-container {{
            background: white;
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            overflow: hidden;
        }}
        
        table {{
            width: 100%;
            border-collapse: collapse;
        }}
        
        thead {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }}
        
        th {{
            padding: 20px;
            text-align: left;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.85em;
            letter-spacing: 1px;
        }}
        
        td {{
            padding: 15px 20px;
            border-bottom: 1px solid #eee;
        }}
        
        tbody tr:hover {{
            background: #f8f9fa;
        }}
        
        .badge {{
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }}
        
        .badge-docker {{
            background: #e3f2fd;
            color: #1976d2;
        }}
        
        .badge-microvm {{
            background: #f3e5f5;
            color: #7b1fa2;
        }}
        
        .badge-unikernel {{
            background: #e8f5e9;
            color: #388e3c;
        }}
        
        .badge-localhost {{
            background: #fff3e0;
            color: #f57c00;
        }}
        
        .footer {{
            background: #2c3e50;
            color: white;
            padding: 30px;
            text-align: center;
        }}
        
        .comparison-section {{
            padding: 40px;
            background: #f8f9fa;
        }}
        
        .comparison-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }}
        
        .env-card {{
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }}
        
        .env-card h3 {{
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.3em;
        }}
        
        .metric-row {{
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }}
        
        .metric-row:last-child {{
            border-bottom: none;
        }}
        
        .metric-label {{
            color: #666;
            font-size: 0.9em;
        }}
        
        .metric-value {{
            font-weight: 600;
            color: #333;
        }}
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1>📊 OptiVolt Dashboard</h1>
            <p>Analyse Comparative des Technologies de Virtualisation</p>
            <p style="font-size: 0.9em; margin-top: 10px;">Généré le {datetime.now().strftime('%d/%m/%Y à %H:%M:%S')}</p>
        </div>
        
        <!-- Stats globales -->
        <div class="stats-grid">
            <div class="stat-card">
                <h3>Total Tests</h3>
                <div class="value">{stats['total_tests']}</div>
                <div class="label">Exécutions complétées</div>
            </div>
            
            <div class="stat-card">
                <h3>CPU Moyen</h3>
                <div class="value">{stats['avg_cpu']:.1f}%</div>
                <div class="label">Utilisation processeur</div>
            </div>
            
            <div class="stat-card">
                <h3>Mémoire Moyenne</h3>
                <div class="value">{stats['avg_memory']:.1f}%</div>
                <div class="label">Utilisation RAM</div>
            </div>
            
            <div class="stat-card">
                <h3>Durée Totale</h3>
                <div class="value">{stats['total_duration']//60}</div>
                <div class="label">Minutes de tests</div>
            </div>
        </div>
        
        <!-- Graphiques -->
        <div class="charts-section">
            <div class="chart-container">
                <h2>📈 Comparaison CPU par Environnement</h2>
                <div class="chart-wrapper">
                    <canvas id="cpuChart"></canvas>
                </div>
            </div>
            
            <div class="chart-container">
                <h2>💾 Comparaison Mémoire par Environnement</h2>
                <div class="chart-wrapper">
                    <canvas id="memoryChart"></canvas>
                </div>
            </div>
            
            <div class="chart-container">
                <h2>⚡ Performance Combinée (CPU + Mémoire)</h2>
                <div class="chart-wrapper">
                    <canvas id="combinedChart"></canvas>
                </div>
            </div>
        </div>
        
        <!-- Comparaison détaillée -->
        <div class="comparison-section">
            <h2 style="color: #667eea; margin-bottom: 20px; font-size: 2em;">🔬 Analyse Détaillée par Environnement</h2>
            <div class="comparison-grid">
"""
    
    # Ajouter les cartes pour chaque environnement
    for env, data in stats['environments'].items():
        badge_class = f"badge-{env}"
        html_content += f"""
                <div class="env-card">
                    <h3><span class="badge {badge_class}">{env.upper()}</span></h3>
                    <div class="metric-row">
                        <span class="metric-label">Nombre de tests</span>
                        <span class="metric-value">{data['count']}</span>
                    </div>
                    <div class="metric-row">
                        <span class="metric-label">CPU moyen</span>
                        <span class="metric-value">{data['avg_cpu']:.2f}%</span>
                    </div>
                    <div class="metric-row">
                        <span class="metric-label">Mémoire moyenne</span>
                        <span class="metric-value">{data['avg_memory']:.2f}%</span>
                    </div>
                    <div class="metric-row">
                        <span class="metric-label">Durée totale</span>
                        <span class="metric-value">{data['total_duration']}s</span>
                    </div>
                </div>
"""
    
    html_content += """
            </div>
        </div>
        
        <!-- Tableau des métriques -->
        <div class="metrics-table">
            <h2 style="color: #667eea; margin-bottom: 20px; font-size: 2em;">📋 Détail des Métriques</h2>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Environnement</th>
                            <th>Date</th>
                            <th>CPU (%)</th>
                            <th>Mémoire (%)</th>
                            <th>Durée (s)</th>
                            <th>Hostname</th>
                        </tr>
                    </thead>
                    <tbody>
"""
    
    # Ajouter les lignes du tableau
    for metric in sorted(metrics_list, key=lambda x: x['metadata']['timestamp'], reverse=True):
        env = metric['metadata']['environment']
        badge_class = f"badge-{env}"
        timestamp = metric['metadata']['timestamp']
        cpu = metric['system_metrics']['averages']['cpu_usage_percent']
        mem = metric['system_metrics']['averages']['memory_usage_percent']
        duration = metric['metadata']['duration_seconds']
        hostname = metric['metadata']['hostname']
        
        html_content += f"""
                        <tr>
                            <td><span class="badge {badge_class}">{env}</span></td>
                            <td>{timestamp}</td>
                            <td>{cpu:.2f}%</td>
                            <td>{mem:.2f}%</td>
                            <td>{duration}s</td>
                            <td>{hostname}</td>
                        </tr>
"""
    
    html_content += f"""
                    </tbody>
                </table>
            </div>
        </div>
        
        <!-- Footer -->
        <div class="footer">
            <p><strong>OptiVolt</strong> - Optimisation Énergétique des Systèmes de Virtualisation</p>
            <p style="margin-top: 10px; opacity: 0.8;">Projet R&D - {datetime.now().year}</p>
        </div>
    </div>
    
    <script>
        // Configuration globale des graphiques
        Chart.defaults.font.family = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif";
        Chart.defaults.color = '#333';
        
        // Données
        const environments = {json.dumps(environments)};
        const cpuData = {json.dumps(cpu_data)};
        const memData = {json.dumps(mem_data)};
        
        // Couleurs
        const colors = {{
            docker: 'rgba(25, 118, 210, 0.8)',
            microvm: 'rgba(123, 31, 162, 0.8)',
            unikernel: 'rgba(56, 142, 60, 0.8)',
            localhost: 'rgba(245, 124, 0, 0.8)'
        }};
        
        const backgroundColors = environments.map(env => colors[env] || 'rgba(100, 100, 100, 0.8)');
        
        // Graphique CPU
        new Chart(document.getElementById('cpuChart'), {{
            type: 'bar',
            data: {{
                labels: environments,
                datasets: [{{
                    label: 'Utilisation CPU (%)',
                    data: cpuData,
                    backgroundColor: backgroundColors,
                    borderWidth: 0,
                    borderRadius: 10
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {{
                    legend: {{
                        display: false
                    }},
                    tooltip: {{
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        padding: 12,
                        titleFont: {{ size: 14 }},
                        bodyFont: {{ size: 13 }}
                    }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: true,
                        grid: {{
                            color: 'rgba(0, 0, 0, 0.05)'
                        }}
                    }},
                    x: {{
                        grid: {{
                            display: false
                        }}
                    }}
                }}
            }}
        }});
        
        // Graphique Mémoire
        new Chart(document.getElementById('memoryChart'), {{
            type: 'bar',
            data: {{
                labels: environments,
                datasets: [{{
                    label: 'Utilisation Mémoire (%)',
                    data: memData,
                    backgroundColor: backgroundColors,
                    borderWidth: 0,
                    borderRadius: 10
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {{
                    legend: {{
                        display: false
                    }},
                    tooltip: {{
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        padding: 12,
                        titleFont: {{ size: 14 }},
                        bodyFont: {{ size: 13 }}
                    }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: true,
                        grid: {{
                            color: 'rgba(0, 0, 0, 0.05)'
                        }}
                    }},
                    x: {{
                        grid: {{
                            display: false
                        }}
                    }}
                }}
            }}
        }});
        
        // Graphique combiné (Radar)
        new Chart(document.getElementById('combinedChart'), {{
            type: 'radar',
            data: {{
                labels: environments,
                datasets: [
                    {{
                        label: 'CPU',
                        data: cpuData,
                        backgroundColor: 'rgba(102, 126, 234, 0.2)',
                        borderColor: 'rgba(102, 126, 234, 1)',
                        borderWidth: 2,
                        pointBackgroundColor: 'rgba(102, 126, 234, 1)',
                        pointRadius: 5
                    }},
                    {{
                        label: 'Mémoire',
                        data: memData,
                        backgroundColor: 'rgba(118, 75, 162, 0.2)',
                        borderColor: 'rgba(118, 75, 162, 1)',
                        borderWidth: 2,
                        pointBackgroundColor: 'rgba(118, 75, 162, 1)',
                        pointRadius: 5
                    }}
                ]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {{
                    legend: {{
                        position: 'top',
                        labels: {{
                            font: {{
                                size: 14
                            }},
                            padding: 20
                        }}
                    }}
                }},
                scales: {{
                    r: {{
                        beginAtZero: true,
                        grid: {{
                            color: 'rgba(0, 0, 0, 0.1)'
                        }},
                        angleLines: {{
                            color: 'rgba(0, 0, 0, 0.1)'
                        }},
                        pointLabels: {{
                            font: {{
                                size: 12
                            }}
                        }}
                    }}
                }}
            }}
        }});
    </script>
</body>
</html>
"""
    
    # Écrire le fichier
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"✓ Dashboard généré: {output_file}")

def main():
    # Déterminer le répertoire des résultats
    results_dir = os.path.join(
        os.path.expanduser('~'),
        'optivolt-automation',
        'results'
    )
    
    if len(sys.argv) > 1:
        results_dir = sys.argv[1]
    
    if not os.path.exists(results_dir):
        print(f"✗ Répertoire introuvable: {results_dir}")
        sys.exit(1)
    
    print(f"📂 Lecture des métriques depuis: {results_dir}")
    
    # Charger les métriques
    metrics_list = load_metrics_files(results_dir)
    
    if not metrics_list:
        print("✗ Aucune métrique trouvée")
        sys.exit(1)
    
    print(f"✓ {len(metrics_list)} fichiers de métriques chargés")
    
    # Calculer les statistiques
    stats = calculate_statistics(metrics_list)
    print(f"✓ Statistiques calculées pour {len(stats['environments'])} environnements")
    
    # Générer le dashboard
    output_file = os.path.join(results_dir, 'dashboard.html')
    generate_html(metrics_list, stats, output_file)
    
    print(f"\n🎉 Dashboard disponible: file://{os.path.abspath(output_file)}")

if __name__ == '__main__':
    main()
