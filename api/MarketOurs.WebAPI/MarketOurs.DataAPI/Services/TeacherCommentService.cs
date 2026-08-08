using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Exceptions;
using MarketOurs.DataAPI.Repos;
using Microsoft.Extensions.Logging;

namespace MarketOurs.DataAPI.Services;

public interface ITeacherCommentService
{
    /// <summary>提交教师评价</summary>
    Task<TeacherCommentItem> CreateAsync(string studentId, string? studentName, CreateTeacherCommentRequest request);

    /// <summary>分页查询评价列表（管理员）</summary>
    Task<PagedResultDto<TeacherCommentItem>> QueryAsync(TeacherCommentQueryRequest request);

    /// <summary>获取我的评价列表</summary>
    Task<List<TeacherCommentItem>> GetMyCommentsAsync(string studentId);

    /// <summary>审核评价</summary>
    Task<TeacherCommentItem> ReviewAsync(string key, string adminId, ReviewTeacherCommentRequest request);

    /// <summary>获取待审核列表</summary>
    Task<List<TeacherCommentItem>> GetPendingListAsync();

    /// <summary>获取指定教师的已通过评价</summary>
    Task<List<TeacherCommentItem>> GetApprovedByTeacherAsync(string teacherName);

    /// <summary>获取教师评价汇总</summary>
    Task<TeacherCommentSummary> GetSummaryAsync(string teacherName, string? teacherId = null);

    /// <summary>删除评价</summary>
    Task DeleteAsync(string key, string studentId);
}

public class TeacherCommentService(
    ITeacherCommentRepo repository,
    ILogger<TeacherCommentService> logger) : ITeacherCommentService
{
    public async Task<TeacherCommentItem> CreateAsync(string studentId, string? studentName, CreateTeacherCommentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.TeacherName))
            throw new BusinessException(ErrorCode.ParameterEmpty, "教师姓名不能为空");

        if (string.IsNullOrWhiteSpace(request.CourseName))
            throw new BusinessException(ErrorCode.ParameterEmpty, "课程名称不能为空");

        if (request.Star < 1 || request.Star > 5)
            throw new BusinessException(ErrorCode.ParameterOutOfRange, "评分必须在 1-5 之间");

        if (!string.IsNullOrEmpty(request.Comment) && request.Comment.Length > 2000)
            throw new BusinessException(ErrorCode.ParameterOutOfRange, "评价内容不能超过 2000 字");

        var model = new TeacherCommentModel
        {
            TeacherName = request.TeacherName.Trim(),
            TeacherId = request.TeacherId,
            CourseName = request.CourseName.Trim(),
            StudentId = studentId,
            StudentName = studentName,
            Comment = request.Comment?.Trim(),
            Star = request.Star,
            Status = CommentReviewStatus.Pending,
            AiVerdict = AiReviewVerdict.None,
            CreatedOn = DateTime.UtcNow
        };

        // TODO: 调用 AI 审核服务，填充 AiVerdict / AiReason / AiScore / AiReviewedOn
        await repository.CreateAsync(model);
        logger.LogInformation("教师评价已提交，Key: {Key}, 教师: {TeacherName}, 学生: {StudentId}",
            model.Key, model.TeacherName, studentId);

        return ToItem(model);
    }

    public async Task<PagedResultDto<TeacherCommentItem>> QueryAsync(TeacherCommentQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var (items, total) = await repository.QueryAsync(
            request.TeacherName, request.CourseName, request.Status, request.MinStar, page, pageSize);

        return PagedResultDto<TeacherCommentItem>.Success(items.Select(ToItem).ToList(), total, page, pageSize);
    }

    public async Task<List<TeacherCommentItem>> GetMyCommentsAsync(string studentId)
    {
        var comments = await repository.GetByStudentIdAsync(studentId);
        return comments.Select(ToItem).ToList();
    }

    public async Task<TeacherCommentItem> ReviewAsync(string key, string adminId, ReviewTeacherCommentRequest request)
    {
        if (request.Status != CommentReviewStatus.Approved && request.Status != CommentReviewStatus.Rejected)
            throw new BusinessException(ErrorCode.InvalidStatusForOperation, "审核状态必须是 Approved 或 Rejected");

        var model = await repository.GetByKeyAsync(key)
            ?? throw new ResourceAccessException(ErrorCode.CommentNotFound, "教师评价不存在", "TeacherComment", key);

        if (model.Status != CommentReviewStatus.Pending)
            throw new BusinessException(ErrorCode.InvalidStatusForOperation, "该评价已审核，不能重复审核");

        model.Status = request.Status;
        model.ReviewedOn = DateTime.UtcNow;
        model.ReviewedBy = adminId;

        // Note: ReviewNote 暂仅记录日志，未来可扩展为独立字段或审计表
        logger.LogInformation("评价已人工审核，Key: {Key}, 状态: {Status}, 审核人: {AdminId}, 备注: {Note}",
            key, request.Status, adminId, request.ReviewNote);

        await repository.UpdateAsync(model);
        return ToItem(model);
    }

    public async Task<List<TeacherCommentItem>> GetPendingListAsync()
    {
        var pending = await repository.GetPendingAsync();
        return pending.Select(ToItem).ToList();
    }

    public async Task<List<TeacherCommentItem>> GetApprovedByTeacherAsync(string teacherName)
    {
        var comments = await repository.GetApprovedByTeacherNameAsync(teacherName);
        return comments.Select(ToItem).ToList();
    }

    public async Task<TeacherCommentSummary> GetSummaryAsync(string teacherName, string? teacherId = null)
    {
        var allComments = await repository.GetApprovedByTeacherNameAsync(teacherName);
        var list = allComments.ToList();

        if (!string.IsNullOrWhiteSpace(teacherId))
            list = list.Where(c => c.TeacherId == teacherId).ToList();

        return new TeacherCommentSummary
        {
            TeacherName = teacherName,
            TeacherId = teacherId,
            TotalCount = list.Count,
            AverageStar = list.Count > 0 ? Math.Round(list.Average(c => c.Star), 1) : 0,
            Courses = list.Select(c => c.CourseName).Distinct().ToList()
        };
    }

    public async Task DeleteAsync(string key, string studentId)
    {
        var model = await repository.GetByKeyAsync(key)
            ?? throw new ResourceAccessException(ErrorCode.CommentNotFound, "教师评价不存在", "TeacherComment", key);

        if (model.StudentId != studentId)
        {
            logger.LogWarning("删除评价权限不足，Key: {Key}, 请求学生: {Requester}, 所属学生: {Owner}",
                key, studentId, model.StudentId);
            throw new BusinessException(ErrorCode.InsufficientPermission, "无权删除他人的评价", 403, null);
        }

        await repository.DeleteAsync(model);
        logger.LogInformation("评价已删除，Key: {Key}, 学生: {StudentId}", key, studentId);
    }

    private static TeacherCommentItem ToItem(TeacherCommentModel model) => new()
    {
        Key = model.Key,
        TeacherName = model.TeacherName,
        TeacherId = model.TeacherId,
        CourseName = model.CourseName,
        StudentName = model.StudentName,
        Comment = model.Comment,
        Star = model.Star,
        Status = model.Status,
        AiVerdict = model.AiVerdict,
        AiReason = model.AiReason,
        AiScore = model.AiScore,
        AiReviewedOn = model.AiReviewedOn,
        ReviewedOn = model.ReviewedOn,
        ReviewedBy = model.ReviewedBy,
        CreatedOn = model.CreatedOn
    };
}
