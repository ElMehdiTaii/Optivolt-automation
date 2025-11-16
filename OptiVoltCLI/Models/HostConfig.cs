using Newtonsoft.Json;

namespace OptiVoltCLI.Models
{
    public class HostConfig
    {
        [JsonProperty("hostname")]
        public string Hostname { get; set; } = string.Empty;

        [JsonProperty("ip")]
        public string Ip { get; set; } = string.Empty;

        [JsonProperty("port")]
        public int Port { get; set; } = 22;

        [JsonProperty("username")]
        public string Username { get; set; } = string.Empty;

        [JsonProperty("privateKeyPath")]
        public string PrivateKeyPath { get; set; } = "~/.ssh/id_rsa";

        [JsonProperty("workingDirectory")]
        public string WorkingDirectory { get; set; } = string.Empty;
    }

    public class EnvironmentsConfig
    {
        [JsonProperty("environments")]
        public Dictionary<string, HostConfig> Environments { get; set; } = new();
    }
}
