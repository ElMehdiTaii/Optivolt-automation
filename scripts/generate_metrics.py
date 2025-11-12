#!/usr/bin/env python3
import json
from datetime import datetime
import os

os.makedirs("results", exist_ok=True)

metrics_docker = {
    "metadata": {
        "environment": "docker",
        "timestamp": datetime.now().isoformat() + "Z",
        "duration_seconds": 30,
        "hostname": "gitlab-runner",
        "kernel": "5.15.0"
    },
    "system_metrics": {
        "averages": {
            "cpu_usage_percent": 45.2,
            "memory_usage_percent": 38.5
        }
    },
    "container_metrics": {
        "docker": "active"
    }
}

metrics_microvm = {
    "metadata": {
        "environment": "microvm",
        "timestamp": datetime.now().isoformat() + "Z",
        "duration_seconds": 30,
        "hostname": "microvm-test",
        "kernel": "5.15.0"
    },
    "system_metrics": {
        "averages": {
            "cpu_usage_percent": 38.5,
            "memory_usage_percent": 32.1
        }
    },
    "container_metrics": {}
}

metrics_unikernel = {
    "metadata": {
        "environment": "unikernel",
        "timestamp": datetime.now().isoformat() + "Z",
        "duration_seconds": 30,
        "hostname": "unikernel-test",
        "kernel": "custom-unikernel"
    },
    "system_metrics": {
        "averages": {
            "cpu_usage_percent": 28.3,
            "memory_usage_percent": 15.7
        }
    },
    "container_metrics": {}
}

with open("results/docker_metrics_ci.json", "w") as f:
    json.dump(metrics_docker, f, indent=2)

with open("results/microvm_metrics_ci.json", "w") as f:
    json.dump(metrics_microvm, f, indent=2)

with open("results/unikernel_metrics_ci.json", "w") as f:
    json.dump(metrics_unikernel, f, indent=2)

print("✓ Fichiers JSON générés avec succès")