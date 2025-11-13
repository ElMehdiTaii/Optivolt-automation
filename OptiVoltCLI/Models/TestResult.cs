using Newtonsoft.Json;

namespace OptiVoltCLI.Models
{
    public class TestResult
    {
        [JsonProperty("test")]
        public string TestName { get; set; } = string.Empty;

        [JsonProperty("environment")]
        public string Environment { get; set; } = string.Empty;

        [JsonProperty("status")]
        public string Status { get; set; } = "pending";

        [JsonProperty("duration_seconds")]
        public double DurationSeconds { get; set; }

        [JsonProperty("timestamp")]
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        [JsonProperty("metrics")]
        public Dictionary<string, object> Metrics { get; set; } = new();

        [JsonProperty("error")]
        public string? Error { get; set; }
    }
}
