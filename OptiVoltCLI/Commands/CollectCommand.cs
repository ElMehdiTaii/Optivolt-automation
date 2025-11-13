using System;
using System.CommandLine;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;
using Newtonsoft.Json;
using OptiVoltCLI.Services;
using OptiVoltCLI.Models;

namespace OptiVoltCLI.Commands
{
    public static class CollectCommand
    {
        public static Command Create(
            ConfigurationService configService, 
            MetricsService metricsService)
        {
            var collectCommand = new Command("collect", "Collecte les métriques des environnements");
            
            var envOption = new Option<string>(
                "--environment",
                description: "Environnement (docker, microvm, unikernel, all)",
                getDefaultValue: () => "all"
            );
            
            var outputOption = new Option<string>(
                "--output",
                description: "Fichier de sortie JSON",
                getDefaultValue: () => "collected_metrics.json"
            );

            collectCommand.AddOption(envOption);
            collectCommand.AddOption(outputOption);
            
            collectCommand.SetHandler(async (string env, string output) =>
            {
                await ExecuteAsync(env, output, metricsService);
            }, envOption, outputOption);

            return collectCommand;
        }

        private static async Task ExecuteAsync(
            string environment,
            string outputPath,
            MetricsService metricsService)
        {
            Console.WriteLine("========================================");
            Console.WriteLine("📊 Collecte des métriques");
            Console.WriteLine("========================================");

            var environments = environment == "all" 
                ? new[] { "docker", "microvm", "unikernel" }
                : new[] { environment };

            var allResults = new List<TestResult>();

            foreach (var env in environments)
            {
                Console.WriteLine($"\n📍 Environnement: {env}");
                
                foreach (var testType in new[] { "cpu", "api", "db" })
                {
                    var result = await metricsService.CollectMetricsAsync(env, testType);
                    allResults.Add(result);
                }
            }

            // Sauvegarder tous les résultats
            try
            {
                var json = JsonConvert.SerializeObject(new { 
                    collected_at = DateTime.UtcNow,
                    results = allResults 
                }, Formatting.Indented);

                await File.WriteAllTextAsync(outputPath, json);
                Console.WriteLine($"\n✅ Métriques collectées: {outputPath}");
                Console.WriteLine($"📊 Total: {allResults.Count} résultats");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Erreur lors de la sauvegarde: {ex.Message}");
                Environment.Exit(1);
            }
        }
    }
}
