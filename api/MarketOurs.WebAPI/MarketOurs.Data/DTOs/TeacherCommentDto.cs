using MarketOurs.Data.DataModels;

namespace MarketOurs.Data.DTOs;

/// <summary>
/// 提交教师评价请求
/// </summary>
public class CreateTeacherCommentRequest
{
    /// <summary>教师姓名</summary>
    public string TeacherName { get; set; } = "";

    /// <summary>教师工号（可选）</summary>
    public string? TeacherId { get; set; }

    /// <summary>课程名称</summary>
    public string CourseName { get; set; } = "";

    /// <summary>评价内容</summary>
    public string? Comment { get; set; }

    /// <summary>评分（1-5）</summary>
    public int Star { get; set; } = 5;
}

/// <summary>
/// 管理员审核请求
/// </summary>
public class ReviewTeacherCommentRequest
{
    /// <summary>审核结论：Approved / Rejected</summary>
    public CommentReviewStatus Status { get; set; }

    /// <summary>审核备注</summary>
    public string? ReviewNote { get; set; }
}

/// <summary>
/// 评价查询参数
/// </summary>
public class TeacherCommentQueryRequest
{
    /// <summary>教师姓名（模糊匹配）</summary>
    public string? TeacherName { get; set; }

    /// <summary>课程名称（模糊匹配）</summary>
    public string? CourseName { get; set; }

    /// <summary>审核状态筛选</summary>
    public CommentReviewStatus? Status { get; set; }

    /// <summary>最低评分</summary>
    public int? MinStar { get; set; }

    /// <summary>页码（从 1 开始）</summary>
    public int Page { get; set; } = 1;

    /// <summary>每页数量</summary>
    public int PageSize { get; set; } = 20;
}

/// <summary>
/// 评价项
/// </summary>
public class TeacherCommentItem
{
    /// <summary>主键</summary>
    public string Key { get; set; } = "";

    /// <summary>教师姓名</summary>
    public string TeacherName { get; set; } = "";

    /// <summary>教师工号</summary>
    public string? TeacherId { get; set; }

    /// <summary>课程名称</summary>
    public string CourseName { get; set; } = "";

    /// <summary>学生昵称</summary>
    public string? StudentName { get; set; }

    /// <summary>评价内容</summary>
    public string? Comment { get; set; }

    /// <summary>评分</summary>
    public int Star { get; set; }

    /// <summary>审核状态</summary>
    public CommentReviewStatus Status { get; set; }

    /// <summary>AI 审核结论</summary>
    public AiReviewVerdict AiVerdict { get; set; }

    /// <summary>AI 审核原因</summary>
    public string? AiReason { get; set; }

    /// <summary>AI 审核置信度</summary>
    public int? AiScore { get; set; }

    /// <summary>AI 审核时间</summary>
    public DateTime? AiReviewedOn { get; set; }

    /// <summary>人工审核时间</summary>
    public DateTime? ReviewedOn { get; set; }

    /// <summary>审核人</summary>
    public string? ReviewedBy { get; set; }

    /// <summary>创建时间</summary>
    public DateTime CreatedOn { get; set; }
}

/// <summary>
/// 教师评价汇总（按教师聚合）
/// </summary>
public class TeacherCommentSummary
{
    /// <summary>教师姓名</summary>
    public string TeacherName { get; set; } = "";

    /// <summary>教师工号</summary>
    public string? TeacherId { get; set; }

    /// <summary>评价总数</summary>
    public int TotalCount { get; set; }

    /// <summary>平均评分</summary>
    public double AverageStar { get; set; }

    /// <summary>课程列表</summary>
    public List<string> Courses { get; set; } = [];
}
