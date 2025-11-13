using System;
using System.IO;
using System.Threading.Tasks;
using Newtonsoft.Json;
using OptiVoltCLI.Models;

namespace OptiVoltCLI.Services
{
    public class MetricsService
    {
        private readonly SshService _sshService;

        public MetricsService(SshService sshService)
        {
            _sshService = sshService;
        }

        public async Task<TestResult> CollectMetricsAsync(string environment, string testType)
        {
            var result = new TestResult
            {
                Environment = environment,
                TestName = testType,
                Timestamp = DateTime.UtcNow
            };

            try
            {
                Console.WriteLine($"📊 Collecte des métriques pour {environment}/{testType}");

                var command = $"cat {testType}_results.json 2>/dev/null || echo '{{}}'";
                var (success, output) = await _sshService.ExecuteCommandAsync(environment, command);

                if (success && !string.IsNullOrWhiteSpace(output))
                {
                    try
                    {
                        var metrics = JsonConvert.DeserializeObject<Dictionary<string, object>>(output);
                        result.Metrics = metrics ?? new Dictionary<string, object>();
                        result.Status = "completed";
                    }
                    catch
                    {
                        result.Status = "completed";
                        result.Metrics["raw_output"] = output;
                    }
                }
                else
                {
                    result.Status = "no_data";
                    result.Error = "Aucune métrique disponible";
                }
            }
            catch (Exception ex)
            {
                result.Status = "error";
                result.Error = ex.Message;
            }

            return result;
        }

        public async Task<bool> SaveResultAsync(TestResult result, string outputPath)
        {
            try
            {
                var json = JsonConvert.SerializeObject(result, Formatting.Indented);
                await File.WriteAllTextAsync(outputPath, json);
                Console.WriteLine($"✅ Résultats sauvegardés: {outputPath}");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Erreur lors de la sauvegarde: {ex.Message}");
                return false;
            }
        }
    }
}
