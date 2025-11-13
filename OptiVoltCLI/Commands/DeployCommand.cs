using System;
using System.CommandLine;
using System.Threading.Tasks;
using OptiVoltCLI.Services;

namespace OptiVoltCLI.Commands
{
    public static class DeployCommand
    {
        public static Command Create(ConfigurationService configService, SshService sshService)
        {
            var deployCommand = new Command("deploy", "Déploie les environnements de test");
            
            var envOption = new Option<string>(
                "--environment",
                description: "Type d'environnement (docker, microvm, unikernel)",
                getDefaultValue: () => "docker"
            );
            
            deployCommand.AddOption(envOption);
            
            deployCommand.SetHandler(async (string env) =>
            {
                await ExecuteAsync(env, sshService);
            }, envOption);

            return deployCommand;
        }

        private static async Task ExecuteAsync(string environment, SshService sshService)
        {
            Console.WriteLine("========================================");
            Console.WriteLine($"🚀 Déploiement de l'environnement: {environment}");
            Console.WriteLine("========================================");

            var scriptName = $"deploy_{environment}.sh";
            var command = $"bash scripts/{scriptName}";

            var (success, output) = await sshService.ExecuteCommandAsync(environment, command, 600);

            if (success)
            {
                Console.WriteLine("✅ Déploiement réussi");
                Console.WriteLine(output);
            }
            else
            {
                Console.WriteLine("❌ Échec du déploiement");
                Console.WriteLine(output);
                Environment.Exit(1);
            }
        }
    }
}
