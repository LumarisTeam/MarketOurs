using System.Security.Claims;
using MarketOurs.DataAPI.Exceptions;
using Microsoft.AspNetCore.Mvc;

namespace MarketOurs.WebAPI.Controllers;

public static class ControllerExceptionExtensions
{
    public static string GetRequiredUserId(this ControllerBase controller)
    {
        var userId = controller.User.FindFirstValue(ClaimTypes.NameIdentifier);
        return string.IsNullOrWhiteSpace(userId) ? throw new AuthException(ErrorCode.Unauthorized, "未授权") : userId;
    }

    public static string? GetOptionalUserId(this ControllerBase controller)
    {
        return controller.User.FindFirstValue(ClaimTypes.NameIdentifier);
    }
}