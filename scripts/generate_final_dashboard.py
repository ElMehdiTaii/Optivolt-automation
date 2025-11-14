#!/usr/bin/env python3
"""
Générateur de rapport final OptiVolt avec toutes les métriques
"""

import json
import sys
from pathlib import Path
from datetime import datetime

def load_all_metrics(directory):
    """Charge tous les fichiers de métriques"""
    data = {
        "tests": [],
        "system_metrics": [],
        "timestamp": datetime.now().isoformat()
    }
    
    for file in Path(directory).glob("*.json"):
        try:
            with open(file) as f:
                content = json.load(f)
                
                if "test" in content and "environment" in content:
                    data["tests"].append(content)
                elif "samples" in content:
                    data["system_metrics"].append(content)
        except:
            pass
    
    return data

def generate_dashboard(data, output_file):
    """Génère un dashboard HTML complet"""
    
    html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>OptiVolt - Dashboard Final</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; padding: 20px; }}
        .container {{ max-width: 1200px; margin: 0 auto; }}
        .hero {{ background: white; padding: 40px; border-radius: 15px; 
                 margin-bottom: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); }}
        .hero h1 {{ font-size: 3em; color: #667eea; margin-bottom: 10px; }}
        .hero p {{ color: #666; font-size: 1.2em; }}
        .stats-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                      gap: 20px; margin-bottom: 30px; }}
        .stat-card {{ background: white; padding: 30px; border-radius: 10px;
                     box-shadow: 0 5px 15px rgba(0,0,0,0.1); }}
        .stat-number {{ font-size: 3em; font-weight: bold; color: #667eea; }}
        .stat-label {{ color: #666; margin-top: 10px; }}
        .card {{ background: white; padding: 30px; border-radius: 10px;
                margin-bottom: 20px; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
        th, td {{ padding: 15px; text-align: left; border-bottom: 1px solid #eee; }}
        th {{ background: #f8f9fa; color: #333; font-weight: 600; }}
        .badge {{ display: inline-block; padding: 5px 15px; border-radius: 20px;
                 font-size: 0.85em; font-weight: 600; }}
        .badge-success {{ background: #d4edda; color: #155724; }}
        .badge-warning {{ background: #fff3cd; color: #856404; }}
        .badge-info {{ background: #d1ecf1; color: #0c5460; }}
        .winner {{ background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                  color: white; padding: 10px 20px; border-radius: 25px;
                  display: inline-block; }}
        h2 {{ color: #333; margin-bottom: 20px; }}
        .footer {{ background: white; padding: 20px; border-radius: 10px;
                  text-align: center; margin-top: 30px; }}
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <div class="hero">
            <h1>⚡ OptiVolt Dashboard</h1>
            <p>Analyse comparative de performances énergétiques</p>
            <p style="color: #999; margin-top: 10px;">Généré le {datetime.now().strftime("%d/%m/%Y à %H:%M:%S")}</p>
        </div>
"""
    
    # Stats globales
    test_count = len(data["tests"])
    envs = set(t.get("environment") for t in data["tests"])
    completed = sum(1 for t in data["tests"] if t.get("status") == "completed")
    
    html += f"""
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number">{test_count}</div>
                <div class="stat-label">Tests Exécutés</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{len(envs)}</div>
                <div class="stat-label">Environnements</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{completed}</div>
                <div class="stat-label">Tests Réussis</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">{(completed/test_count*100) if test_count > 0 else 0:.0f}%</div>
                <div class="stat-label">Taux de Succès</div>
            </div>
        </div>
"""
    
    # Tests par environnement
    tests_by_env = {}
    for test in data["tests"]:
        env = test.get("environment", "unknown")
        if env not in tests_by_env:
            tests_by_env[env] = []
        tests_by_env[env].append(test)
    
    html += """
        <div class="card">
            <h2>🧪 Résultats par Environnement</h2>
            <table>
                <tr>
                    <th>Environnement</th>
                    <th>Type de Test</th>
                    <th>Durée (s)</th>
                    <th>Statut</th>
                    <th>Timestamp</th>
                </tr>
"""
    
    for env, tests in sorted(tests_by_env.items()):
        for test in tests:
            status_badge = "badge-success" if test.get("status") == "completed" else "badge-warning"
            html += f"""
                <tr>
                    <td><strong>{env}</strong></td>
                    <td>{test.get("test", "N/A").upper()}</td>
                    <td>{test.get("duration_seconds", 0):.2f}</td>
                    <td><span class="badge {status_badge}">{test.get("status", "unknown")}</span></td>
                    <td>{test.get("timestamp", "N/A")[:19]}</td>
                </tr>
"""
    
    html += """
            </table>
        </div>
"""
    
    # Comparaison
    if len(envs) > 1:
        html += """
        <div class="card">
            <h2>🏆 Comparaison de Performances</h2>
"""
        
        # Grouper par type de test
        tests_by_type = {}
        for test in data["tests"]:
            test_type = test.get("test", "unknown")
            if test_type not in tests_by_type:
                tests_by_type[test_type] = []
            tests_by_type[test_type].append(test)
        
        for test_type, tests in tests_by_type.items():
            if len(tests) > 1:
                fastest = min(tests, key=lambda x: x.get("duration_seconds", float('inf')))
                html += f"""
            <p><strong>Test {test_type.upper()}:</strong> 
               <span class="winner">🏆 {fastest.get("environment")} - {fastest.get("duration_seconds")}s</span>
            </p>
"""
        
        html += """
        </div>
"""
    
    # Métriques système
    if data["system_metrics"]:
        html += """
        <div class="card">
            <h2>💻 Métriques Système</h2>
"""
        for metrics in data["system_metrics"][:1]:  # Prendre la première
            summary = metrics.get("summary", {})
            html += f"""
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-number">{summary.get("avg_cpu_percent", 0):.1f}%</div>
                    <div class="stat-label">CPU Moyen</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">{summary.get("avg_memory_percent", 0):.1f}%</div>
                    <div class="stat-label">Mémoire Moyenne</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">{summary.get("estimated_power_watts", 0):.1f}W</div>
                    <div class="stat-label">Puissance Estimée</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">{summary.get("estimated_energy_wh", 0):.4f} Wh</div>
                    <div class="stat-label">Énergie Consommée</div>
                </div>
            </div>
"""
        html += """
        </div>
"""
    
    # Footer
    html += f"""
        <div class="footer">
            <p><strong>OptiVolt</strong> - Pipeline d'analyse énergétique</p>
            <p style="margin-top: 10px; color: #666;">
                📊 Grafana: <a href="http://localhost:3000">localhost:3000</a> | 
                📈 Prometheus: <a href="http://localhost:9090">localhost:9090</a>
            </p>
        </div>
    </div>
</body>
</html>
"""
    
    with open(output_file, 'w') as f:
        f.write(html)
    
    print(f"✅ Dashboard généré: {output_file}")

def main():
    directory = sys.argv[1] if len(sys.argv) > 1 else "."
    output = sys.argv[2] if len(sys.argv) > 2 else "dashboard_final.html"
    
    print("📊 Génération du dashboard final...")
    data = load_all_metrics(directory)
    
    print(f"   Tests: {len(data['tests'])}")
    print(f"   Métriques système: {len(data['system_metrics'])}")
    
    generate_dashboard(data, output)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
