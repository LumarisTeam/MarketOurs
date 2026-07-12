using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Exceptions;
using MarketOurs.DataAPI.Repos;
using MarketOurs.DataAPI.Services.Background;

namespace MarketOurs.DataAPI.Services;

public interface IReportService
{
    Task<ReportDto> CreateAsync(string reporterUserId, CreateReportRequest request);
    Task<PagedResultDto<ReportDto>> GetAllAsync(ReportStatus? status, ReportTargetType? targetType, PaginationParams pagination);
    Task<ReportDto> UpdateStatusAsync(string id, string reviewerUserId, UpdateReportStatusRequest request);
}

public class ReportService(
    IReportRepo reportRepo, IUserRepo userRepo, IPostRepo postRepo, ICommentRepo commentRepo,
    NotificationMessageQueue notificationQueue) : IReportService
{
    public async Task<ReportDto> CreateAsync(string reporterUserId, CreateReportRequest request)
    {
        if (request.Reason == ReportReason.Other && string.IsNullOrWhiteSpace(request.Description))
            throw new BusinessException(ErrorCode.ParameterValidationFailed, "选择其他理由时请填写说明");
        if (await reportRepo.ExistsAsync(reporterUserId, request.TargetType, request.TargetId))
            throw new BusinessException(ErrorCode.ReportAlreadySubmitted, "您已举报过该内容", 409, null);

        var reporter = await userRepo.GetByIdAsync(reporterUserId)
            ?? throw new ResourceAccessException(ErrorCode.UserNotFound, "用户不存在");
        var (ownerId, summary) = await GetTargetAsync(request.TargetType, request.TargetId);
        if (ownerId == reporterUserId)
            throw new BusinessException(ErrorCode.ReportTargetNotAllowed, "不能举报自己的内容或账号");

        var report = new ReportModel {
            TargetType = request.TargetType, TargetId = request.TargetId, ReporterUserId = reporterUserId,
            ReporterName = reporter.Name, TargetSummary = summary, Reason = request.Reason,
            Description = request.Description?.Trim(), CreatedAt = DateTime.UtcNow
        };
        await reportRepo.CreateAsync(report);
        return ToDto(report);
    }

    public async Task<PagedResultDto<ReportDto>> GetAllAsync(ReportStatus? status, ReportTargetType? targetType, PaginationParams pagination)
    {
        var countTask = reportRepo.CountAsync(status, targetType);
        var reportsTask = reportRepo.GetAllAsync(status, targetType, pagination.PageIndex, pagination.PageSize);
        await Task.WhenAll(countTask, reportsTask);
        return PagedResultDto<ReportDto>.Success(reportsTask.Result.Select(ToDto).ToList(), countTask.Result, pagination.PageIndex, pagination.PageSize);
    }

    public async Task<ReportDto> UpdateStatusAsync(string id, string reviewerUserId, UpdateReportStatusRequest request)
    {
        if (request.Status is not (ReportStatus.Resolved or ReportStatus.Rejected))
            throw new BusinessException(ErrorCode.InvalidStatusForOperation, "举报只能处理为已处理或已驳回");
        var report = await reportRepo.GetByIdAsync(id)
            ?? throw new ResourceAccessException(ErrorCode.ReportNotFound, "举报不存在");
        if (report.Status != ReportStatus.Pending)
            throw new BusinessException(ErrorCode.InvalidStatusForOperation, "举报已处理");
        report.Status = request.Status; report.ReviewedByUserId = reviewerUserId;
        report.ReviewedAt = DateTime.UtcNow; report.ResolutionNote = request.ResolutionNote?.Trim();
        await reportRepo.UpdateAsync(report);
        notificationQueue.Enqueue(new NotificationMessage {
            UserId = report.ReporterUserId, Type = NotificationType.System, TargetId = report.TargetId,
            Title = "举报处理结果", Content = request.Status == ReportStatus.Resolved ? "您提交的举报已处理。" : "您提交的举报已驳回。"
        });
        return ToDto(report);
    }

    private async Task<(string OwnerId, string Summary)> GetTargetAsync(ReportTargetType type, string id) => type switch
    {
        ReportTargetType.Post => await GetPostAsync(id),
        ReportTargetType.Comment => await GetCommentAsync(id),
        ReportTargetType.User => await GetUserAsync(id),
        _ => throw new BusinessException(ErrorCode.ReportTargetNotAllowed, "不支持的举报目标")
    };
    private async Task<(string, string)> GetPostAsync(string id) { var post = await postRepo.GetReviewedByIdAsync(id) ?? throw new ResourceAccessException(ErrorCode.PostNotFound, "帖子不存在"); return (post.UserId, post.Title); }
    private async Task<(string, string)> GetCommentAsync(string id) { var comment = await commentRepo.GetReviewedByIdAsync(id) ?? throw new ResourceAccessException(ErrorCode.CommentNotFound, "评论不存在"); return (comment.UserId, comment.Content.Length > 120 ? comment.Content[..120] : comment.Content); }
    private async Task<(string, string)> GetUserAsync(string id) { var user = await userRepo.GetByIdAsync(id) ?? throw new ResourceAccessException(ErrorCode.UserNotFound, "用户不存在"); if (!user.IsActive) throw new BusinessException(ErrorCode.ReportTargetNotAllowed, "该账号不可举报"); return (user.Id, user.Name); }
    private static ReportDto ToDto(ReportModel x) => new() { Id = x.Id, TargetType = x.TargetType, TargetId = x.TargetId, TargetSummary = x.TargetSummary, ReporterUserId = x.ReporterUserId, ReporterName = x.ReporterName, Reason = x.Reason, Description = x.Description, Status = x.Status, ReviewedByUserId = x.ReviewedByUserId, ResolutionNote = x.ResolutionNote, ReviewedAt = x.ReviewedAt, CreatedAt = x.CreatedAt };
}
