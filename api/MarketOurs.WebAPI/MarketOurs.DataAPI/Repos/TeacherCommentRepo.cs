using MarketOurs.Data;
using MarketOurs.Data.DataModels;
using Microsoft.EntityFrameworkCore;

namespace MarketOurs.DataAPI.Repos;

public interface ITeacherCommentRepo
{
    Task<(List<TeacherCommentModel> Items, int Total)> QueryAsync(
        string? teacherName, string? courseName, bool? isReview,
        int? minStar, int page, int pageSize);

    Task<(List<TeacherCommentModel> Items, int Total)> SearchApprovedAsync(
        string? keyword, int page, int pageSize);

    Task<List<TeacherCommentModel>> GetByUserIdAsync(string userId);

    Task<List<TeacherCommentModel>> GetApprovedByTeacherNameAsync(string teacherName);

    Task<List<TeacherCommentModel>> GetPendingAsync();

    Task<TeacherCommentModel?> GetByKeyAsync(string key);

    Task CreateAsync(TeacherCommentModel comment);

    Task UpdateAsync(TeacherCommentModel comment);

    Task SetReviewStatusAsync(string key, bool isReview, string? reason = null);

    Task DeleteAsync(TeacherCommentModel comment);
}

public class TeacherCommentRepo(IDbContextFactory<MarketContext> factory) : ITeacherCommentRepo
{
    public async Task<(List<TeacherCommentModel> Items, int Total)> QueryAsync(
        string? teacherName, string? courseName, bool? isReview,
        int? minStar, int page, int pageSize)
    {
        await using var context = await factory.CreateDbContextAsync();

        var query = context.TeacherComments.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(teacherName))
            query = query.Where(c => c.TeacherName.Contains(teacherName));

        if (!string.IsNullOrWhiteSpace(courseName))
            query = query.Where(c => c.CourseName.Contains(courseName));

        if (isReview.HasValue)
            query = query.Where(c => c.IsReview == isReview.Value);

        if (minStar.HasValue)
            query = query.Where(c => c.Star >= minStar.Value);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(c => c.CreatedOn)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<(List<TeacherCommentModel> Items, int Total)> SearchApprovedAsync(
        string? keyword, int page, int pageSize)
    {
        await using var context = await factory.CreateDbContextAsync();

        var query = context.TeacherComments.AsNoTracking()
            .Where(c => c.IsReview);

        if (!string.IsNullOrWhiteSpace(keyword))
        {
            var trimmedKeyword = keyword.Trim();
            query = query.Where(c =>
                c.TeacherName.Contains(trimmedKeyword) ||
                c.CourseName.Contains(trimmedKeyword));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(c => c.CreatedOn)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<List<TeacherCommentModel>> GetByUserIdAsync(string userId)
    {
        await using var context = await factory.CreateDbContextAsync();
        return await context.TeacherComments.AsNoTracking()
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedOn)
            .ToListAsync();
    }

    public async Task<List<TeacherCommentModel>> GetApprovedByTeacherNameAsync(string teacherName)
    {
        await using var context = await factory.CreateDbContextAsync();
        return await context.TeacherComments.AsNoTracking()
            .Where(c => c.TeacherName.Contains(teacherName) && c.IsReview)
            .OrderByDescending(c => c.CreatedOn)
            .ToListAsync();
    }

    public async Task<List<TeacherCommentModel>> GetPendingAsync()
    {
        await using var context = await factory.CreateDbContextAsync();
        return await context.TeacherComments.AsNoTracking()
            .Where(c => !c.IsReview)
            .OrderByDescending(c => c.CreatedOn)
            .ToListAsync();
    }

    public async Task<TeacherCommentModel?> GetByKeyAsync(string key)
    {
        await using var context = await factory.CreateDbContextAsync();
        return await context.TeacherComments.FirstOrDefaultAsync(c => c.Key == key);
    }

    public async Task CreateAsync(TeacherCommentModel comment)
    {
        await using var context = await factory.CreateDbContextAsync();
        context.TeacherComments.Add(comment);
        await context.SaveChangesAsync();
    }

    public async Task UpdateAsync(TeacherCommentModel comment)
    {
        await using var context = await factory.CreateDbContextAsync();
        context.TeacherComments.Update(comment);
        await context.SaveChangesAsync();
    }

    public async Task SetReviewStatusAsync(string key, bool isReview, string? reason = null)
    {
        await using var context = await factory.CreateDbContextAsync();
        var comment = await context.TeacherComments.FirstOrDefaultAsync(c => c.Key == key);
        if (comment == null)
        {
            return;
        }

        comment.IsReview = isReview;
        comment.AiReason = isReview ? null : reason;
        comment.AiReviewedOn = DateTime.UtcNow;
        await context.SaveChangesAsync();
    }

    public async Task DeleteAsync(TeacherCommentModel comment)
    {
        await using var context = await factory.CreateDbContextAsync();
        context.TeacherComments.Remove(comment);
        await context.SaveChangesAsync();
    }
}
