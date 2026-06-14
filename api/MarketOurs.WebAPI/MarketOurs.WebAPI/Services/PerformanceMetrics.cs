using Prometheus;

namespace MarketOurs.WebAPI.Services;

public static class PerformanceMetrics
{
    public static readonly Histogram EndpointDuration = Metrics.CreateHistogram(
        "marketours_endpoint_duration_seconds",
        "Duration of hot read endpoints.",
        new HistogramConfiguration
        {
            LabelNames = ["endpoint", "method", "status_code"],
            Buckets = Histogram.ExponentialBuckets(0.005, 2, 12)
        });

    public static readonly Histogram DbCommandDuration = Metrics.CreateHistogram(
        "marketours_db_command_duration_seconds",
        "Duration of EF Core database commands.",
        new HistogramConfiguration
        {
            LabelNames = ["command_type"],
            Buckets = Histogram.ExponentialBuckets(0.001, 2, 14)
        });
}
