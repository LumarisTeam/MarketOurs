using System.Diagnostics;
using MarketOurs.WebAPI.Services;

namespace MarketOurs.WebAPI.Middlewares;

public sealed class RequestMetricsMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var endpointLabel = NormalizeEndpoint(context.Request);
        if (endpointLabel == null)
        {
            await next(context);
            return;
        }

        var start = Stopwatch.GetTimestamp();
        try
        {
            await next(context);
        }
        finally
        {
            var elapsed = Stopwatch.GetElapsedTime(start);
            PerformanceMetrics.EndpointDuration
                .WithLabels(endpointLabel, context.Request.Method, context.Response.StatusCode.ToString())
                .Observe(elapsed.TotalSeconds);
        }
    }

    private static string? NormalizeEndpoint(HttpRequest request)
    {
        if (!HttpMethods.IsGet(request.Method))
        {
            return null;
        }

        var segments = request.Path.Value?
            .Split('/', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        if (segments == null || segments.Length == 0)
        {
            return null;
        }

        if (segments.Length == 1 && segments[0].Equals("Post", StringComparison.OrdinalIgnoreCase))
        {
            return "GET /Post";
        }

        if (segments.Length == 2 && segments[0].Equals("Post", StringComparison.OrdinalIgnoreCase))
        {
            return "GET /Post/{id}";
        }

        if (segments.Length >= 3
            && segments[0].Equals("Post", StringComparison.OrdinalIgnoreCase)
            && segments[2].Equals("comments", StringComparison.OrdinalIgnoreCase))
        {
            return "GET /Post/{id}/comments";
        }

        if (segments.Length == 3
            && segments[0].Equals("User", StringComparison.OrdinalIgnoreCase)
            && segments[1].Equals("public", StringComparison.OrdinalIgnoreCase))
        {
            return "GET /User/public/{id}";
        }

        return null;
    }
}
