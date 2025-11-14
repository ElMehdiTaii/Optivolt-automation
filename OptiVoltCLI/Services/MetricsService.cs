using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Newtonsoft.Json;
using OptiVoltCLI.Models;
using OptiVoltCLI.Exceptions;
using OptiVoltCLI.Logging;

namespace OptiVoltCLI.Services
{
    /// <summary>
    /// Service for collecting and managing test metrics
    /// </summary>
    public class MetricsService
    {
        private readonly SshService _sshService;
        private readonly ILogger _logger;

        /// <summary>
        /// Initializes a new instance of MetricsService
        /// </summary>
        /// <param name="sshService">SSH service instance</param>
        /// <param name="logger">Logger instance. If null, creates a default console logger.</param>
        public MetricsService(SshService sshService, ILogger? logger = null)
        {
            _sshService = sshService ?? throw new ArgumentNullException(nameof(sshService));
            _logger = logger ?? new ConsoleLogger(LogLevel.Info, includeTimestamp: false);
        }

        /// <summary>
        /// Collects metrics for a specific test from an environment
        /// </summary>
        /// <param name="environment">Environment name</param>
        /// <param name="testType">Type of test (cpu, api, db)</param>
        /// <returns>TestResult with collected metrics</returns>
        public async Task<TestResult> CollectMetricsAsync(string environment, string testType)
        {
            if (string.IsNullOrWhiteSpace(environment))
                throw new ArgumentException("Environment name cannot be null or empty", nameof(environment));
            
            if (string.IsNullOrWhiteSpace(testType))
                throw new ArgumentException("Test type cannot be null or empty", nameof(testType));

            var result = new TestResult
            {
                Environment = environment,
                TestName = testType,
                Timestamp = DateTime.UtcNow
            };

            try
            {
                _logger.Info($"Collecting metrics for {environment}/{testType}");

                var command = $"cat {testType}_results.json 2>/dev/null || echo '{{}}'";
                var (success, output) = await _sshService.ExecuteCommandAsync(environment, command);

                if (success && !string.IsNullOrWhiteSpace(output))
                {
                    try
                    {
                        var metrics = JsonConvert.DeserializeObject<Dictionary<string, object>>(output);
                        result.Metrics = metrics ?? new Dictionary<string, object>();
                        result.Status = "completed";
                        _logger.Info($"Successfully collected {result.Metrics.Count} metrics");
                    }
                    catch (JsonException ex)
                    {
                        _logger.Warning($"Failed to parse JSON metrics, storing raw output: {ex.Message}");
                        result.Status = "completed";
                        result.Metrics["raw_output"] = output;
                    }
                }
                else
                {
                    result.Status = "no_data";
                    result.Error = "No metrics available";
                    _logger.Warning($"No metrics data found for {environment}/{testType}");
                }
            }
            catch (Exception ex)
            {
                result.Status = "error";
                result.Error = ex.Message;
                _logger.Error($"Failed to collect metrics for {environment}/{testType}", ex);
            }

            return result;
        }

        /// <summary>
        /// Saves test result to a JSON file
        /// </summary>
        /// <param name="result">Test result to save</param>
        /// <param name="outputPath">Output file path</param>
        /// <returns>True if successful, false otherwise</returns>
        public async Task<bool> SaveResultAsync(TestResult result, string outputPath)
        {
            if (result == null)
                throw new ArgumentNullException(nameof(result));
            
            if (string.IsNullOrWhiteSpace(outputPath))
                throw new ArgumentException("Output path cannot be null or empty", nameof(outputPath));

            try
            {
                // Ensure directory exists
                var directory = Path.GetDirectoryName(outputPath);
                if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                    _logger.Debug($"Created directory: {directory}");
                }

                var json = JsonConvert.SerializeObject(result, Formatting.Indented);
                await File.WriteAllTextAsync(outputPath, json);
                _logger.Info($"Results saved to {outputPath}");
                return true;
            }
            catch (IOException ex)
            {
                _logger.Error($"Failed to save results to {outputPath}", ex);
                return false;
            }
            catch (Exception ex)
            {
                _logger.Error($"Unexpected error saving results to {outputPath}", ex);
                return false;
            }
        }
    }
}
