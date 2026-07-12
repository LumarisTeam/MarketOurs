using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarketOurs.WebAPI.Controllers;

[ApiController, Route("[controller]")]
public class ReportController(IReportService reportService) : ControllerBase
{
    [HttpPost, Authorize]
    public async Task<ApiResponse<ReportDto>> Create([FromBody] CreateReportRequest request) =>
        ApiResponse<ReportDto>.Success(await reportService.CreateAsync(this.GetRequiredUserId(), request), "举报已提交");

    [HttpGet, Authorize(Roles = "Admin")]
    public async Task<ApiResponse<PagedResultDto<ReportDto>>> GetAll([FromQuery] ReportStatus? status, [FromQuery] ReportTargetType? targetType, [FromQuery] PaginationParams pagination) =>
        ApiResponse<PagedResultDto<ReportDto>>.Success(await reportService.GetAllAsync(status, targetType, pagination));

    [HttpPut("{id}/status"), Authorize(Roles = "Admin")]
    public async Task<ApiResponse<ReportDto>> UpdateStatus(string id, [FromBody] UpdateReportStatusRequest request) =>
        ApiResponse<ReportDto>.Success(await reportService.UpdateStatusAsync(id, this.GetRequiredUserId(), request), "举报状态已更新");
}
