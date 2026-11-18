using MarketOurs.Data;
using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using Microsoft.EntityFrameworkCore;
using ParadeDB.EntityFrameworkCore.Extensions;

namespace MarketOurs.DataAPI.Repos;

public interface ITeacherCommentRepo
{
    Task<(List<TeacherCommentModel> Items, int Total)> QueryAsync(
        string? teacherName, string? courseName, bool? isReview,
        int? minStar, int page, int pageSize);

    Task<(List<TeacherCommentModel> Items, int Total)> SearchApprovedAsync(
        string? keyword, int page, int pageSize);

    Task<(List<CourseCommentSummary> Items, int Total)> QueryCoursesAsync(string? keyword, int page, int pageSize);
    Task<CourseCommentSummary> GetCourseSummaryAsync(string courseName);
    Task<(List<TeacherCommentModel> Items, int Total)> GetCourseCommentsAsync(string courseName, int page, int pageSize);

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

        var query = context.TeacherComments.AsNoTracking()
            .Include(c => c.User)
            .AsQueryable();

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

        if (context.Database.IsNpgsql())
        {
            try
            {
                // ParadeDB BM25 全文检索教师姓名/课程名；无 ParadeDB 时回退到 Contains
                IQueryable<TeacherCommentModel> query = context.TeacherComments.AsNoTracking()
                    .Include(c => c.User)
                    .Where(c => c.IsReview);

                if (!string.IsNullOrWhiteSpace(keyword))
                {
                    var trimmedKeyword = keyword.Trim();
                    query = query.Where(c =>
                        EF.Functions.MatchAny(c.TeacherName, trimmedKeyword) ||
                        EF.Functions.MatchAny(c.CourseName, trimmedKeyword));
                }

                var total = await query.CountAsync();
                var items = await query
                    .OrderByDescending(c => c.CreatedOn)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                return (items, total);
            }
            catch
            {
                return await SearchApprovedWithContainsAsync(context, keyword, page, pageSize);
            }
        }

        return await SearchApprovedWithContainsAsync(context, keyword, page, pageSize);
    }

    private static async Task<(List<TeacherCommentModel> Items, int Total)> SearchApprovedWithContainsAsync(
        MarketContext context, string? keyword, int page, int pageSize)
    {
        var query = context.TeacherComments.AsNoTracking()
            .Include(c => c.User)
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

    public async Task<(List<CourseCommentSummary> Items, int Total)> QueryCoursesAsync(
        string? keyword, int page, int pageSize)
    {
        await using var context = await factory.CreateDbContextAsync();
        if (context.Database.IsNpgsql() && !string.IsNullOrWhiteSpace(keyword))
        {
            try
            {
                return await QueryCoursesCoreAsync(context, keyword, page, pageSize, true);
            }
            catch (InvalidOperationException)
            {
                // MatchAny also requires the ParadeDB EF query translator.
            }
            catch (Npgsql.PostgresException ex) when (ex.SqlState is "42883" or "42704" or "0A000" or "XX000")
            {
                // A plain PostgreSQL installation may not have the ParadeDB extension/index.
            }
        }
        return await QueryCoursesCoreAsync(context, keyword, page, pageSize, false);
    }

    private static async Task<(List<CourseCommentSummary> Items, int Total)> QueryCoursesCoreAsync(
        MarketContext context, string? keyword, int page, int pageSize, bool useBm25)
    {
        var approved = context.TeacherComments.AsNoTracking().Where(c => c.IsReview);
        var courses = approved;
        if (!string.IsNullOrWhiteSpace(keyword))
        {
            var term = keyword.Trim();
            var matches = useBm25
                ? approved.Where(c => EF.Functions.MatchAny(c.TeacherName, term) || EF.Functions.MatchAny(c.CourseName, term))
                : approved.Where(c => c.TeacherName.Contains(term) || c.CourseName.Contains(term));
            var courseNames = matches.Select(c => c.CourseName.Trim());
            // Filter courses, not individual reviews: a teacher search must retain all teachers' ratings.
            courses = approved.Where(c => courseNames.Contains(c.CourseName.Trim()));
        }
        var aggregates = AggregateCourses(courses);
        var total = await aggregates.CountAsync();
        var items = await aggregates.OrderByDescending(c => c.LatestCommentOn).ThenBy(c => c.CourseName)
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return (items.Select(ToCourseSummary).ToList(), total);
    }

    public async Task<CourseCommentSummary> GetCourseSummaryAsync(string courseName)
    {
        await using var context = await factory.CreateDbContextAsync();
        var aggregate = await AggregateCourses(context.TeacherComments.AsNoTracking()
                .Where(c => c.IsReview && c.CourseName.Trim() == courseName))
            .SingleOrDefaultAsync();
        return aggregate == null ? new CourseCommentSummary { CourseName = courseName } : ToCourseSummary(aggregate);
    }

    public async Task<(List<TeacherCommentModel> Items, int Total)> GetCourseCommentsAsync(
        string courseName, int page, int pageSize)
    {
        await using var context = await factory.CreateDbContextAsync();
        var query = context.TeacherComments.AsNoTracking()
            .Where(c => c.IsReview && c.CourseName.Trim() == courseName);
        var total = await query.CountAsync();
        var items = await query.Include(c => c.User).OrderByDescending(c => c.CreatedOn).ThenBy(c => c.Key)
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return (items, total);
    }

    private static IQueryable<CourseAggregate> AggregateCourses(IQueryable<TeacherCommentModel> query) =>
        query.GroupBy(c => c.CourseName.Trim()).Select(group => new CourseAggregate
        {
            CourseName = group.Key,
            TotalCount = group.Count(),
            AverageStar = group.Average(c => (double)c.Star),
            LatestCommentOn = group.Max(c => c.CreatedOn),
            One = group.Count(c => c.Star == 1),
            Two = group.Count(c => c.Star == 2),
            Three = group.Count(c => c.Star == 3),
            Four = group.Count(c => c.Star == 4),
            Five = group.Count(c => c.Star == 5)
        });

    private static CourseCommentSummary ToCourseSummary(CourseAggregate aggregate) => new()
    {
        CourseName = aggregate.CourseName,
        TotalCount = aggregate.TotalCount,
        AverageStar = Math.Round(aggregate.AverageStar, 1, MidpointRounding.AwayFromZero),
        LatestCommentOn = aggregate.LatestCommentOn,
        StarDistribution = new[] { aggregate.One, aggregate.Two, aggregate.Three, aggregate.Four, aggregate.Five }
            .Select((count, index) => new CourseStarCount { Star = index + 1, Count = count }).ToList()
    };

    private sealed class CourseAggregate
    {
        public string CourseName { get; set; } = "";
        public int TotalCount { get; set; }
        public double AverageStar { get; set; }
        public DateTime LatestCommentOn { get; set; }
        public int One { get; set; }
        public int Two { get; set; }
        public int Three { get; set; }
        public int Four { get; set; }
        public int Five { get; set; }
    }

    public async Task<List<TeacherCommentModel>> GetByUserIdAsync(string userId)
    {
        await using var context = await factory.CreateDbContextAsync();
        return await context.TeacherComments.AsNoTracking()
            .Include(c => c.User)
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedOn)
            .ToListAsync();
    }

    public async Task<List<TeacherCommentModel>> GetApprovedByTeacherNameAsync(string teacherName)
    {
        await using var context = await factory.CreateDbContextAsync();
        return await context.TeacherComments.AsNoTracking()
            .Include(c => c.User)
            .Where(c => c.TeacherName.Contains(teacherName) && c.IsReview)
            .OrderByDescending(c => c.CreatedOn)
            .ToListAsync();
    }

    public async Task<List<TeacherCommentModel>> GetPendingAsync()
    {
        await using var context = await factory.CreateDbContextAsync();
        return await context.TeacherComments.AsNoTracking()
            .Include(c => c.User)
            .Where(c => !c.IsReview)
            .OrderByDescending(c => c.CreatedOn)
            .ToListAsync();
    }

    public async Task<TeacherCommentModel?> GetByKeyAsync(string key)
    {
        await using var context = await factory.CreateDbContextAsync();
        return await context.TeacherComments.Include(c => c.User).FirstOrDefaultAsync(c => c.Key == key);
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
