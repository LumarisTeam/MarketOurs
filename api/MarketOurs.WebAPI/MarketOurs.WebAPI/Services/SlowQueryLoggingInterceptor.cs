using System.Data.Common;
using System.Diagnostics;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace MarketOurs.WebAPI.Services;

public sealed class SlowQueryLoggingInterceptor(ILogger<SlowQueryLoggingInterceptor> logger) : DbCommandInterceptor
{
    private static readonly TimeSpan SlowQueryThreshold = TimeSpan.FromMilliseconds(100);

    public override DbDataReader ReaderExecuted(
        DbCommand command,
        CommandExecutedEventData eventData,
        DbDataReader result)
    {
        RecordCommand(command, eventData.Duration, "reader", result.RecordsAffected >= 0 ? result.RecordsAffected : null);
        return result;
    }

    public override ValueTask<DbDataReader> ReaderExecutedAsync(
        DbCommand command,
        CommandExecutedEventData eventData,
        DbDataReader result,
        CancellationToken cancellationToken = default)
    {
        RecordCommand(command, eventData.Duration, "reader", result.RecordsAffected >= 0 ? result.RecordsAffected : null);
        return ValueTask.FromResult(result);
    }

    public override object? ScalarExecuted(
        DbCommand command,
        CommandExecutedEventData eventData,
        object? result)
    {
        RecordCommand(command, eventData.Duration, "scalar", result == null ? 0 : 1);
        return result;
    }

    public override ValueTask<object?> ScalarExecutedAsync(
        DbCommand command,
        CommandExecutedEventData eventData,
        object? result,
        CancellationToken cancellationToken = default)
    {
        RecordCommand(command, eventData.Duration, "scalar", result == null ? 0 : 1);
        return ValueTask.FromResult(result);
    }

    public override int NonQueryExecuted(
        DbCommand command,
        CommandExecutedEventData eventData,
        int result)
    {
        RecordCommand(command, eventData.Duration, "nonquery", result);
        return result;
    }

    public override ValueTask<int> NonQueryExecutedAsync(
        DbCommand command,
        CommandExecutedEventData eventData,
        int result,
        CancellationToken cancellationToken = default)
    {
        RecordCommand(command, eventData.Duration, "nonquery", result);
        return ValueTask.FromResult(result);
    }

    private void RecordCommand(DbCommand command, TimeSpan duration, string commandType, int? rowCount)
    {
        PerformanceMetrics.DbCommandDuration
            .WithLabels(commandType)
            .Observe(duration.TotalSeconds);

        if (duration < SlowQueryThreshold)
        {
            return;
        }

        logger.LogWarning(
            "Slow SQL detected ({DurationMs} ms, {CommandType}, rows={RowCount}): {CommandText}",
            duration.TotalMilliseconds,
            commandType,
            rowCount?.ToString() ?? "unknown",
            Summarize(command.CommandText));
    }

    private static string Summarize(string sql)
    {
        if (string.IsNullOrWhiteSpace(sql))
        {
            return string.Empty;
        }

        var singleLine = string.Join(" ", sql
            .Split(['\r', '\n', '\t'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));

        return singleLine.Length <= 240 ? singleLine : $"{singleLine[..240]}...";
    }
}
