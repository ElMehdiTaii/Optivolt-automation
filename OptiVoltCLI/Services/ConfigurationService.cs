using System;
using System.IO;
using Newtonsoft.Json;
using OptiVoltCLI.Models;
using OptiVoltCLI.Exceptions;
using OptiVoltCLI.Logging;

namespace OptiVoltCLI.Services
{
    /// <summary>
    /// Service for managing application configuration
    /// </summary>
    public class ConfigurationService
    {
        private readonly string _configPath;
        private readonly ILogger _logger;

        /// <summary>
        /// Initializes a new instance of ConfigurationService
        /// </summary>
        /// <param name="configPath">Path to configuration file. If null, uses default path.</param>
        /// <param name="logger">Logger instance. If null, creates a default console logger.</param>
        public ConfigurationService(string? configPath = null, ILogger? logger = null)
        {
            if (configPath == null)
            {
                // Try multiple possible paths
                var possiblePaths = new[]
                {
                    Path.Combine(Directory.GetCurrentDirectory(), "config", "hosts.json"),
                    Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "config", "hosts.json"),
                    Path.Combine("/workspaces", "Optivolt-automation", "config", "hosts.json"),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "optivolt-automation", "config", "hosts.json")
                };

                foreach (var path in possiblePaths)
                {
                    var normalizedPath = Path.GetFullPath(path);
                    if (File.Exists(normalizedPath))
                    {
                        _configPath = normalizedPath;
                        break;
                    }
                }

                _configPath ??= possiblePaths[0]; // Fallback to first path
            }
            else
            {
                _configPath = configPath;
            }
            
            _logger = logger ?? new ConsoleLogger(LogLevel.Info, includeTimestamp: false);
        }

        /// <summary>
        /// Retrieves configuration for a specific environment
        /// </summary>
        /// <param name="environment">Environment name (docker, unikernel, microvm)</param>
        /// <returns>HostConfig if found, null otherwise</returns>
        /// <exception cref="ConfigurationException">Thrown when configuration is invalid</exception>
        public HostConfig? GetEnvironmentConfig(string environment)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(environment))
                {
                    throw new ArgumentException("Environment name cannot be null or empty", nameof(environment));
                }

                if (!File.Exists(_configPath))
                {
                    _logger.Error($"Configuration file not found: {_configPath}");
                    throw new ConfigurationException($"Configuration file not found: {_configPath}", "configPath");
                }

                _logger.Debug($"Reading configuration from {_configPath}");
                var json = File.ReadAllText(_configPath);
                
                var config = JsonConvert.DeserializeObject<EnvironmentsConfig>(json);

                if (config?.Environments == null || config.Environments.Count == 0)
                {
                    throw new ConfigurationException("Invalid configuration format or empty environments");
                }

                if (!config.Environments.ContainsKey(environment))
                {
                    var available = string.Join(", ", config.Environments.Keys);
                    _logger.Warning($"Environment '{environment}' not found. Available: {available}");
                    return null;
                }

                _logger.Debug($"Configuration loaded for environment: {environment}");
                return config.Environments[environment];
            }
            catch (JsonException ex)
            {
                _logger.Error("Failed to parse configuration file", ex);
                throw new ConfigurationException("Invalid JSON format in configuration file", ex);
            }
            catch (IOException ex)
            {
                _logger.Error("Failed to read configuration file", ex);
                throw new ConfigurationException($"Failed to read configuration file: {_configPath}", ex);
            }
        }

        /// <summary>
        /// Checks if hostname represents a local machine
        /// </summary>
        /// <param name="hostname">Hostname to check</param>
        /// <returns>True if hostname is local, false otherwise</returns>
        public bool IsLocalhost(string hostname)
        {
            if (string.IsNullOrWhiteSpace(hostname))
                return false;

            return hostname.Equals("localhost", StringComparison.OrdinalIgnoreCase) || 
                   hostname == "127.0.0.1" || 
                   hostname == "::1";
        }

        /// <summary>
        /// Validates host configuration
        /// </summary>
        /// <param name="config">Configuration to validate</param>
        /// <returns>True if valid, false otherwise</returns>
        public bool ValidateHostConfig(HostConfig config)
        {
            if (config == null)
                return false;

            if (string.IsNullOrWhiteSpace(config.Hostname))
            {
                _logger.Warning("Hostname is missing or empty");
                return false;
            }

            if (config.Port <= 0 || config.Port > 65535)
            {
                _logger.Warning($"Invalid port number: {config.Port}");
                return false;
            }

            if (string.IsNullOrWhiteSpace(config.Username))
            {
                _logger.Warning("Username is missing or empty");
                return false;
            }

            return true;
        }
    }
}
