using System;

namespace OptiVoltCLI.Logging
{
    /// <summary>
    /// Log levels for the application
    /// </summary>
    public enum LogLevel
    {
        Debug,
        Info,
        Warning,
        Error,
        Critical
    }

    /// <summary>
    /// Simple logger implementation for OptiVolt
    /// </summary>
    public interface ILogger
    {
        void Log(LogLevel level, string message);
        void Debug(string message);
        void Info(string message);
        void Warning(string message);
        void Error(string message, Exception? exception = null);
        void Critical(string message, Exception? exception = null);
    }

    /// <summary>
    /// Console-based logger implementation
    /// </summary>
    public class ConsoleLogger : ILogger
    {
        private readonly LogLevel _minimumLevel;
        private readonly bool _includeTimestamp;

        public ConsoleLogger(LogLevel minimumLevel = LogLevel.Info, bool includeTimestamp = true)
        {
            _minimumLevel = minimumLevel;
            _includeTimestamp = includeTimestamp;
        }

        public void Log(LogLevel level, string message)
        {
            if (level < _minimumLevel)
                return;

            var timestamp = _includeTimestamp ? $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] " : "";
            var levelStr = $"[{level.ToString().ToUpper()}]";
            var color = GetColorForLevel(level);

            Console.ForegroundColor = color;
            Console.WriteLine($"{timestamp}{levelStr} {message}");
            Console.ResetColor();
        }

        public void Debug(string message) => Log(LogLevel.Debug, message);
        
        public void Info(string message) => Log(LogLevel.Info, message);
        
        public void Warning(string message) => Log(LogLevel.Warning, message);
        
        public void Error(string message, Exception? exception = null)
        {
            Log(LogLevel.Error, message);
            if (exception != null)
            {
                Log(LogLevel.Error, $"Exception: {exception.Message}");
                if (exception.StackTrace != null)
                {
                    Log(LogLevel.Debug, $"Stack trace: {exception.StackTrace}");
                }
            }
        }
        
        public void Critical(string message, Exception? exception = null)
        {
            Log(LogLevel.Critical, message);
            if (exception != null)
            {
                Log(LogLevel.Critical, $"Exception: {exception.Message}");
                if (exception.StackTrace != null)
                {
                    Log(LogLevel.Critical, $"Stack trace: {exception.StackTrace}");
                }
            }
        }

        private static ConsoleColor GetColorForLevel(LogLevel level)
        {
            return level switch
            {
                LogLevel.Debug => ConsoleColor.Gray,
                LogLevel.Info => ConsoleColor.White,
                LogLevel.Warning => ConsoleColor.Yellow,
                LogLevel.Error => ConsoleColor.Red,
                LogLevel.Critical => ConsoleColor.DarkRed,
                _ => ConsoleColor.White
            };
        }
    }
}
