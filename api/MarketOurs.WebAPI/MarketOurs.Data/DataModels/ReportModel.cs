using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarketOurs.Data.DataModels;

public enum ReportTargetType { Post, Comment, User }
public enum ReportReason { SpamOrAdvertising, FraudOrTransactionRisk, SexualOrInappropriate, HateOrHarassment, Other }
public enum ReportStatus { Pending, Resolved, Rejected }

[Table("reports")]
public class ReportModel : DataModel
{
    [Key, MaxLength(64)] public string Id { get; set; } = Guid.NewGuid().ToString();
    public ReportTargetType TargetType { get; set; }
    [Required, MaxLength(64)] public string TargetId { get; set; } = "";
    [Required, MaxLength(64)] public string ReporterUserId { get; set; } = "";
    [Required, MaxLength(128)] public string ReporterName { get; set; } = "";
    [Required, MaxLength(1024)] public string TargetSummary { get; set; } = "";
    public ReportReason Reason { get; set; }
    [MaxLength(500)] public string? Description { get; set; }
    public ReportStatus Status { get; set; } = ReportStatus.Pending;
    [MaxLength(64)] public string? ReviewedByUserId { get; set; }
    [MaxLength(500)] public string? ResolutionNote { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public override void Update(DataModel model)
    {
        if (model is not ReportModel report) return;
        Status = report.Status; ReviewedByUserId = report.ReviewedByUserId;
        ResolutionNote = report.ResolutionNote; ReviewedAt = report.ReviewedAt;
    }
}
