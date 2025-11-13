using System;
using System.IO;
using Newtonsoft.Json;
using OptiVoltCLI.Models;

namespace OptiVoltCLI.Services
{
    public class ConfigurationService
    {
        private readonly string _configPath;

        public ConfigurationService(string? configPath = null)
        {
            _configPath = configPath ?? Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                "optivolt-automation", "config", "hosts.json"
            );
        }

        public HostConfig? GetEnvironmentConfig(string environment)
        {
            try
            {
                if (!File.Exists(_configPath))
                {
                    Console.WriteLine($"❌ Fichier de configuration introuvable: {_configPath}");
                    return null;
                }

                var json = File.ReadAllText(_configPath);
                var config = JsonConvert.DeserializeObject<EnvironmentsConfig>(json);

                if (config?.Environments == null)
                {
                    Console.WriteLine("❌ Format de configuration invalide");
                    return null;
                }

                if (!config.Environments.ContainsKey(environment))
                {
                    Console.WriteLine($"❌ Environnement '{environment}' introuvable dans la configuration");
                    Console.WriteLine($"Environnements disponibles: {string.Join(", ", config.Environments.Keys)}");
                    return null;
                }

                return config.Environments[environment];
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Erreur lors de la lecture de la configuration: {ex.Message}");
                return null;
            }
        }

        public bool IsLocalhost(string hostname)
        {
            return hostname == "localhost" || 
                   hostname == "127.0.0.1" || 
                   hostname == "::1";
        }
    }
}
