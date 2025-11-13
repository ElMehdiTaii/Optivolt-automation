# 🚀 Structure CI/CD OptiVolt

Ce dossier contient la configuration CI/CD modulaire pour le projet OptiVolt.

## 📁 Organisation

```
.gitlab/
└── ci/
    ├── build.yml       # Compilation et publication
    ├── deploy.yml      # Déploiement (Docker, MicroVM, Unikernel)
    ├── test.yml        # Tests de charge (CPU, API, DB)
    ├── metrics.yml     # Collecte des métriques système
    ├── power.yml       # Monitoring énergétique (Scaphandre)
    └── report.yml      # Génération du rapport final
```

## 📋 Fichiers

### `build.yml` (26 lignes)
- **Job:** `build:cli`
- **Description:** Compile le projet OptiVoltCLI avec .NET 8.0
- **Artifacts:** Binaires dans `/publish` (1h)

### `deploy.yml` (112 lignes)
- **Jobs:** `deploy:docker`, `deploy:microvm`, `deploy:unikernel`
- **Description:** Déploiement sur les 3 environnements cibles
- **Artifacts:** Résultats JSON de déploiement

### `test.yml` (70 lignes)
- **Jobs:** `test:cpu`, `test:api`, `test:db`
- **Description:** Tests de charge sur chaque type de workload
- **Artifacts:** Résultats JSON des tests (1 semaine)

### `metrics.yml` (33 lignes)
- **Job:** `metrics:collect`
- **Description:** Collecte des métriques système et benchmark
- **Artifacts:** Métriques et résultats workload (1 mois)

### `power.yml` (69 lignes)
- **Jobs:** `power:scaphandre-setup`, `power:collect-energy`
- **Description:** Installation Scaphandre et collecte consommation électrique
- **Artifacts:** Données de consommation énergétique (1 mois)

### `report.yml` (31 lignes)
- **Job:** `report:generate`
- **Description:** Génère le dashboard HTML final
- **Artifacts:** Rapport public GitLab Pages (3 mois)

## 🎯 Avantages

### ✅ Maintenabilité
- Chaque stage dans son propre fichier
- Modifications isolées et faciles à tester
- Historique Git clair par fonctionnalité

### ✅ Lisibilité
- Fichier principal réduit de 334 → 27 lignes
- Structure claire avec commentaires
- Navigation simplifiée dans le code

### ✅ Réutilisabilité
- Jobs modulaires facilement réutilisables
- Possibilité d'inclure/exclure des stages
- Templates réutilisables pour d'autres projets

### ✅ Collaboration
- Plusieurs développeurs peuvent travailler en parallèle
- Moins de conflits Git
- Revues de code plus ciblées

## 🔧 Utilisation

Le fichier principal `.gitlab-ci.yml` inclut automatiquement tous les fichiers :

```yaml
include:
  - local: '.gitlab/ci/build.yml'
  - local: '.gitlab/ci/deploy.yml'
  - local: '.gitlab/ci/test.yml'
  - local: '.gitlab/ci/metrics.yml'
  - local: '.gitlab/ci/power.yml'
  - local: '.gitlab/ci/report.yml'
```

## 📝 Modification

Pour modifier un stage spécifique :

1. Ouvrir le fichier correspondant dans `.gitlab/ci/`
2. Modifier le job concerné
3. Valider la syntaxe : `yamllint -d relaxed .gitlab/ci/nom-fichier.yml`
4. Commit et push

## 🧪 Validation locale

```bash
# Valider tous les fichiers CI/CD
yamllint -d relaxed .gitlab-ci.yml .gitlab/ci/*.yml

# Vérifier la structure
tree .gitlab/

# Compter les lignes
wc -l .gitlab-ci.yml .gitlab/ci/*.yml
```

## 📊 Statistiques

- **Total:** 368 lignes de configuration CI/CD
- **Fichier principal:** 27 lignes (92% de réduction)
- **Fichiers modulaires:** 6 fichiers thématiques
- **Validation:** 100% YAML valide

## 🔗 Références

- [Documentation GitLab CI Include](https://docs.gitlab.com/ee/ci/yaml/#include)
- [Best Practices GitLab CI](https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html)
- [OptiVolt Documentation](../../README.md)
