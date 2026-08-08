using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace MarketOurs.Data.DataModels;

/// <summary>
/// 教师评价审核状态
/// </summary>
public enum CommentReviewStatus
{
    /// <summary>待审核</summary>
    Pending = 0,
    /// <summary>已通过</summary>
    Approved = 1,
    /// <summary>已拒绝</summary>
    Rejected = 2
}

/// <summary>
/// 教师评价 AI 审核结论
/// </summary>
public enum AiReviewVerdict
{
    /// <summary>未审核</summary>
    None = 0,
    /// <summary>AI 判定通过</summary>
    Pass = 1,
    /// <summary>AI 判定有风险（建议人工审核）</summary>
    Risk = 2,
    /// <summary>AI 判定违规</summary>
    Block = 3
}

/// <summary>
/// 教师评价模型 —— 校园集市教师评价系统
/// </summary>
[Table("teacher_comments")]
public class TeacherCommentModel : DataModel
{
    /// <summary>主键</summary>
    [JsonIgnore]
    [Key]
    [MaxLength(64)]
    public string Key { get; set; } = Guid.NewGuid().ToString();

    /// <summary>教师姓名</summary>
    [MaxLength(128)]
    public string TeacherName { get; set; } = "";

    /// <summary>教师工号（可选，用于精确关联）</summary>
    [MaxLength(64)]
    public string? TeacherId { get; set; }

    /// <summary>课程名称</summary>
    [MaxLength(256)]
    public string CourseName { get; set; } = "";

    /// <summary>评价学生ID</summary>
    [JsonIgnore]
    [MaxLength(64)]
    public string StudentId { get; set; } = "";

    /// <summary>学生昵称（可选，展示用）</summary>
    [MaxLength(128)]
    public string? StudentName { get; set; }

    /// <summary>评价内容</summary>
    [MaxLength(2000)]
    public string? Comment { get; set; }

    /// <summary>评分（1-5 星，默认 5）</summary>
    public int Star { get; set; } = 5;

    /// <summary>审核状态</summary>
    public CommentReviewStatus Status { get; set; } = CommentReviewStatus.Pending;

    /// <summary>AI 审核结论</summary>
    public AiReviewVerdict AiVerdict { get; set; } = AiReviewVerdict.None;

    /// <summary>AI 审核原因/说明</summary>
    [MaxLength(1024)]
    public string? AiReason { get; set; }

    /// <summary>AI 审核置信度 (0-100)</summary>
    public int? AiScore { get; set; }

    /// <summary>AI 审核时间</summary>
    public DateTime? AiReviewedOn { get; set; }

    /// <summary>人工审核时间</summary>
    public DateTime? ReviewedOn { get; set; }

    /// <summary>审核人ID</summary>
    [MaxLength(64)]
    public string? ReviewedBy { get; set; }

    /// <summary>创建时间</summary>
    public DateTime CreatedOn { get; set; } = DateTime.UtcNow;

    /// <inheritdoc />
    public override void Update(DataModel model)
    {
        if (model is not TeacherCommentModel other) return;
        TeacherName = other.TeacherName;
        TeacherId = other.TeacherId;
        CourseName = other.CourseName;
        StudentName = other.StudentName;
        Comment = other.Comment;
        Star = other.Star;
        Status = other.Status;
        AiVerdict = other.AiVerdict;
        AiReason = other.AiReason;
        AiScore = other.AiScore;
        AiReviewedOn = other.AiReviewedOn;
        ReviewedOn = other.ReviewedOn;
        ReviewedBy = other.ReviewedBy;
    }
}
