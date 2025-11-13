#!/usr/bin/env python3
"""
OptiVolt Workload Benchmark
Génère une charge CPU/mémoire mesurable pour comparer Docker/MicroVM/Unikernel
"""

import time
import hashlib
import sys
import json
import psutil
import os
from datetime import datetime

class WorkloadBenchmark:
    def __init__(self, duration_sec=30, intensity="medium"):
        self.duration = duration_sec
        self.intensity = intensity
        self.results = {
            "start_time": datetime.now().isoformat(),
            "duration_sec": duration_sec,
            "intensity": intensity,
            "iterations": 0,
            "cpu_samples": [],
            "memory_samples": [],
            "metrics": {}
        }
        
    def run_crypto_workload(self):
        """Charge CPU intensive avec calculs cryptographiques"""
        print(f"[WORKLOAD] Démarrage benchmark crypto (durée: {self.duration}s)")
        print(f"[WORKLOAD] Intensité: {self.intensity}")
        
        start_time = time.time()
        iteration = 0
        
        # Intensité détermine le nombre d'opérations
        ops_per_iteration = {
            "light": 5000,
            "medium": 15000,
            "heavy": 50000
        }.get(self.intensity, 15000)
        
        while (time.time() - start_time) < self.duration:
            # Génération de données
            data = f"optivolt-benchmark-{iteration}-{time.time()}".encode()
            
            # Calculs cryptographiques
            for _ in range(ops_per_iteration):
                hash_result = hashlib.sha256(data).hexdigest()
                hash_result = hashlib.sha512(hash_result.encode()).hexdigest()
            
            iteration += 1
            
            # Collecte des métriques toutes les 2 secondes
            if iteration % 10 == 0:
                cpu_percent = psutil.cpu_percent(interval=0.1)
                mem_info = psutil.virtual_memory()
                
                self.results["cpu_samples"].append({
                    "timestamp": time.time() - start_time,
                    "cpu_percent": cpu_percent
                })
                self.results["memory_samples"].append({
                    "timestamp": time.time() - start_time,
                    "memory_mb": mem_info.used / (1024 * 1024),
                    "memory_percent": mem_info.percent
                })
                
                print(f"[WORKLOAD] Iter {iteration} | CPU: {cpu_percent:.1f}% | "
                      f"MEM: {mem_info.percent:.1f}% ({mem_info.used/(1024*1024):.0f}MB)")
                sys.stdout.flush()
            
            # Petite pause pour éviter saturation totale
            time.sleep(0.05)
        
        self.results["iterations"] = iteration
        self.results["end_time"] = datetime.now().isoformat()
        
        # Calcul des statistiques
        self._calculate_stats()
        
        return self.results
    
    def _calculate_stats(self):
        """Calcule les statistiques finales"""
        if self.results["cpu_samples"]:
            cpu_values = [s["cpu_percent"] for s in self.results["cpu_samples"]]
            self.results["metrics"]["cpu_avg"] = sum(cpu_values) / len(cpu_values)
            self.results["metrics"]["cpu_max"] = max(cpu_values)
            self.results["metrics"]["cpu_min"] = min(cpu_values)
        
        if self.results["memory_samples"]:
            mem_values = [s["memory_mb"] for s in self.results["memory_samples"]]
            self.results["metrics"]["memory_avg_mb"] = sum(mem_values) / len(mem_values)
            self.results["metrics"]["memory_max_mb"] = max(mem_values)
        
        # Throughput
        self.results["metrics"]["iterations_per_sec"] = (
            self.results["iterations"] / self.duration
        )
        
        print("\n" + "="*50)
        print("[WORKLOAD] Résultats du benchmark")
        print("="*50)
        print(f"Itérations totales:     {self.results['iterations']}")
        print(f"Itérations/sec:         {self.results['metrics']['iterations_per_sec']:.2f}")
        print(f"CPU moyen:              {self.results['metrics'].get('cpu_avg', 0):.1f}%")
        print(f"CPU max:                {self.results['metrics'].get('cpu_max', 0):.1f}%")
        print(f"Mémoire moyenne:        {self.results['metrics'].get('memory_avg_mb', 0):.0f} MB")
        print(f"Mémoire max:            {self.results['metrics'].get('memory_max_mb', 0):.0f} MB")
        print("="*50 + "\n")
    
    def save_results(self, output_file="/tmp/workload_results.json"):
        """Sauvegarde les résultats en JSON"""
        with open(output_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        print(f"[WORKLOAD] Résultats sauvegardés: {output_file}")


def main():
    # Paramètres par défaut
    duration = int(os.getenv("WORKLOAD_DURATION", "30"))
    intensity = os.getenv("WORKLOAD_INTENSITY", "medium")
    output_file = os.getenv("WORKLOAD_OUTPUT", "/tmp/workload_results.json")
    
    print("="*50)
    print("OptiVolt Workload Benchmark")
    print("="*50)
    print(f"Durée:      {duration}s")
    print(f"Intensité:  {intensity}")
    print(f"Output:     {output_file}")
    print("="*50 + "\n")
    
    # Informations système
    print(f"[INFO] CPU cores:   {psutil.cpu_count()}")
    print(f"[INFO] CPU freq:    {psutil.cpu_freq().current if psutil.cpu_freq() else 'N/A'} MHz")
    print(f"[INFO] RAM total:   {psutil.virtual_memory().total / (1024**3):.1f} GB")
    print(f"[INFO] Platform:    {sys.platform}\n")
    
    # Exécution du benchmark
    benchmark = WorkloadBenchmark(duration_sec=duration, intensity=intensity)
    
    try:
        results = benchmark.run_crypto_workload()
        benchmark.save_results(output_file)
        print("\n✅ [WORKLOAD] Benchmark terminé avec succès")
        return 0
    except Exception as e:
        print(f"\n❌ [WORKLOAD] Erreur: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
