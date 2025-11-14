using Xunit;
using Moq;
using System.IO;
using OptiVoltCLI.Services;
using OptiVoltCLI.Models;

namespace OptiVoltCLI.Tests.Services
{
    /// <summary>
    /// Tests unitaires pour ConfigurationService
    /// </summary>
    public class ConfigurationServiceTests
    {
        [Fact]
        public void IsLocalhost_ShouldIdentifyLocalAddresses()
        {
            // Arrange
            var service = new ConfigurationService();

            // Act & Assert
            Assert.True(service.IsLocalhost("localhost"));
            Assert.True(service.IsLocalhost("127.0.0.1"));
            Assert.True(service.IsLocalhost("::1"));
            Assert.False(service.IsLocalhost("192.168.1.100"));
            Assert.False(service.IsLocalhost("example.com"));
        }

        [Fact]
        public void GetEnvironmentConfig_ShouldThrowForInvalidPath()
        {
            // Arrange
            var invalidPath = "/tmp/nonexistent_config_" + Guid.NewGuid() + ".json";
            var service = new ConfigurationService(invalidPath);

            // Act & Assert
            Assert.Throws<OptiVoltCLI.Exceptions.ConfigurationException>(() =>
                service.GetEnvironmentConfig("docker"));
        }

        [Fact]
        public void GetEnvironmentConfig_ShouldReturnNullForMissingEnvironment()
        {
            // Arrange
            var tempFile = Path.GetTempFileName();
            File.WriteAllText(tempFile, @"{
                ""hosts"": {
                    ""docker"": {
                        ""hostname"": ""localhost"",
                        ""ip"": ""127.0.0.1"",
                        ""port"": 22,
                        ""user"": ""root"",
                        ""workdir"": ""/tmp""
                    }
                }
            }");

            var service = new ConfigurationService(tempFile);

            // Act
            var config = service.GetEnvironmentConfig("nonexistent");

            // Assert
            Assert.Null(config);

            // Cleanup
            File.Delete(tempFile);
        }

        [Fact]
        public void GetEnvironmentConfig_ShouldParseValidConfiguration()
        {
            // Arrange
            var tempFile = Path.GetTempFileName();
            File.WriteAllText(tempFile, @"{
                ""hosts"": {
                    ""docker"": {
                        ""hostname"": ""test-docker"",
                        ""ip"": ""192.168.1.100"",
                        ""port"": 2222,
                        ""user"": ""testuser"",
                        ""workdir"": ""/opt/tests""
                    }
                }
            }");

            var service = new ConfigurationService(tempFile);

            // Act
            var config = service.GetEnvironmentConfig("docker");

            // Assert
            Assert.NotNull(config);
            Assert.Equal("test-docker", config.Hostname);
            Assert.Equal("192.168.1.100", config.Ip);
            Assert.Equal(2222, config.Port);
            Assert.Equal("testuser", config.Username);
            Assert.Equal("/opt/tests", config.WorkingDirectory);

            // Cleanup
            File.Delete(tempFile);
        }

        [Fact]
        public void GetEnvironmentConfig_ShouldThrowForMalformedJson()
        {
            // Arrange
            var tempFile = Path.GetTempFileName();
            File.WriteAllText(tempFile, "{ invalid json }");

            var service = new ConfigurationService(tempFile);

            // Act & Assert
            Assert.Throws<OptiVoltCLI.Exceptions.ConfigurationException>(() =>
                service.GetEnvironmentConfig("docker"));

            // Cleanup
            File.Delete(tempFile);
        }
    }
}
