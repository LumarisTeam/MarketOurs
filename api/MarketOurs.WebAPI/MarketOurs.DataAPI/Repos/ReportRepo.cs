using MarketOurs.Data;
using MarketOurs.Data.DataModels;
using Microsoft.EntityFrameworkCore;

namespace MarketOurs.DataAPI.Repos;

public interface IReportRepo
{
    Task CreateAsync(ReportModel report);
    Task<bool> ExistsAsync(string reporterUserId, ReportTargetType targetType, string targetId);
    Task<ReportModel?> GetByIdAsync(string id);
    Task<List<ReportModel>> GetAllAsync(ReportStatus? status, ReportTargetType? targetType, int pageIndex, int pageSize);
    Task<int> CountAsync(ReportStatus? status, ReportTargetType? targetType);
    Task UpdateAsync(ReportModel report);
}

public class ReportRepo(IDbContextFactory<MarketContext> factory) : IReportRepo
{
    public async Task CreateAsync(ReportModel report) { await using var db = await factory.CreateDbContextAsync(); db.Reports.Add(report); await db.SaveChangesAsync(); }
    public async Task<bool> ExistsAsync(string reporterUserId, ReportTargetType targetType, string targetId) { await using var db = await factory.CreateDbContextAsync(); return await db.Reports.AnyAsync(x => x.ReporterUserId == reporterUserId && x.TargetType == targetType && x.TargetId == targetId); }
    public async Task<ReportModel?> GetByIdAsync(string id) { await using var db = await factory.CreateDbContextAsync(); return await db.Reports.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id); }
    public async Task<List<ReportModel>> GetAllAsync(ReportStatus? status, ReportTargetType? targetType, int pageIndex, int pageSize) { await using var db = await factory.CreateDbContextAsync(); return await Query(db, status, targetType).OrderByDescending(x => x.CreatedAt).Skip((pageIndex - 1) * pageSize).Take(pageSize).ToListAsync(); }
    public async Task<int> CountAsync(ReportStatus? status, ReportTargetType? targetType) { await using var db = await factory.CreateDbContextAsync(); return await Query(db, status, targetType).CountAsync(); }
    public async Task UpdateAsync(ReportModel report) { await using var db = await factory.CreateDbContextAsync(); db.Reports.Update(report); await db.SaveChangesAsync(); }
    private static IQueryable<ReportModel> Query(MarketContext db, ReportStatus? status, ReportTargetType? targetType) => db.Reports.AsNoTracking().Where(x => (!status.HasValue || x.Status == status) && (!targetType.HasValue || x.TargetType == targetType));
}
