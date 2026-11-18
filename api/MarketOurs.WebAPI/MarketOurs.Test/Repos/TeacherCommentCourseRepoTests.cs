using MarketOurs.Data;
using MarketOurs.Data.DataModels;
using MarketOurs.DataAPI.Repos;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace MarketOurs.Test.Repos;

public abstract class TeacherCommentCourseRepoContract
{
    protected IDbContextFactory<MarketContext> Factory = null!;
    private TeacherCommentRepo _repo = null!;
    private string _prefix = null!;
    private string _course = null!;
    private string _userId = null!;
    private string _teacher = null!;
    private readonly DateTime _date = new(2026, 11, 1, 0, 0, 0, DateTimeKind.Utc);

    protected abstract Task<IDbContextFactory<MarketContext>> CreateFactoryAsync();

    [SetUp]
    public async Task Seed()
    {
        Factory = null!;
        Factory = await CreateFactoryAsync();
        _repo = new TeacherCommentRepo(Factory);
        _prefix = Guid.NewGuid().ToString("N");
        _course = _prefix + " Calculus";
        _teacher = "Alpha" + _prefix;
        _userId = Guid.NewGuid().ToString();
        await using var context = await Factory.CreateDbContextAsync();
        context.Users.Add(new UserModel { Id = _userId, Name = "Student", Email = _userId + "@example.com" });
        context.TeacherComments.AddRange(
            Review("a", _course, 5, teacher: _teacher),
            Review("b", _course, 1),
            Review("c", " " + _course + " ", 4),
            Review("d", _course, 3),
            Review("e", _course, 1, approved: false),
            Review("f", _course + " II", 2),
            Review("g", _prefix + " Pending", 5, approved: false));
        await context.SaveChangesAsync();
    }

    private TeacherCommentModel Review(string key, string course, int star, bool approved = true, string? teacher = null) => new()
    {
        Key = _prefix + key, CourseName = course, TeacherName = teacher ?? _prefix + " 李老师",
        Star = star, UserId = _userId, IsReview = approved, CreatedOn = _date
    };

    [TearDown]
    public virtual async Task Cleanup()
    {
        if (Factory == null) return;
        await using var context = await Factory.CreateDbContextAsync();
        await context.TeacherComments.Where(c => c.UserId == _userId).ExecuteDeleteAsync();
        await context.Users.Where(c => c.Id == _userId).ExecuteDeleteAsync();

    }

    [Test]
    public async Task TeacherSearch_PreservesAllTeachersRatingsAndTrimsCourseNames()
    {
        var (items, total) = await _repo.QueryCoursesAsync(_teacher, 1, 20);
        var summary = items.Single();
        Assert.Multiple(() =>
        {
            Assert.That(total, Is.EqualTo(1));
            Assert.That(summary.CourseName, Is.EqualTo(_course));
            Assert.That(summary.TotalCount, Is.EqualTo(4));
            Assert.That(summary.AverageStar, Is.EqualTo(3.3));
            Assert.That(summary.StarDistribution.Select(c => c.Star), Is.EqualTo(new[] { 1, 2, 3, 4, 5 }));
            Assert.That(summary.StarDistribution.Select(c => c.Count), Is.EqualTo(new[] { 1, 0, 1, 1, 1 }));
        });
    }

    [Test]
    public async Task CourseSummary_ExactMatchAndRatingOnlyComments()
    {
        var summary = await _repo.GetCourseSummaryAsync(_course);
        var (comments, total) = await _repo.GetCourseCommentsAsync(_course, 1, 20);
        Assert.Multiple(() =>
        {
            Assert.That(summary.TotalCount, Is.EqualTo(4));
            Assert.That(total, Is.EqualTo(4));
            Assert.That(comments.All(c => c.IsReview && c.Comment == null), Is.True);
            Assert.That(comments.All(c => c.User.Name == "Student"), Is.True);
            Assert.That(comments.Select(c => c.Key), Is.EqualTo(new[] { "a", "b", "c", "d" }.Select(k => _prefix + k)));
        });
    }

    [Test]
    public async Task CoursePagination_CountsGroupsAndHasStableOrder()
    {
        var (first, total) = await _repo.QueryCoursesAsync(_prefix, 1, 1);
        var (second, totalAgain) = await _repo.QueryCoursesAsync(_prefix, 2, 1);
        Assert.Multiple(() =>
        {
            Assert.That(total, Is.EqualTo(2));
            Assert.That(totalAgain, Is.EqualTo(2));
            Assert.That(first.Single().CourseName, Is.EqualTo(_course));
            Assert.That(second.Single().CourseName, Is.EqualTo(_course + " II"));
        });
        await using var context = await Factory.CreateDbContextAsync();
        var newer = await context.TeacherComments.SingleAsync(c => c.Key == _prefix + "f");
        newer.CreatedOn = _date.AddDays(1);
        await context.SaveChangesAsync();
        var (updated, _) = await _repo.QueryCoursesAsync(_prefix, 1, 1);
        Assert.That(updated.Single().CourseName, Is.EqualTo(_course + " II"));
    }

    [Test]
    public async Task ReviewPagination_DoesNotChangeWholeCourseSummary()
    {
        await using var context = await Factory.CreateDbContextAsync();
        context.TeacherComments.AddRange(Enumerable.Range(0, 22).Select(i => Review($"more-{i:D2}", _course, 5)));
        await context.SaveChangesAsync();
        var (first, total) = await _repo.GetCourseCommentsAsync(_course, 1, 20);
        var (second, _) = await _repo.GetCourseCommentsAsync(_course, 2, 20);
        var summary = await _repo.GetCourseSummaryAsync(_course);
        Assert.Multiple(() =>
        {
            Assert.That(total, Is.EqualTo(26));
            Assert.That(first, Has.Count.EqualTo(20));
            Assert.That(second, Has.Count.EqualTo(6));
            Assert.That(first.Select(c => c.Key).Intersect(second.Select(c => c.Key)), Is.Empty);
            Assert.That(summary.TotalCount, Is.EqualTo(26));
            Assert.That(summary.AverageStar, Is.EqualTo(4.7));
        });
    }

    [Test]
    public async Task ReviewStatusEditsAndDeletion_AreReflectedWithoutStaleAggregates()
    {
        await using var context = await Factory.CreateDbContextAsync();
        var pending = await context.TeacherComments.SingleAsync(c => c.Key == _prefix + "e");
        pending.IsReview = true;
        await context.SaveChangesAsync();
        Assert.That((await _repo.GetCourseSummaryAsync(_course)).TotalCount, Is.EqualTo(5));
        pending.IsReview = false;
        await context.SaveChangesAsync();
        Assert.That((await _repo.GetCourseSummaryAsync(_course)).TotalCount, Is.EqualTo(4));
        var moved = await context.TeacherComments.SingleAsync(c => c.Key == _prefix + "d");
        moved.CourseName = _course + " II";
        await context.SaveChangesAsync();
        Assert.That((await _repo.GetCourseSummaryAsync(_course)).TotalCount, Is.EqualTo(3));
        await context.TeacherComments.Where(c => c.CourseName.Trim() == _course).ExecuteDeleteAsync();
        var summary = await _repo.GetCourseSummaryAsync(_course);
        var (items, _) = await _repo.QueryCoursesAsync(_prefix, 1, 20);
        Assert.Multiple(() =>
        {
            Assert.That(summary.TotalCount, Is.Zero);
            Assert.That(summary.LatestCommentOn, Is.Null);
            Assert.That(summary.StarDistribution.Sum(c => c.Count), Is.Zero);
            Assert.That(items.Any(c => c.CourseName == _course), Is.False);
        });
    }

    [Test]
    public async Task CourseNames_DoNotMergeDifferentCasing()
    {
        await using var context = await Factory.CreateDbContextAsync();
        context.TeacherComments.Add(Review("lowercase", _course.ToLowerInvariant(), 1));
        await context.SaveChangesAsync();
        var original = await _repo.GetCourseSummaryAsync(_course);
        var lower = await _repo.GetCourseSummaryAsync(_course.ToLowerInvariant());
        Assert.That(original.TotalCount, Is.EqualTo(4));
        Assert.That(lower.TotalCount, Is.EqualTo(1));
    }

    [Test]
    public async Task MissingCourse_ReturnsEmptySummaryAndPage()
    {
        var summary = await _repo.GetCourseSummaryAsync(_prefix + " Missing");
        var (reviews, total) = await _repo.GetCourseCommentsAsync(_prefix + " Missing", 1, 20);
        Assert.Multiple(() =>
        {
            Assert.That(summary.TotalCount, Is.Zero);
            Assert.That(summary.AverageStar, Is.Zero);
            Assert.That(summary.StarDistribution, Has.Count.EqualTo(5));
            Assert.That(reviews, Is.Empty);
            Assert.That(total, Is.Zero);
        });
    }
}

[TestFixture]
public class TeacherCommentCourseSqliteTests : TeacherCommentCourseRepoContract
{
    private SqliteConnection _connection = null!;

    protected override async Task<IDbContextFactory<MarketContext>> CreateFactoryAsync()
    {
        _connection = new SqliteConnection("Data Source=:memory:");
        await _connection.OpenAsync();
        var factory = new CourseTestContextFactory(new DbContextOptionsBuilder<MarketContext>().UseSqlite(_connection).Options);
        await using var context = await factory.CreateDbContextAsync();
        await context.Database.EnsureCreatedAsync();
        return factory;
    }

    [TearDown]
    public override async Task Cleanup()
    {
        try { await base.Cleanup(); }
        finally { if (_connection != null) await _connection.DisposeAsync(); }
    }
}

public sealed class CourseTestContextFactory(DbContextOptions<MarketContext> options) : IDbContextFactory<MarketContext>
{
    public MarketContext CreateDbContext() => new(options);
    public Task<MarketContext> CreateDbContextAsync(CancellationToken cancellationToken = default) => Task.FromResult(CreateDbContext());
}
