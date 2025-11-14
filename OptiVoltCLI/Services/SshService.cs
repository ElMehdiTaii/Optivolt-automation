using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using Renci.SshNet;
using OptiVoltCLI.Models;
using OptiVoltCLI.Exceptions;
using OptiVoltCLI.Logging;

namespace OptiVoltCLI.Services
{
    /// <summary>
    /// Service for executing commands locally or remotely via SSH
    /// </summary>
    public class SshService
    {
        private readonly ConfigurationService _configService;
        private readonly ILogger _logger;

        /// <summary>
        /// Initializes a new instance of SshService
        /// </summary>
        /// <param name="configService">Configuration service instance</param>
        /// <param name="logger">Logger instance. If null, creates a default console logger.</param>
        public SshService(ConfigurationService configService, ILogger? logger = null)
        {
            _configService = configService ?? throw new ArgumentNullException(nameof(configService));
            _logger = logger ?? new ConsoleLogger(LogLevel.Info, includeTimestamp: false);
        }

        /// <summary>
        /// Executes a command on specified environment (local or remote)
        /// </summary>
        /// <param name="environment">Environment name</param>
        /// <param name="command">Command to execute</param>
        /// <param name="timeoutSeconds">Command timeout in seconds</param>
        /// <returns>Tuple with success status and command output</returns>
        /// <exception cref="ConfigurationException">Thrown when configuration is invalid</exception>
        /// <exception cref="SshConnectionException">Thrown when SSH connection fails</exception>
        /// <exception cref="CommandExecutionException">Thrown when command execution fails</exception>
        public async Task<(bool Success, string Output)> ExecuteCommandAsync(
            string environment, 
            string command, 
            int timeoutSeconds = 300)
        {
            if (string.IsNullOrWhiteSpace(environment))
                throw new ArgumentException("Environment name cannot be null or empty", nameof(environment));
            
            if (string.IsNullOrWhiteSpace(command))
                throw new ArgumentException("Command cannot be null or empty", nameof(command));

            var hostConfig = _configService.GetEnvironmentConfig(environment);
            if (hostConfig == null)
            {
                throw new ConfigurationException($"Configuration not found for environment: {environment}");
            }

            // Validate configuration
            if (!_configService.ValidateHostConfig(hostConfig))
            {
                throw new ConfigurationException($"Invalid configuration for environment: {environment}");
            }

            // Exécution locale si localhost
            if (_configService.IsLocalhost(hostConfig.Hostname))
            {
                _logger.Info($"Executing locally on {environment}");
                return await ExecuteLocalCommandAsync(command, hostConfig.WorkingDirectory, timeoutSeconds);
            }

            // Exécution distante via SSH
            _logger.Info($"Executing remotely on {environment} ({hostConfig.Hostname})");
            return await ExecuteRemoteCommandAsync(hostConfig, command, timeoutSeconds);
        }

        /// <summary>
        /// Executes a command locally using bash
        /// </summary>
        private async Task<(bool Success, string Output)> ExecuteLocalCommandAsync(
            string command, 
            string workingDirectory, 
            int timeoutSeconds)
        {
            try
            {
                _logger.Debug($"Local command: {command}");
                _logger.Debug($"Working directory: {workingDirectory}");

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
                    _logger.Warning($"Command timed out after {timeoutSeconds}s: {command}");
                    throw new CommandExecutionException(
                        $"Command execution timeout after {timeoutSeconds} seconds", 
                        command, 
                        -1
                    );
                }

                var output = await outputTask;
                var error = await errorTask;

                var fullOutput = string.IsNullOrEmpty(error) ? output : $"{output}\n{error}";
                
                if (process.ExitCode != 0)
                {
                    _logger.Warning($"Command failed with exit code {process.ExitCode}");
                    _logger.Debug($"Error output: {error}");
                }

                return (process.ExitCode == 0, fullOutput);
            }
            catch (CommandExecutionException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.Error($"Local command execution failed: {command}", ex);
                throw new CommandExecutionException(
                    $"Failed to execute local command: {ex.Message}", 
                    command, 
                    -1, 
                    ex
                );
            }
        }

        /// <summary>
        /// Executes a command remotely via SSH
        /// </summary>
        private async Task<(bool Success, string Output)> ExecuteRemoteCommandAsync(
            HostConfig hostConfig, 
            string command, 
            int timeoutSeconds)
        {
            SshClient? sshClient = null;
            
            try
            {
                _logger.Info($"Connecting via SSH to {hostConfig.Username}@{hostConfig.Hostname}:{hostConfig.Port}");

                var privateKeyPath = hostConfig.PrivateKeyPath.Replace("~", 
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile));

                if (!File.Exists(privateKeyPath))
                {
                    _logger.Error($"Private key not found: {privateKeyPath}");
                    throw new SshConnectionException(
                        $"Private key not found: {privateKeyPath}", 
                        hostConfig.Hostname, 
                        hostConfig.Port
                    );
                }

                _logger.Debug($"Using private key: {privateKeyPath}");

                var privateKey = new PrivateKeyFile(privateKeyPath);
                var connectionInfo = new ConnectionInfo(
                    hostConfig.Ip,
                    hostConfig.Port,
                    hostConfig.Username,
                    new PrivateKeyAuthenticationMethod(hostConfig.Username, privateKey)
                );

                sshClient = new SshClient(connectionInfo);
                
                await Task.Run(() => sshClient.Connect());
                _logger.Info("SSH connection established");

                var fullCommand = $"cd {hostConfig.WorkingDirectory} && {command}";
                _logger.Debug($"Remote command: {fullCommand}");

                using var sshCommand = sshClient.CreateCommand(fullCommand);
                
                sshCommand.CommandTimeout = TimeSpan.FromSeconds(timeoutSeconds);
                var result = await Task.Run(() => sshCommand.Execute());

                sshClient.Disconnect();

                var output = sshCommand.ExitStatus == 0 ? 
                    result : 
                    $"{result}\n{sshCommand.Error}";

                if (sshCommand.ExitStatus != 0)
                {
                    _logger.Warning($"Remote command failed with exit code {sshCommand.ExitStatus}");
                    _logger.Debug($"Error output: {sshCommand.Error}");
                }

                return (sshCommand.ExitStatus == 0, output);
            }
            catch (Renci.SshNet.Common.SshConnectionException ex)
            {
                _logger.Error($"SSH connection failed to {hostConfig.Hostname}:{hostConfig.Port}", ex);
                throw new SshConnectionException(
                    $"Failed to connect to SSH server: {ex.Message}", 
                    hostConfig.Hostname, 
                    hostConfig.Port, 
                    ex
                );
            }
            catch (Renci.SshNet.Common.SshAuthenticationException ex)
            {
                _logger.Error($"SSH authentication failed for {hostConfig.Username}@{hostConfig.Hostname}", ex);
                throw new SshConnectionException(
                    $"SSH authentication failed: {ex.Message}", 
                    hostConfig.Hostname, 
                    hostConfig.Port, 
                    ex
                );
            }
            catch (SshConnectionException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.Error($"Remote command execution failed: {command}", ex);
                throw new CommandExecutionException(
                    $"Failed to execute remote command: {ex.Message}", 
                    command, 
                    -1, 
                    ex
                );
            }
            finally
            {
                if (sshClient != null && sshClient.IsConnected)
                {
                    sshClient.Disconnect();
                    _logger.Debug("SSH connection closed");
                }
            }
        }
    }
}
