using Xunit;
using OptiVoltCLI.Models;

namespace OptiVoltCLI.Tests.Models
{
    /// <summary>
    /// Tests unitaires pour le modèle TestResult
    /// </summary>
    public class TestResultTests
    {
        [Fact]
        public void TestResult_ShouldInitializeWithDefaultValues()
        {
            // Arrange & Act
            var result = new TestResult();

            // Assert
            Assert.Equal(string.Empty, result.TestName);
            Assert.Equal(string.Empty, result.Environment);
            Assert.Equal("pending", result.Status);  // Default status is "pending"
            Assert.Equal(0.0, result.DurationSeconds);
            Assert.NotNull(result.Metrics);
            Assert.Empty(result.Metrics);
            Assert.Null(result.Error);
        }

        [Theory]
        [InlineData("cpu", "docker", "completed", 30.5, null)]
        [InlineData("api", "unikernel", "failed", 15.2, "Connection refused")]
        [InlineData("db", "microvm", "completed", 60.0, null)]
        public void TestResult_ShouldStoreTestData(
            string testType,
            string environment,
            string status,
            double duration,
            string? error)
        {
            // Arrange
            var result = new TestResult
            {
                TestName = testType,
                Environment = environment,
                Status = status,
                DurationSeconds = duration,
                Error = error
            };

            // Act & Assert
            Assert.Equal(testType, result.TestName);
            Assert.Equal(environment, result.Environment);
            Assert.Equal(status, result.Status);
            Assert.Equal(duration, result.DurationSeconds);
            Assert.Equal(error, result.Error);
        }

        [Fact]
        public void TestResult_ShouldStoreMetrics()
        {
            // Arrange
            var result = new TestResult();
            var metrics = new Dictionary<string, object>
            {
                { "cpu_avg", 45.5 },
                { "memory_mb", 512 },
                { "requests_total", 1000 }
            };

            // Act
            result.Metrics = metrics;

            // Assert
            Assert.Equal(3, result.Metrics.Count);
            Assert.Equal(45.5, result.Metrics["cpu_avg"]);
            Assert.Equal(512, result.Metrics["memory_mb"]);
            Assert.Equal(1000, result.Metrics["requests_total"]);
        }

        [Fact]
        public void TestResult_ShouldIndicateSuccess()
        {
            // Arrange
            var successResult = new TestResult { Status = "completed", Error = null };
            var failureResult = new TestResult { Status = "failed", Error = "Test error" };

            // Act
            var isSuccess = successResult.Status == "completed" && successResult.Error == null;
            var isFailure = failureResult.Status == "failed" || failureResult.Error != null;

            // Assert
            Assert.True(isSuccess);
            Assert.True(isFailure);
        }
    }
}
