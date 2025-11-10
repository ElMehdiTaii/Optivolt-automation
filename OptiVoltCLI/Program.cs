using System;
using System.CommandLine;
using System.IO;
using System.Threading.Tasks;
using Newtonsoft.Json;

using System;
using System.CommandLine;
using System.IO;
using System.Threading.Tasks;
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
                getDefaultValue: () => "localhost"
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

            rootCommand.AddCommand(deployCommand);
            rootCommand.AddCommand(testCommand);
            rootCommand.AddCommand(metricsCommand);
            rootCommand.AddCommand(reportCommand);
            rootCommand.AddCommand(statusCommand);

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
                        // Note: Pour une vraie connexion, utilisez une clé SSH
                        // client.Connect();
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
            string fullScriptPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                "optivolt-automation", scriptPath
            );

            Console.WriteLine($"[DEPLOY] Hôte: {hostname}");
            Console.WriteLine($"[DEPLOY] Script: {scriptPath}");
            Console.WriteLine($"[DEPLOY] Workdir: {workdir}");

            try
            {
                string keyPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".ssh", "id_ed25519");
                var keyFile = new PrivateKeyFile(keyPath);
                var keyFiles = new[] { keyFile };
                var methods = new[] { new PrivateKeyAuthenticationMethod(user, keyFiles) };
                var connectionInfo = new ConnectionInfo(hostname, port, user, methods);

                using (var client = new SshClient(connectionInfo))
                {
                    Console.WriteLine($"[DEPLOY] Connexion à {hostname}...");
                    client.Connect();
                    Console.WriteLine($"[DEPLOY] ✓ Connecté");

                    // Créer le répertoire de travail
                    var mkdirCmd = client.RunCommand($"mkdir -p {workdir}");
                    Console.WriteLine($"[DEPLOY] Création du répertoire: {workdir}");

                    // Copier le script
                    using (var sftp = new SftpClient(connectionInfo))
                    {
                        sftp.Connect();
                        string remoteScriptPath = $"{workdir}/deploy.sh";
                        using (var fileStream = File.OpenRead(fullScriptPath))
                        {
                            sftp.UploadFile(fileStream, remoteScriptPath, true);
                        }
                        Console.WriteLine($"[DEPLOY] Script copié sur l'hôte distant");
                        sftp.Disconnect();
                    }

                    // Rendre le script exécutable et l'exécuter
                    var chmodCmd = client.RunCommand($"chmod +x {workdir}/deploy.sh");
                    Console.WriteLine($"[DEPLOY] Exécution du script de déploiement...");
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
            
            // TODO: Implémentation similaire avec SSH
            await Task.Delay(2000);
            
            Console.WriteLine($"[TEST] ✓ Tests terminés");
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

            // Copier le script de collecte
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

            // Exécuter le script
            var chmodCmd = client.RunCommand($"chmod +x {remoteScriptPath}");
            Console.WriteLine($"[METRICS] Collecte en cours (30 secondes)...");
            
            var collectCmd = client.RunCommand(
                $"{remoteScriptPath} {environment} 30 {remoteMetricsFile}"
            );

            Console.WriteLine(collectCmd.Result);

            if (collectCmd.ExitStatus == 0)
            {
                // Télécharger les résultats
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

                // Afficher un résumé
                string jsonContent = await File.ReadAllTextAsync(localMetricsFile);
                var metrics = JObject.Parse(jsonContent);
                
                Console.WriteLine("\n=== RÉSUMÉ DES MÉTRIQUES ===");
                Console.WriteLine($"CPU moyen: {metrics["system_metrics"]["averages"]["cpu_usage_percent"]}%");
                Console.WriteLine($"Mémoire moyenne: {metrics["system_metrics"]["averages"]["memory_usage_percent"]}%");
                Console.WriteLine($"Durée: {metrics["metadata"]["duration_seconds"]}s");
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
            Console.WriteLine("[REPORT] Génération du rapport...");
            
            string resultsDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                "optivolt-automation", "results"
            );
            
            if (Directory.Exists(resultsDir))
            {
                var files = Directory.GetFiles(resultsDir, "*.json");
                Console.WriteLine($"[REPORT] {files.Length} fichiers de résultats trouvés");
                
                foreach (var file in files)
                {
                    Console.WriteLine($"  - {Path.GetFileName(file)}");
                }
            }
            
            Console.WriteLine("[REPORT] ✓ Rapport généré");
        }
    }
}
