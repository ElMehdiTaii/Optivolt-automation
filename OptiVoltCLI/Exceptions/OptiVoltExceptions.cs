using System;

namespace OptiVoltCLI.Exceptions
{
    /// <summary>
    /// Base exception for OptiVolt application
    /// </summary>
    public class OptiVoltException : Exception
    {
        public OptiVoltException() : base() { }
        
        public OptiVoltException(string message) : base(message) { }
        
        public OptiVoltException(string message, Exception innerException) 
            : base(message, innerException) { }
    }

    /// <summary>
    /// Exception thrown when configuration is invalid or missing
    /// </summary>
    public class ConfigurationException : OptiVoltException
    {
        public string? ConfigurationKey { get; }

        public ConfigurationException(string message) : base(message) { }
        
        public ConfigurationException(string message, string configurationKey) 
            : base(message)
        {
            ConfigurationKey = configurationKey;
        }
        
        public ConfigurationException(string message, Exception innerException) 
            : base(message, innerException) { }
    }

    /// <summary>
    /// Exception thrown when SSH operations fail
    /// </summary>
    public class SshConnectionException : OptiVoltException
    {
        public string? Host { get; }
        public int? Port { get; }

        public SshConnectionException(string message) : base(message) { }
        
        public SshConnectionException(string message, string host, int port) 
            : base(message)
        {
            Host = host;
            Port = port;
        }
        
        public SshConnectionException(string message, string host, int port, Exception innerException) 
            : base(message, innerException)
        {
            Host = host;
            Port = port;
        }
        
        public SshConnectionException(string message, Exception innerException) 
            : base(message, innerException) { }
    }

    /// <summary>
    /// Exception thrown when command execution fails
    /// </summary>
    public class CommandExecutionException : OptiVoltException
    {
        public string? Command { get; }
        public int? ExitCode { get; }

        public CommandExecutionException(string message) : base(message) { }
        
        public CommandExecutionException(string message, string command, int exitCode) 
            : base(message)
        {
            Command = command;
            ExitCode = exitCode;
        }
        
        public CommandExecutionException(string message, string command, int exitCode, Exception innerException) 
            : base(message, innerException)
        {
            Command = command;
            ExitCode = exitCode;
        }
        
        public CommandExecutionException(string message, Exception innerException) 
            : base(message, innerException) { }
    }

    /// <summary>
    /// Exception thrown when test execution fails
    /// </summary>
    public class TestExecutionException : OptiVoltException
    {
        public string? TestType { get; }
        public string? Environment { get; }

        public TestExecutionException(string message) : base(message) { }
        
        public TestExecutionException(string message, string testType, string environment) 
            : base(message)
        {
            TestType = testType;
            Environment = environment;
        }
        
        public TestExecutionException(string message, Exception innerException) 
            : base(message, innerException) { }
    }
}
