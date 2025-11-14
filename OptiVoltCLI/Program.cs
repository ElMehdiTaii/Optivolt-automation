using System;
using System.CommandLine;
using System.Threading.Tasks;
using OptiVoltCLI.Commands;
using OptiVoltCLI.Services;
using OptiVoltCLI.Logging;

namespace OptiVoltCLI
{
    /// <summary>
    /// OptiVolt CLI - Automatisation des tests de virtualisation
    /// Point d'entrée principal de l'application
    /// </summary>
    class Program
    {
        static async Task<int> Main(string[] args)
        {
            // Affichage de la bannière
            DisplayBanner();

            // Initialisation du logger
            var logger = new ConsoleLogger(LogLevel.Info, includeTimestamp: false);

            try
            {
                // Initialisation des services (Dependency Injection manuel)
                var configService = new ConfigurationService(logger: logger);
                var sshService = new SshService(configService, logger);
                var metricsService = new MetricsService(sshService, logger);

                // Configuration de la commande racine
                var rootCommand = new RootCommand("OptiVolt - Automatisation des tests de virtualisation");

                // Ajout des commandes
                rootCommand.AddCommand(DeployCommand.Create(configService, sshService));
                rootCommand.AddCommand(TestCommand.Create(configService, sshService, metricsService));
                rootCommand.AddCommand(CollectCommand.Create(configService, metricsService));

                // Exécution
                return await rootCommand.InvokeAsync(args);
            }
            catch (Exception ex)
            {
                logger.Critical("Application failed to start", ex);
                return 1;
            }
        }

        private static void DisplayBanner()
        {
            Console.WriteLine("╔═══════════════════════════════════════════════╗");
            Console.WriteLine("║         OptiVolt CLI v1.0.0                   ║");
            Console.WriteLine("║   Automatisation Tests de Virtualisation      ║");
            Console.WriteLine("╚═══════════════════════════════════════════════╝");
            Console.WriteLine();
        }
    }
}
