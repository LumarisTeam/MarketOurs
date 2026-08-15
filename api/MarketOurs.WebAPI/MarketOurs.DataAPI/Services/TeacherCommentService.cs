using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Exceptions;
using MarketOurs.DataAPI.Repos;
using MarketOurs.DataAPI.Services.Background;
using Microsoft.Extensions.Logging;

namespace MarketOurs.DataAPI.Services;

public interface ITeacherCommentService
{
    /// <summary>提交教师评价</summary>
    Task<TeacherCommentItem> CreateAsync(string userId, CreateTeacherCommentRequest request);

    /// <summary>分页查询评价列表（管理员）</summary>
    Task<PagedResultDto<TeacherCommentItem>> QueryAsync(TeacherCommentQueryRequest request);

    /// <summary>分页搜索已通过评价</summary>
    Task<PagedResultDto<TeacherCommentItem>> SearchApprovedAsync(string? keyword, int page, int pageSize);

    /// <summary>获取我的评价列表</summary>
    Task<List<TeacherCommentItem>> GetMyCommentsAsync(string userId);

    /// <summary>审核评价</summary>
    Task<TeacherCommentItem> ReviewAsync(string key, string adminId, ReviewTeacherCommentRequest request);

    /// <summary>获取待审核列表</summary>
    Task<List<TeacherCommentItem>> GetPendingListAsync();

    /// <summary>获取指定教师的已通过评价</summary>
    Task<List<TeacherCommentItem>> GetApprovedByTeacherAsync(string teacherName);

    /// <summary>获取教师评价汇总</summary>
    Task<TeacherCommentSummary> GetSummaryAsync(string teacherName);

    /// <summary>删除评价</summary>
    Task DeleteAsync(string key, string userId);
}

public class TeacherCommentService(
    ITeacherCommentRepo repository,
    ILogger<TeacherCommentService> logger,
    ReviewMessageQueue? reviewQueue = null) : ITeacherCommentService
{
    public async Task<TeacherCommentItem> CreateAsync(string userId, CreateTeacherCommentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.TeacherName))
            throw new BusinessException(ErrorCode.ParameterEmpty, "教师姓名不能为空");

        if (string.IsNullOrWhiteSpace(request.CourseName))
            throw new BusinessException(ErrorCode.ParameterEmpty, "课程名称不能为空");

        if (request.Star is < 1 or > 5)
            throw new BusinessException(ErrorCode.ParameterOutOfRange, "评分必须在 1-5 之间");

        if (!string.IsNullOrEmpty(request.Comment) && request.Comment.Length > 2000)
            throw new BusinessException(ErrorCode.ParameterOutOfRange, "评价内容不能超过 2000 字");

        var model = new TeacherCommentModel
        {
            TeacherName = request.TeacherName.Trim(),
            CourseName = request.CourseName.Trim(),
            UserId = userId,
            Comment = request.Comment?.Trim(),
            Star = request.Star,
            IsReview = false,
            CreatedOn = DateTime.UtcNow
        };

        await repository.CreateAsync(model);
        if (reviewQueue != null)
        {
            await reviewQueue.EnqueueAsync(new ReviewMessage(model.Key, ReviewType.TeacherComment));
        }

        logger.LogInformation("教师评价已提交，Key: {Key}, 教师: {TeacherName}, 用户: {UserId}",
            model.Key, model.TeacherName, userId);

        return ToItem(model);
    }

    public async Task<PagedResultDto<TeacherCommentItem>> QueryAsync(TeacherCommentQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var (items, total) = await repository.QueryAsync(
            request.TeacherName, request.CourseName, request.IsReview, request.MinStar, page, pageSize);

        return PagedResultDto<TeacherCommentItem>.Success([.. items.Select(ToItem)], total, page, pageSize);
    }

    public async Task<PagedResultDto<TeacherCommentItem>> SearchApprovedAsync(string? keyword, int page, int pageSize)
    {
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 100);

        var (items, total) = await repository.SearchApprovedAsync(keyword, safePage, safePageSize);

        return PagedResultDto<TeacherCommentItem>.Success([.. items.Select(ToItem)], total, safePage, safePageSize);
    }

    public async Task<List<TeacherCommentItem>> GetMyCommentsAsync(string userId)
    {
        var comments = await repository.GetByUserIdAsync(userId);
        return [.. comments.Select(ToItem)];
    }

    public async Task<TeacherCommentItem> ReviewAsync(string key, string adminId, ReviewTeacherCommentRequest request)
    {
        var model = await repository.GetByKeyAsync(key)
                    ?? throw new ResourceAccessException(ErrorCode.CommentNotFound, "教师评价不存在", "TeacherComment", key);

        model.IsReview = request.IsReview;
        model.ReviewedOn = DateTime.UtcNow;
        model.ReviewedBy = adminId;

        // Note: ReviewNote 暂仅记录日志，未来可扩展为独立字段或审计表
        logger.LogInformation("评价已人工审核，Key: {Key}, 是否通过: {IsReview}, 审核人: {AdminId}, 备注: {Note}",
            key, request.IsReview, adminId, request.ReviewNote);

        await repository.UpdateAsync(model);
        return ToItem(model);
    }

    public async Task<List<TeacherCommentItem>> GetPendingListAsync()
    {
        var pending = await repository.GetPendingAsync();
        return [.. pending.Select(ToItem)];
    }

    public async Task<List<TeacherCommentItem>> GetApprovedByTeacherAsync(string teacherName)
    {
        var comments = await repository.GetApprovedByTeacherNameAsync(teacherName);
        return [.. comments.Select(ToItem)];
    }

    public async Task<TeacherCommentSummary> GetSummaryAsync(string teacherName)
    {
        var allComments = await repository.GetApprovedByTeacherNameAsync(teacherName);
        var list = allComments.ToList();

        return new TeacherCommentSummary
        {
            TeacherName = teacherName,
            TotalCount = list.Count,
            AverageStar = list.Count > 0 ? Math.Round(list.Average(c => c.Star), 1) : 0,
            Courses = list.Select(c => c.CourseName).Distinct().ToList()
        };
    }

    public async Task DeleteAsync(string key, string userId)
    {
        var model = await repository.GetByKeyAsync(key)
                    ?? throw new ResourceAccessException(ErrorCode.CommentNotFound, "教师评价不存在", "TeacherComment", key);

        if (model.UserId != userId)
        {
            logger.LogWarning("删除评价权限不足，Key: {Key}, 请求用户: {Requester}, 所属用户: {Owner}",
                key, userId, model.UserId);
            throw new BusinessException(ErrorCode.InsufficientPermission, "无权删除他人的评价", 403, null);
        }

        await repository.DeleteAsync(model);
        logger.LogInformation("评价已删除，Key: {Key}, 用户: {UserId}", key, userId);
    }

    private static TeacherCommentItem ToItem(TeacherCommentModel model) => new()
    {
        Key = model.Key,
        TeacherName = model.TeacherName,
        CourseName = model.CourseName,
        UserId = model.UserId,
        Comment = model.Comment,
        Star = model.Star,
        IsReview = model.IsReview,
        AiReason = model.AiReason,
        AiReviewedOn = model.AiReviewedOn,
        ReviewedOn = model.ReviewedOn,
        ReviewedBy = model.ReviewedBy,
        CreatedOn = model.CreatedOn
    };
}
