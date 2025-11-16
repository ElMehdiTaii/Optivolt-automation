#!/usr/bin/env python3
"""
Collecteur de métriques d'énergie et de performance
Alternative à Scaphandre pour environnements sans RAPL
"""

import json
import psutil
import time
import sys
from datetime import datetime

def collect_metrics(duration=10, interval=1):
    """Collecte les métriques pendant une durée donnée"""
    
    print(f"📊 Collecte des métriques pendant {duration}s...")
    
    metrics = {
        "timestamp": datetime.now().isoformat(),
        "duration_seconds": duration,
        "samples": [],
        "summary": {}
    }
    
    start_time = time.time()
    sample_count = 0
    
    # Métriques cumulatives
    cpu_total = 0
    memory_total = 0
    disk_io_read = 0
    disk_io_write = 0
    net_io_sent = 0
    net_io_recv = 0
    
    # Métriques initiales pour le delta
    disk_io_initial = psutil.disk_io_counters()
    net_io_initial = psutil.net_io_counters()
    
    while time.time() - start_time < duration:
        sample = {
            "timestamp": datetime.now().isoformat(),
            "cpu_percent": psutil.cpu_percent(interval=interval),
            "cpu_count": psutil.cpu_count(),
            "memory_percent": psutil.virtual_memory().percent,
            "memory_used_mb": psutil.virtual_memory().used / (1024 * 1024),
            "memory_available_mb": psutil.virtual_memory().available / (1024 * 1024),
        }
        
        # IO stats
        try:
            disk_io = psutil.disk_io_counters()
            sample["disk_read_mb"] = (disk_io.read_bytes - disk_io_initial.read_bytes) / (1024 * 1024)
            sample["disk_write_mb"] = (disk_io.write_bytes - disk_io_initial.write_bytes) / (1024 * 1024)
        except:
            sample["disk_read_mb"] = 0
            sample["disk_write_mb"] = 0
        
        try:
            net_io = psutil.net_io_counters()
            sample["net_sent_mb"] = (net_io.bytes_sent - net_io_initial.bytes_sent) / (1024 * 1024)
            sample["net_recv_mb"] = (net_io.bytes_recv - net_io_initial.bytes_recv) / (1024 * 1024)
        except:
            sample["net_sent_mb"] = 0
            sample["net_recv_mb"] = 0
        
        metrics["samples"].append(sample)
        
        # Cumul pour moyennes
        cpu_total += sample["cpu_percent"]
        memory_total += sample["memory_percent"]
        sample_count += 1
        
        time.sleep(max(0, interval - (time.time() - start_time) % interval))
    
    # Calculer les résumés
    if sample_count > 0:
        metrics["summary"] = {
            "avg_cpu_percent": cpu_total / sample_count,
            "avg_memory_percent": memory_total / sample_count,
            "max_cpu_percent": max(s["cpu_percent"] for s in metrics["samples"]),
            "max_memory_percent": max(s["memory_percent"] for s in metrics["samples"]),
            "total_disk_read_mb": metrics["samples"][-1]["disk_read_mb"],
            "total_disk_write_mb": metrics["samples"][-1]["disk_write_mb"],
            "total_net_sent_mb": metrics["samples"][-1]["net_sent_mb"],
            "total_net_recv_mb": metrics["samples"][-1]["net_recv_mb"],
            "sample_count": sample_count,
        }
        
        # Estimation d'énergie basée sur le CPU (très approximatif)
        # TDP moyen d'un CPU ~65W, utilisation proportionnelle
        tdp_watts = 65
        avg_cpu_fraction = metrics["summary"]["avg_cpu_percent"] / 100
        estimated_power_watts = tdp_watts * avg_cpu_fraction
        estimated_energy_joules = estimated_power_watts * duration
        
        metrics["summary"]["estimated_power_watts"] = round(estimated_power_watts, 2)
        metrics["summary"]["estimated_energy_joules"] = round(estimated_energy_joules, 2)
        metrics["summary"]["estimated_energy_wh"] = round(estimated_energy_joules / 3600, 4)
    
    return metrics

def main():
    duration = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    output_file = sys.argv[2] if len(sys.argv) > 2 else "metrics.json"
    
    try:
        metrics = collect_metrics(duration)
        
        with open(output_file, 'w') as f:
            json.dump(metrics, f, indent=2)
        
        print(f"\n✅ Métriques sauvegardées: {output_file}")
        print(f"\n📊 Résumé:")
        print(f"   CPU moyen: {metrics['summary']['avg_cpu_percent']:.1f}%")
        print(f"   Mémoire moyenne: {metrics['summary']['avg_memory_percent']:.1f}%")
        print(f"   Puissance estimée: {metrics['summary']['estimated_power_watts']:.2f}W")
        print(f"   Énergie estimée: {metrics['summary']['estimated_energy_wh']:.4f} Wh")
        
        return 0
    except KeyboardInterrupt:
        print("\n⚠️  Collecte interrompue")
        return 1
    except Exception as e:
        print(f"\n❌ Erreur: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
