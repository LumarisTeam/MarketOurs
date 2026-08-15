using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace MarketOurs.Data.DataModels;

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

    /// <summary>课程名称</summary>
    [MaxLength(256)]
    public string CourseName { get; set; } = "";

    /// <summary>
    /// 评论者用户 ID
    /// </summary>
    [MaxLength(64)]
    public string UserId { get; set; } = "";

    /// <summary>
    /// 评论者用户信息
    /// </summary>
    public UserModel User { get; set; } = null!;

    /// <summary>评价内容</summary>
    [MaxLength(2000)]
    public string? Comment { get; set; }

    /// <summary>评分（1-5 星，默认 5）</summary>
    public int Star { get; set; } = 5;

    /// <summary>是否通过审核</summary>
    public bool IsReview { get; set; }

    /// <summary>AI 审核原因/说明</summary>
    [MaxLength(1024)]
    public string? AiReason { get; set; }

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
        CourseName = other.CourseName;
        Comment = other.Comment;
        Star = other.Star;
        IsReview = other.IsReview;
        AiReason = other.AiReason;
        AiReviewedOn = other.AiReviewedOn;
        ReviewedOn = other.ReviewedOn;
        ReviewedBy = other.ReviewedBy;
    }
}
