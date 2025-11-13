using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using Renci.SshNet;
using OptiVoltCLI.Models;

namespace OptiVoltCLI.Services
{
    public class SshService
    {
        private readonly ConfigurationService _configService;

        public SshService(ConfigurationService configService)
        {
            _configService = configService;
        }

        public async Task<(bool Success, string Output)> ExecuteCommandAsync(
            string environment, 
            string command, 
            int timeoutSeconds = 300)
        {
            var hostConfig = _configService.GetEnvironmentConfig(environment);
            if (hostConfig == null)
            {
                return (false, "Configuration introuvable");
            }

            // Exécution locale si localhost
            if (_configService.IsLocalhost(hostConfig.Hostname))
            {
                return await ExecuteLocalCommandAsync(command, hostConfig.WorkingDirectory, timeoutSeconds);
            }

            // Exécution distante via SSH
            return await ExecuteRemoteCommandAsync(hostConfig, command, timeoutSeconds);
        }

        private async Task<(bool Success, string Output)> ExecuteLocalCommandAsync(
            string command, 
            string workingDirectory, 
            int timeoutSeconds)
        {
            try
            {
                Console.WriteLine($"🔧 Exécution locale: {command}");

                var processInfo = new ProcessStartInfo
                {
                    FileName = "/bin/bash",
                    Arguments = $"-c \"{command}\"",
                    WorkingDirectory = workingDirectory,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using var process = new Process { StartInfo = processInfo };
                process.Start();

                var outputTask = process.StandardOutput.ReadToEndAsync();
                var errorTask = process.StandardError.ReadToEndAsync();

                var completed = await Task.Run(() => 
                    process.WaitForExit(timeoutSeconds * 1000)
                );

                if (!completed)
                {
                    process.Kill();
                    return (false, "Timeout lors de l'exécution");
                }

                var output = await outputTask;
                var error = await errorTask;

                var fullOutput = string.IsNullOrEmpty(error) ? output : $"{output}\n{error}";
                return (process.ExitCode == 0, fullOutput);
            }
            catch (Exception ex)
            {
                return (false, $"Erreur: {ex.Message}");
            }
        }

        private async Task<(bool Success, string Output)> ExecuteRemoteCommandAsync(
            HostConfig hostConfig, 
            string command, 
            int timeoutSeconds)
        {
            try
            {
                Console.WriteLine($"🌐 Connexion SSH à {hostConfig.Username}@{hostConfig.Hostname}:{hostConfig.Port}");

                var privateKeyPath = hostConfig.PrivateKeyPath.Replace("~", 
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile));

                if (!File.Exists(privateKeyPath))
                {
                    return (false, $"Clé privée introuvable: {privateKeyPath}");
                }

                var privateKey = new PrivateKeyFile(privateKeyPath);
                var connectionInfo = new ConnectionInfo(
                    hostConfig.Hostname,
                    hostConfig.Port,
                    hostConfig.Username,
                    new PrivateKeyAuthenticationMethod(hostConfig.Username, privateKey)
                );

                using var sshClient = new SshClient(connectionInfo);
                
                await Task.Run(() => sshClient.Connect());
                Console.WriteLine("✅ Connexion SSH établie");

                var fullCommand = $"cd {hostConfig.WorkingDirectory} && {command}";
                using var sshCommand = sshClient.CreateCommand(fullCommand);
                
                sshCommand.CommandTimeout = TimeSpan.FromSeconds(timeoutSeconds);
                var result = await Task.Run(() => sshCommand.Execute());

                sshClient.Disconnect();

                var output = sshCommand.ExitStatus == 0 ? 
                    result : 
                    $"{result}\n{sshCommand.Error}";

                return (sshCommand.ExitStatus == 0, output);
            }
            catch (Exception ex)
            {
                return (false, $"Erreur SSH: {ex.Message}");
            }
        }
    }
}
