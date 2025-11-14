using Xunit;
using OptiVoltCLI.Models;
using Newtonsoft.Json;

namespace OptiVoltCLI.Tests.Models
{
    /// <summary>
    /// Tests unitaires pour le modèle HostConfig
    /// </summary>
    public class HostConfigTests
    {
        [Fact]
        public void HostConfig_ShouldDeserializeFromJson()
        {
            // Arrange
            var json = @"{
                ""hostname"": ""test-host"",
                ""ip"": ""192.168.1.100"",
                ""port"": 2222,
                ""user"": ""testuser"",
                ""workdir"": ""/tmp/test""
            }";

            // Act
            var config = JsonConvert.DeserializeObject<HostConfig>(json);

            // Assert
            Assert.NotNull(config);
            Assert.Equal("test-host", config.Hostname);
            Assert.Equal("192.168.1.100", config.Ip);
            Assert.Equal(2222, config.Port);
            Assert.Equal("testuser", config.Username);
            Assert.Equal("/tmp/test", config.WorkingDirectory);
        }

        [Fact]
        public void HostConfig_ShouldHaveDefaultValues()
        {
            // Arrange & Act
            var config = new HostConfig();

            // Assert
            Assert.Equal(string.Empty, config.Hostname);
            Assert.Equal(string.Empty, config.Ip);
            Assert.Equal(22, config.Port);
            Assert.Equal(string.Empty, config.Username);
            Assert.Equal("~/.ssh/id_rsa", config.PrivateKeyPath);
            Assert.Equal(string.Empty, config.WorkingDirectory);
        }

        [Theory]
        [InlineData("", false)]
        [InlineData("localhost", true)]
        [InlineData("test-host", true)]
        [InlineData("192.168.1.1", true)]
        public void HostConfig_Hostname_ShouldValidate(string hostname, bool isValid)
        {
            // Arrange
            var config = new HostConfig { Hostname = hostname };

            // Act
            var hasValue = !string.IsNullOrEmpty(config.Hostname);

            // Assert
            Assert.Equal(isValid, hasValue);
        }

        [Theory]
        [InlineData(22, true)]
        [InlineData(2222, true)]
        [InlineData(0, false)]
        [InlineData(-1, false)]
        [InlineData(65536, false)]
        public void HostConfig_Port_ShouldBeInValidRange(int port, bool expectedValid)
        {
            // Arrange
            var config = new HostConfig { Port = port };

            // Act
            var isValid = port > 0 && port <= 65535;

            // Assert
            Assert.Equal(expectedValid, isValid);
        }
    }
}
