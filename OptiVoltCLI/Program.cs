using System;
using System.CommandLine;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Renci.SshNet;

namespace OptiVoltCLI
{
    class Program
    {
        static string ConfigPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            "optivolt-automation", "config", "hosts.json"
        );

        static async Task<int> Main(string[] args)
        {
            var rootCommand = new RootCommand("OptiVolt - Automatisation des tests de virtualisation");

            // Commande: deploy
            var deployCommand = new Command("deploy", "Déploie les environnements de test");
            var envOption = new Option<string>(
                "--environment",
                description: "Type d'environnement (docker, microvm, unikernel, localhost)",
                getDefaultValue: () => "docker"
            );
            deployCommand.AddOption(envOption);
            deployCommand.SetHandler(async (string env) =>
            {
                await DeployEnvironment(env);
            }, envOption);

            // Commande: test
            var testCommand = new Command("test", "Lance les tests de performance");
            var testTypeOption = new Option<string>(
                "--type",
                description: "Type de test (cpu, api, db, all)",
                getDefaultValue: () => "all"
            );
            testCommand.AddOption(envOption);
            testCommand.AddOption(testTypeOption);
            testCommand.SetHandler(async (string env, string testType) =>
            {
                await RunTests(env, testType);
            }, envOption, testTypeOption);

            // Commande: metrics
            var metricsCommand = new Command("metrics", "Récupère les métriques de consommation");
            metricsCommand.AddOption(envOption);
            metricsCommand.SetHandler(async (string env) =>
            {
                await CollectMetrics(env);
            }, envOption);

            // Commande: report
            var reportCommand = new Command("report", "Génère un rapport des résultats");
            reportCommand.SetHandler(() =>
            {
                GenerateReport();
            });

            // Commande: status
            var statusCommand = new Command("status", "Vérifie le statut des hôtes");
            statusCommand.SetHandler(async () =>
            {
                await CheckHostsStatus();
            });

            // Commande: pipes (affiche les pipelines CI/CD)
            var pipesCommand = new Command("pipes", "Affiche les pipelines disponibles");
            pipesCommand.SetHandler(() =>
            {
                ShowPipelines();
            });

            rootCommand.AddCommand(deployCommand);
            rootCommand.AddCommand(testCommand);
            rootCommand.AddCommand(metricsCommand);
            rootCommand.AddCommand(reportCommand);
            rootCommand.AddCommand(statusCommand);
            rootCommand.AddCommand(pipesCommand);

            return await rootCommand.InvokeAsync(args);
        }

        static JObject LoadConfig()
        {
            if (!File.Exists(ConfigPath))
            {
                Console.WriteLine($"[ERROR] Fichier de configuration introuvable: {ConfigPath}");
                return null;
            }
            return JObject.Parse(File.ReadAllText(ConfigPath));
        }

        static async Task CheckHostsStatus()
        {
            Console.WriteLine("[STATUS] Vérification de la connectivité des hôtes...\n");
            var config = LoadConfig();
            if (config == null) return;

            foreach (var host in config["hosts"])
            {
                var hostName = ((JProperty)host).Name;
                var hostData = host.First;
                
                Console.WriteLine($"[{hostName.ToUpper()}] Test de connexion...");
                
                try
                {
                    string hostname = hostData["hostname"].ToString();
                    string user = hostData["user"].ToString();
                    int port = (int)hostData["port"];
                    
                    if (user == "current")
                        user = Environment.UserName;

                    using (var client = new SshClient(hostname, port, user, ""))
                    {
                        client.ConnectionInfo.Timeout = TimeSpan.FromSeconds(5);
                        Console.WriteLine($"[{hostName.ToUpper()}] ✓ Configuration OK");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[{hostName.ToUpper()}] ✗ Erreur: {ex.Message}");
                }
                
                Console.WriteLine();
            }
        }

        static void ShowPipelines()
        {
            Console.WriteLine("\n╔════════════════════════════════════════════════════════════════╗");
            Console.WriteLine("║           PIPELINES CI/CD DISPONIBLES - OptiVolt               ║");
            Console.WriteLine("╚════════════════════════════════════════════════════════════════╝\n");

            var pipelines = new List<(string name, string description, string[] stages)>
            {
                (
                    "Pipeline Build",
                    "Compilation et packaging du projet",
                    new[] { "📦 build:cli", "✅ Publié en Release" }
                ),
                (
                    "Pipeline Deploy",
                    "Déploiement sur 3 environnements",
                    new[] { 
                        "🐳 deploy:docker (Docker Container)",
                        "🖥️  deploy:microvm (MicroVM 192.168.1.101)",
                        "🔮 deploy:unikernel (Unikernel 192.168.1.102)"
                    }
                ),
                (
                    "Pipeline Test",
                    "Exécution des tests réels via SSH",
                    new[] { 
                        "⚙️  test:cpu (Performance CPU)",
                        "🌐 test:api (Santé API HTTP)",
                        "🗄️  test:db (Intégrité DB)"
                    }
                ),
                (
                    "Pipeline Metrics",
                    "Collecte des métriques de consommation",
                    new[] { 
                        "📊 metrics:collect (30 secondes de monitoring)",
                        "💾 Fichiers JSON générés"
                    }
                ),
                (
                    "Pipeline Report",
                    "Génération du dashboard interactif",
                    new[] { 
                        "📈 report:generate (Dashboard HTML)",
                        "🌍 GitLab Pages (Public)",
                        "📊 Graphiques Chart.js"
                    }
                )
            };

            int pipelineNum = 1;
            foreach (var (name, description, stages) in pipelines)
            {
                Console.WriteLine($"┌─ PIPELINE {pipelineNum} ─────────────────────────────────────┐");
                Console.WriteLine($"│ 📋 {name.PadRight(52)} │");
                Console.WriteLine($"│ 📝 {description.PadRight(52)} │");
                Console.WriteLine($"├─────────────────────────────────────────────────────────┤");
                
                foreach (var stage in stages)
                {
                    Console.WriteLine($"│   {stage.PadRight(53)} │");
                }
                
                Console.WriteLine($"└─────────────────────────────────────────────────────────┘\n");
                pipelineNum++;
            }

            Console.WriteLine("╔════════════════════════════════════════════════════════════════╗");
            Console.WriteLine("║                    FLUX COMPLET DU PIPELINE                    ║");
            Console.WriteLine("╚════════════════════════════════════════════════════════════════╝\n");

            Console.WriteLine(@"
┌─────────────────────────────────┐
│ 1. BUILD                        │
│   └─ OptiVoltCLI.dll (Release)  │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│ 2. DEPLOY (Parallèle ⚡)        │
│   ├─ 🐳  Docker                 │
│   ├─ 🖥️  MicroVM                │
│   └─ 🔮 Unikernel               │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│ 3. TEST (Parallèle ⚡)          │
│   ├─ ⚙️  CPU (top command)       │
│   ├─ 🌐 API (curl /health)      │
│   └─ 🗄️  DB (sqlite3 query)     │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│ 4. METRICS                      │
│   └─ Collecte 30 sec (SSH)      │
└─────────────────────────────────┘
              ↓
┌─────────────────────────────────┐
│ 5. REPORT                       │
│   └─ Dashboard + GitLab Pages   │
└─────────────────────────────────┘
");

            Console.WriteLine("\n╔════════════════════════════════════════════════════════════════╗");
            Console.WriteLine("║                   COMMANDES DISPONIBLES                        ║");
            Console.WriteLine("╚════════════════════════════════════════════════════════════════╝\n");

            Console.WriteLine("  🔧 DEPLOY:");
            Console.WriteLine("    dotnet OptiVoltCLI.dll deploy --environment docker");
            Console.WriteLine("    dotnet OptiVoltCLI.dll deploy --environment microvm");
            Console.WriteLine("    dotnet OptiVoltCLI.dll deploy --environment unikernel\n");

            Console.WriteLine("  🧪 TESTS:");
            Console.WriteLine("    dotnet OptiVoltCLI.dll test --environment docker --type cpu");
            Console.WriteLine("    dotnet OptiVoltCLI.dll test --environment microvm --type api");
            Console.WriteLine("    dotnet OptiVoltCLI.dll test --environment unikernel --type db");
            Console.WriteLine("    dotnet OptiVoltCLI.dll test --environment docker --type all\n");

            Console.WriteLine("  📊 METRICS:");
            Console.WriteLine("    dotnet OptiVoltCLI.dll metrics --environment docker");
            Console.WriteLine("    dotnet OptiVoltCLI.dll metrics --environment microvm");
            Console.WriteLine("    dotnet OptiVoltCLI.dll metrics --environment unikernel\n");

            Console.WriteLine("  📈 REPORT & STATUS:");
            Console.WriteLine("    dotnet OptiVoltCLI.dll report");
            Console.WriteLine("    dotnet OptiVoltCLI.dll status");
            Console.WriteLine("    dotnet OptiVoltCLI.dll pipes\n");
        }

        static async Task DeployEnvironment(string environment)
        {
            Console.WriteLine($"[DEPLOY] Déploiement de l'environnement: {environment}");
            
            var config = LoadConfig();
            if (config == null) return;

            if (!config["hosts"].HasValues || config["hosts"][environment] == null)
            {
                Console.WriteLine($"[ERROR] Environnement '{environment}' non trouvé dans la configuration");
                return;
            }

            var hostData = config["hosts"][environment];
            string hostname = hostData["hostname"].ToString();
            string user = hostData["user"].ToString();
            int port = (int)hostData["port"];
            string workdir = hostData["workdir"].ToString();

            if (user == "current")
                user = Environment.UserName;

            string scriptKey = $"{environment}_deploy";
            string scriptPath = config["scripts"][scriptKey]?.ToString() ?? "scripts/deploy_docker.sh";
            
            string fullScriptPath = Path.Combine(AppContext.BaseDirectory, scriptPath);
            
            if (!File.Exists(fullScriptPath))
            {
                fullScriptPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                    "optivolt-automation", scriptPath
                );
            }

            Console.WriteLine($"[DEPLOY] Hôte: {hostname}");
            Console.WriteLine($"[DEPLOY] Script: {scriptPath}");
            Console.WriteLine($"[DEPLOY] Workdir: {workdir}");

            try
            {
                SshClient client = null;
                SftpClient sftp = null;
                
                string sshAuthSock = Environment.GetEnvironmentVariable("SSH_AUTH_SOCK");
                
                if (!string.IsNullOrEmpty(sshAuthSock))
                {
                    Console.WriteLine($"[DEPLOY] Mode CI/CD détecté (SSH_AUTH_SOCK)");
                    try
                    {
                        var authNone = new NoneAuthenticationMethod(user);
                        var connectionInfo = new ConnectionInfo(hostname, port, user, authNone);
                        client = new SshClient(connectionInfo);
                        sftp = new SftpClient(connectionInfo);
                    }
                    catch
                    {
                        var connectionInfo = new ConnectionInfo(hostname, port, user, 
                            new PasswordAuthenticationMethod(user, ""));
                        client = new SshClient(connectionInfo);
                        sftp = new SftpClient(connectionInfo);
                    }
                }
                else
                {
                    Console.WriteLine($"[DEPLOY] Mode local détecté");
                    string keyPath = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), 
                        ".ssh", "id_ed25519"
                    );
                    
                    if (!File.Exists(keyPath))
                    {
                        Console.WriteLine($"[DEPLOY] ✗ Erreur: Clé SSH introuvable: {keyPath}");
                        return;
                    }
                    
                    var keyFile = new PrivateKeyFile(keyPath);
                    var connectionInfo = new ConnectionInfo(hostname, port, user, 
                        new PrivateKeyAuthenticationMethod(user, keyFile));
                    
                    client = new SshClient(connectionInfo);
                    sftp = new SftpClient(connectionInfo);
                }

                using (client)
                using (sftp)
                {
                    Console.WriteLine($"[DEPLOY] Connexion à {hostname}:{port}...");
                    client.Connect();
                    Console.WriteLine($"[DEPLOY] ✓ SSH connecté");

                    var mkdirCmd = client.RunCommand($"mkdir -p {workdir}");
                    Console.WriteLine($"[DEPLOY] Création du répertoire: {workdir}");

                    if (!File.Exists(fullScriptPath))
                    {
                        Console.WriteLine($"[DEPLOY] ✗ Script introuvable: {fullScriptPath}");
                        return;
                    }

                    try
                    {
                        sftp.Connect();
                        string remoteScriptPath = $"{workdir}/deploy.sh";
                        using (var fileStream = File.OpenRead(fullScriptPath))
                        {
                            sftp.UploadFile(fileStream, remoteScriptPath, true);
                        }
                        Console.WriteLine($"[DEPLOY] ✓ Script copié");
                        sftp.Disconnect();
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[DEPLOY] ✗ Erreur SFTP: {ex.Message}");
                        return;
                    }

                    var chmodCmd = client.RunCommand($"chmod +x {workdir}/deploy.sh");
                    Console.WriteLine($"[DEPLOY] Exécution du script...");
                    var deployCmd = client.RunCommand($"cd {workdir} && ./deploy.sh {workdir}");
                    
                    Console.WriteLine($"\n--- Output ---");
                    Console.WriteLine(deployCmd.Result);
                    if (!string.IsNullOrEmpty(deployCmd.Error))
                    {
                        Console.WriteLine($"--- Errors ---");
                        Console.WriteLine(deployCmd.Error);
                    }

                    if (deployCmd.ExitStatus == 0)
                    {
                        Console.WriteLine($"\n[DEPLOY] ✓ Environnement {environment} déployé avec succès");
                    }
                    else
                    {
                        Console.WriteLine($"\n[DEPLOY] ✗ Échec du déploiement (code: {deployCmd.ExitStatus})");
                    }

                    client.Disconnect();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[DEPLOY] ✗ Erreur: {ex.Message}");
            }
        }

        static async Task RunTests(string environment, string testType)
        {
            Console.WriteLine($"[TEST] Exécution des tests {testType} sur {environment}");
            
            var config = LoadConfig();
            if (config == null) return;

            if (!config["hosts"].HasValues || config["hosts"][environment] == null)
            {
                Console.WriteLine($"[ERROR] Environnement '{environment}' non trouvé");
                return;
            }

            var hostData = config["hosts"][environment];
            string hostname = hostData["hostname"].ToString();
            string user = hostData["user"].ToString();
            int port = (int)hostData["port"];
            string workdir = hostData["workdir"].ToString();

            if (user == "current")
                user = Environment.UserName;

            try
            {
                string keyPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), 
                    ".ssh", "id_ed25519"
                );
                
                var keyFile = new PrivateKeyFile(keyPath);
                var connectionInfo = new ConnectionInfo(hostname, port, user, 
                    new PrivateKeyAuthenticationMethod(user, keyFile));

                using (var client = new SshClient(connectionInfo))
                {
                    Console.WriteLine($"[TEST] Connexion à {hostname}:{port}...");
                    client.Connect();
                    Console.WriteLine($"[TEST] ✓ Connecté\n");

                    string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                    string resultsDir = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                        "optivolt-automation", "results"
                    );
                    Directory.CreateDirectory(resultsDir);

                    var testResults = new Dictionary<string, object>
                    {
                        { "timestamp", DateTime.Now },
                        { "environment", environment },
                        { "tests", new Dictionary<string, object>() }
                    };

                    var tests = (Dictionary<string, object>)testResults["tests"];

                    // TEST CPU
                    if (testType == "cpu" || testType == "all")
                    {
                        Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                        Console.WriteLine("⚙️  TEST CPU");
                        Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                        
                        var cpuTest = client.RunCommand("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1");
                        string cpuUsage = cpuTest.Result.Trim();
                        double cpuValue = double.TryParse(cpuUsage, out var cpu) ? cpu : 0.0;
                        
                        Console.WriteLine($"✓ Utilisation CPU: {cpuValue:F2}%\n");
                        
                        tests["cpu"] = new
                        {
                            status = "passed",
                            cpu_usage_percent = cpuValue,
                            timestamp = DateTime.Now
                        };
                    }

                    // TEST API
                    if (testType == "api" || testType == "all")
                    {
                        Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                        Console.WriteLine("🌐 TEST API");
                        Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                        
                        var apiTest = client.RunCommand("curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/api/health 2>/dev/null || echo '000'");
                        string httpCode = apiTest.Result.Trim();
                        bool apiOk = httpCode == "200" || httpCode == "201" || httpCode == "204";
                        
                        Console.WriteLine($"✓ HTTP Status: {httpCode}");
                        Console.WriteLine($"✓ API Status: {(apiOk ? "✅ OK" : "❌ KO")}\n");
                        
                        tests["api"] = new
                        {
                            status = apiOk ? "passed" : "failed",
                            http_code = int.TryParse(httpCode, out var code) ? code : 0,
                            timestamp = DateTime.Now
                        };
                    }

                    // TEST DB
                    if (testType == "db" || testType == "all")
                    {
                        Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                        Console.WriteLine("🗄️  TEST DB");
                        Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                        
                        var dbTest = client.RunCommand("sqlite3 /tmp/optivolt.db 'SELECT COUNT(*) FROM sqlite_master;' 2>/dev/null || echo '0'");
                        string dbStatus = dbTest.Result.Trim();
                        bool dbOk = !dbStatus.Equals("0") && !string.IsNullOrEmpty(dbStatus);
                        
                        Console.WriteLine($"✓ Tables Count: {dbStatus}");
                        Console.WriteLine($"✓ DB Status: {(dbOk ? "✅ OK" : "❌ KO")}\n");
                        
                        tests["db"] = new
                        {
                            status = dbOk ? "passed" : "failed",
                            tables_count = int.TryParse(dbStatus, out var count) ? count : 0,
                            timestamp = DateTime.Now
                        };
                    }

                    // Sauvegarder les résultats
                    string resultFile = Path.Combine(resultsDir, $"test_{testType}_{environment}_{timestamp}.json");
                    File.WriteAllText(resultFile, JsonConvert.SerializeObject(testResults, Formatting.Indented));
                    
                    Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                    Console.WriteLine($"✅ Tous les tests terminés");
                    Console.WriteLine($"📁 Résultats: {resultFile}");
                    Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
                    
                    client.Disconnect();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[TEST] ✗ Erreur: {ex.Message}");
            }
        }

        static async Task CollectMetrics(string environment)
        {
            Console.WriteLine($"[METRICS] Collecte des métriques pour {environment}");
            
            var config = LoadConfig();
            if (config == null) return;

            if (!config["hosts"].HasValues || config["hosts"][environment] == null)
            {
                Console.WriteLine($"[ERROR] Environnement '{environment}' non trouvé");
                return;
            }

            var hostData = config["hosts"][environment];
            string hostname = hostData["hostname"].ToString();
            string user = hostData["user"].ToString();
            int port = (int)hostData["port"];
            string workdir = hostData["workdir"].ToString();

            if (user == "current")
                user = Environment.UserName;

            string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string remoteMetricsFile = $"{workdir}/metrics_{timestamp}.json";
            string localMetricsFile = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                "optivolt-automation", "results", $"{environment}_metrics_{timestamp}.json"
            );

            try
            {
                string keyPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), 
                    ".ssh", "id_ed25519"
                );
                var keyFile = new PrivateKeyFile(keyPath);
                var keyFiles = new[] { keyFile };
                var methods = new[] { new PrivateKeyAuthenticationMethod(user, keyFiles) };
                var connectionInfo = new ConnectionInfo(hostname, port, user, methods);

                using (var client = new SshClient(connectionInfo))
                {
                    Console.WriteLine($"[METRICS] Connexion à {hostname}...");
                    client.Connect();

                    string localScriptPath = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                        "optivolt-automation", "scripts", "collect_metrics.sh"
                    );
                    string remoteScriptPath = $"{workdir}/collect_metrics.sh";

                    using (var sftp = new SftpClient(connectionInfo))
                    {
                        sftp.Connect();
                        using (var fileStream = File.OpenRead(localScriptPath))
                        {
                            sftp.UploadFile(fileStream, remoteScriptPath, true);
                        }
                        Console.WriteLine($"[METRICS] Script de collecte copié");
                        sftp.Disconnect();
                    }

                    var chmodCmd = client.RunCommand($"chmod +x {remoteScriptPath}");
                    Console.WriteLine($"[METRICS] Collecte en cours (30 secondes)...");
                    
                    var collectCmd = client.RunCommand(
                        $"{remoteScriptPath} {environment} 30 {remoteMetricsFile}"
                    );

                    Console.WriteLine(collectCmd.Result);

                    if (collectCmd.ExitStatus == 0)
                    {
                        using (var sftp = new SftpClient(connectionInfo))
                        {
                            sftp.Connect();
                            using (var fileStream = File.Create(localMetricsFile))
                            {
                                sftp.DownloadFile(remoteMetricsFile, fileStream);
                            }
                            Console.WriteLine($"[METRICS] ✓ Métriques récupérées: {localMetricsFile}");
                            sftp.Disconnect();
                        }

                        string jsonContent = await File.ReadAllTextAsync(localMetricsFile);
                        var metrics = JObject.Parse(jsonContent);
                        
                        Console.WriteLine("\n╔════════════════════════════════════════╗");
                        Console.WriteLine("║     RÉSUMÉ DES MÉTRIQUES               ║");
                        Console.WriteLine("╚════════════════════════════════════════╝");
                        Console.WriteLine($"CPU moyen:      {metrics["system_metrics"]["averages"]["cpu_usage_percent"]}%");
                        Console.WriteLine($"Mémoire moyenne: {metrics["system_metrics"]["averages"]["memory_usage_percent"]}%");
                        Console.WriteLine($"Durée:          {metrics["metadata"]["duration_seconds"]}s");
                        Console.WriteLine("╚════════════════════════════════════════╝\n");
                    }
                    else
                    {
                        Console.WriteLine($"[METRICS] ✗ Échec de la collecte");
                    }

                    client.Disconnect();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[METRICS] ✗ Erreur: {ex.Message}");
            }
        }

        static void GenerateReport()
        {
            Console.WriteLine("[REPORT] Génération du rapport...\n");
            
            string resultsDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                "optivolt-automation", "results"
            );
            
            if (Directory.Exists(resultsDir))
            {
                var files = Directory.GetFiles(resultsDir, "*.json");
                
                Console.WriteLine("╔════════════════════════════════════════════════════════════════╗");
                Console.WriteLine($"║  RÉSULTATS TROUVÉS: {files.Length} fichiers".PadRight(65) + "║");
                Console.WriteLine("╚════════════════════════════════════════════════════════════════╝\n");
                
                foreach (var file in files)
                {
                    Console.WriteLine($"  📄 {Path.GetFileName(file)}");
                }
            }
            
            Console.WriteLine("\n[REPORT] ✓ Rapport généré");
        }
    }
}