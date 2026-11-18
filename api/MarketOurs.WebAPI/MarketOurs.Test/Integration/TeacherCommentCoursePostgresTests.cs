using MarketOurs.Data;
using MarketOurs.Test.Repos;
using Microsoft.EntityFrameworkCore;
using ParadeDB.EntityFrameworkCore.Extensions;

namespace MarketOurs.Test.Integration;

[TestFixture, Category("Integration")]
public class TeacherCommentCoursePostgresTests : TeacherCommentCourseRepoContract
{
    protected override Task<IDbContextFactory<MarketContext>> CreateFactoryAsync()
    {
        if (!TestAssemblySetup.IsDockerAvailable)
            Assert.Ignore("Docker is not available. PostgreSQL course tests are skipped.");
        IDbContextFactory<MarketContext> factory = new CourseTestContextFactory(
            new DbContextOptionsBuilder<MarketContext>().UseNpgsql(TestAssemblySetup.DbConnectionString, options => options.UseParadeDb()).Options);
        return Task.FromResult(factory);
    }
}
