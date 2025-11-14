#!/usr/bin/env python3
"""
Script de comparaison des performances entre environnements
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

def load_test_results(directory):
    """Charge tous les fichiers de résultats de test"""
    results = {}
    for file in Path(directory).glob("test_*.json"):
        try:
            with open(file) as f:
                data = json.load(f)
                env = data.get('environment', 'unknown')
                test_type = data.get('test', 'unknown')
                key = f"{env}_{test_type}"
                results[key] = data
        except Exception as e:
            print(f"⚠️  Erreur lecture {file}: {e}")
    return results

def compare_results(results):
    """Compare les résultats entre environnements"""
    print("\n" + "="*80)
    print("📊 COMPARAISON DES PERFORMANCES")
    print("="*80 + "\n")
    
    # Grouper par type de test
    tests = {}
    for key, data in results.items():
        test_type = data.get('test', 'unknown')
        if test_type not in tests:
            tests[test_type] = {}
        env = data.get('environment', 'unknown')
        tests[test_type][env] = data
    
    # Comparer chaque type de test
    for test_type, envs in tests.items():
        print(f"\n🧪 Test: {test_type.upper()}")
        print("-" * 80)
        
        for env, data in envs.items():
            status = "✅" if data.get('status') == 'completed' else "❌"
            duration = data.get('duration_seconds', 0)
            timestamp = data.get('timestamp', 'N/A')
            
            print(f"{status} {env:15s} | Durée: {duration:6.2f}s | {timestamp}")
        
        # Calculer le gagnant
        if len(envs) > 1:
            fastest = min(envs.items(), key=lambda x: x[1].get('duration_seconds', float('inf')))
            print(f"   🏆 Plus rapide: {fastest[0]}")
    
    print("\n" + "="*80)

def generate_html_report(results, output_file):
    """Génère un rapport HTML"""
    html = """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>OptiVolt - Comparaison des Performances</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                  color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .header h1 { margin: 0; }
        .card { background: white; padding: 20px; border-radius: 8px; 
                margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #667eea; color: white; }
        .status-ok { color: #27ae60; font-weight: bold; }
        .status-fail { color: #e74c3c; font-weight: bold; }
        .winner { background: #f0f8ff; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>⚡ OptiVolt - Comparaison des Performances</h1>
        <p>Rapport généré le """ + datetime.now().strftime("%Y-%m-%d %H:%M:%S") + """</p>
    </div>
"""
    
    # Grouper par type de test
    tests = {}
    for key, data in results.items():
        test_type = data.get('test', 'unknown')
        if test_type not in tests:
            tests[test_type] = {}
        env = data.get('environment', 'unknown')
        tests[test_type][env] = data
    
    for test_type, envs in tests.items():
        html += f"""
    <div class="card">
        <h2>🧪 Test: {test_type.upper()}</h2>
        <table>
            <tr>
                <th>Environnement</th>
                <th>Statut</th>
                <th>Durée (s)</th>
                <th>Timestamp</th>
            </tr>
"""
        
        # Trouver le plus rapide
        fastest_env = min(envs.items(), key=lambda x: x[1].get('duration_seconds', float('inf')))[0] if envs else None
        
        for env, data in sorted(envs.items()):
            status = data.get('status', 'unknown')
            status_class = 'status-ok' if status == 'completed' else 'status-fail'
            duration = data.get('duration_seconds', 0)
            timestamp = data.get('timestamp', 'N/A')[:19]
            row_class = 'winner' if env == fastest_env else ''
            
            html += f"""
            <tr class="{row_class}">
                <td><strong>{env}</strong> {'🏆' if env == fastest_env else ''}</td>
                <td class="{status_class}">{status}</td>
                <td>{duration:.2f}</td>
                <td>{timestamp}</td>
            </tr>
"""
        
        html += """
        </table>
    </div>
"""
    
    html += """
    <div class="card">
        <h3>📋 Résumé</h3>
        <ul>
            <li>Nombre total de tests: """ + str(len(results)) + """</li>
            <li>Environnements testés: """ + str(len(set(r.get('environment') for r in results.values()))) + """</li>
            <li>Types de tests: """ + str(len(tests)) + """</li>
        </ul>
    </div>
</body>
</html>
"""
    
    with open(output_file, 'w') as f:
        f.write(html)
    
    print(f"\n✅ Rapport HTML généré: {output_file}")

def main():
    # Répertoire des résultats
    results_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    output_file = sys.argv[2] if len(sys.argv) > 2 else "comparison_report.html"
    
    print("📂 Chargement des résultats depuis:", results_dir)
    results = load_test_results(results_dir)
    
    if not results:
        print("❌ Aucun résultat trouvé")
        return 1
    
    print(f"✅ {len(results)} résultats chargés")
    
    # Afficher la comparaison
    compare_results(results)
    
    # Générer le rapport HTML
    generate_html_report(results, output_file)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
