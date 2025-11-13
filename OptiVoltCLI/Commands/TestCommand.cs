using System;
using System.CommandLine;
using System.Threading.Tasks;
using OptiVoltCLI.Services;
using OptiVoltCLI.Models;

namespace OptiVoltCLI.Commands
{
    public static class TestCommand
    {
        public static Command Create(
            ConfigurationService configService, 
            SshService sshService, 
            MetricsService metricsService)
        {
            var testCommand = new Command("test", "Lance les tests de performance");
            
            var envOption = new Option<string>(
                "--environment",
                description: "Environnement de test (docker, microvm, unikernel)",
                getDefaultValue: () => "docker"
            );
            
            var typeOption = new Option<string>(
                "--type",
                description: "Type de test (cpu, api, db, all)",
                getDefaultValue: () => "all"
            );
            
            var durationOption = new Option<int>(
                "--duration",
                description: "Durée du test en secondes",
                getDefaultValue: () => 30
            );

            testCommand.AddOption(envOption);
            testCommand.AddOption(typeOption);
            testCommand.AddOption(durationOption);
            
            testCommand.SetHandler(async (string env, string type, int duration) =>
            {
                await ExecuteAsync(env, type, duration, sshService, metricsService);
            }, envOption, typeOption, durationOption);

            return testCommand;
        }

        private static async Task ExecuteAsync(
            string environment, 
            string testType, 
            int duration,
            SshService sshService,
            MetricsService metricsService)
        {
            Console.WriteLine("========================================");
            Console.WriteLine($"🧪 Lancement des tests: {testType}");
            Console.WriteLine($"📍 Environnement: {environment}");
            Console.WriteLine($"⏱️  Durée: {duration}s");
            Console.WriteLine("========================================");

            var testsToRun = testType == "all" 
                ? new[] { "cpu", "api", "db" } 
                : new[] { testType };

            foreach (var test in testsToRun)
            {
                Console.WriteLine($"\n▶️  Test: {test}");
                
                var command = $"bash scripts/run_test_{test}.sh {duration}";
                var (success, output) = await sshService.ExecuteCommandAsync(environment, command, duration + 60);

                if (success)
                {
                    Console.WriteLine($"✅ Test {test} terminé");
                    
                    // Collecter les métriques
                    var result = await metricsService.CollectMetricsAsync(environment, test);
                    result.DurationSeconds = duration;
                    
                    var outputPath = $"test_{test}_{environment}.json";
                    await metricsService.SaveResultAsync(result, outputPath);
                }
                else
                {
                    Console.WriteLine($"❌ Test {test} échoué");
                    Console.WriteLine(output);
                }
            }

            Console.WriteLine("\n========================================");
            Console.WriteLine("✅ Tests terminés");
            Console.WriteLine("========================================");
        }
    }
}
