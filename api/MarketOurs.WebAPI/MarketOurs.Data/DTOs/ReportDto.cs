using System.ComponentModel.DataAnnotations;
using MarketOurs.Data.DataModels;

namespace MarketOurs.Data.DTOs;

public class CreateReportRequest
{
    public ReportTargetType TargetType { get; set; }
    [Required, MaxLength(64)] public string TargetId { get; set; } = "";
    public ReportReason Reason { get; set; }
    [MaxLength(500)] public string? Description { get; set; }
}

public class UpdateReportStatusRequest
{
    public ReportStatus Status { get; set; }
    [MaxLength(500)] public string? ResolutionNote { get; set; }
}

public class ReportDto
{
    public string Id { get; set; } = "";
    public ReportTargetType TargetType { get; set; }
    public string TargetId { get; set; } = "";
    public string TargetSummary { get; set; } = "";
    public string ReporterUserId { get; set; } = "";
    public string ReporterName { get; set; } = "";
    public ReportReason Reason { get; set; }
    public string? Description { get; set; }
    public ReportStatus Status { get; set; }
    public string? ReviewedByUserId { get; set; }
    public string? ResolutionNote { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}
