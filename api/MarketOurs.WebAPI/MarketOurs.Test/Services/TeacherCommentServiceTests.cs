using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Exceptions;
using MarketOurs.DataAPI.Repos;
using MarketOurs.DataAPI.Services;
using MarketOurs.DataAPI.Services.Background;
using Microsoft.Extensions.Logging;
using Moq;

namespace MarketOurs.Test.Services;

/// <summary>
/// 教师评价服务层测试 —— 校园集市
/// 覆盖业务校验、审核流程、权限控制与汇总计算等核心逻辑。
/// </summary>
[TestFixture]
public class TeacherCommentServiceTests
{
    private Mock<ITeacherCommentRepo> _mockRepo = null!;
    private Mock<ILogger<TeacherCommentService>> _mockLogger = null!;
    private ReviewMessageQueue _reviewQueue = null!;
    private TeacherCommentService _service = null!;

    private const string UserId = "user_001";
    private const string AdminId = "admin_001";

    [SetUp]
    public void Setup()
    {
        _mockRepo = new Mock<ITeacherCommentRepo>();
        _mockLogger = new Mock<ILogger<TeacherCommentService>>();
        _reviewQueue = new ReviewMessageQueue();
        _service = new TeacherCommentService(_mockRepo.Object, _mockLogger.Object, _reviewQueue);
    }

    // ==================== CreateAsync ====================

    [Test]
    public async Task CreateAsync_WithValidRequest_ShouldCreatePendingComment()
    {
        var request = new CreateTeacherCommentRequest
        {
            TeacherName = " 张老师 ",
            CourseName = " 高等数学 ",
            Star = 4,
            Comment = " 讲课很清晰 "
        };

        TeacherCommentModel? captured = null;
        _mockRepo
            .Setup(r => r.CreateAsync(It.IsAny<TeacherCommentModel>()))
            .Callback<TeacherCommentModel>(m => captured = m)
            .Returns(Task.CompletedTask);

        var result = await _service.CreateAsync(UserId, request);

        Assert.Multiple(() =>
        {
            Assert.That(result.TeacherName, Is.EqualTo("张老师")); // Trim 验证
            Assert.That(result.CourseName, Is.EqualTo("高等数学"));
            Assert.That(result.Comment, Is.EqualTo("讲课很清晰"));
            Assert.That(result.Star, Is.EqualTo(4));
            Assert.That(result.IsReview, Is.False);
            Assert.That(result.UserId, Is.EqualTo(UserId));
        });
        // 验证传入仓库的模型字段
        Assert.Multiple(() =>
        {
            Assert.That(captured!.UserId, Is.EqualTo(UserId));
            Assert.That(captured.IsReview, Is.False);
        });
        _mockRepo.Verify(r => r.CreateAsync(It.IsAny<TeacherCommentModel>()), Times.Once);

        await using var enumerator = _reviewQueue.DequeueAllAsync(CancellationToken.None).GetAsyncEnumerator();
        Assert.That(await enumerator.MoveNextAsync(), Is.True);
        Assert.Multiple(() =>
        {
            Assert.That(enumerator.Current.TargetId, Is.EqualTo(result.Key));
            Assert.That(enumerator.Current.Type, Is.EqualTo(ReviewType.TeacherComment));
        });
    }

    [TestCase("", "高数", 5, Description = "教师姓名为空")]
    [TestCase(" ", "高数", 5, Description = "教师姓名为空白")]
    public void CreateAsync_WhenTeacherNameEmpty_ShouldThrow(string teacherName, string courseName, int star)
    {
        var request = new CreateTeacherCommentRequest { TeacherName = teacherName, CourseName = courseName, Star = star };

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.CreateAsync(UserId, request));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.ParameterEmpty));
            Assert.That(ex.Message, Does.Contain("教师姓名"));
        });
        _mockRepo.Verify(r => r.CreateAsync(It.IsAny<TeacherCommentModel>()), Times.Never);
    }

    [Test]
    public void CreateAsync_WhenCourseNameEmpty_ShouldThrow()
    {
        var request = new CreateTeacherCommentRequest { TeacherName = "张老师", CourseName = "", Star = 5 };

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.CreateAsync(UserId, request));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.ParameterEmpty));
            Assert.That(ex.Message, Does.Contain("课程名称"));
        });
    }

    [TestCase(0, Description = "评分为 0，低于下限")]
    [TestCase(6, Description = "评分为 6，高于上限")]
    public void CreateAsync_WhenStarOutOfRange_ShouldThrow(int star)
    {
        var request = new CreateTeacherCommentRequest { TeacherName = "张老师", CourseName = "高数", Star = star };

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.CreateAsync(UserId, request));

        Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.ParameterOutOfRange));
    }

    [Test]
    public void CreateAsync_WhenCommentExceeds2000Chars_ShouldThrow()
    {
        var request = new CreateTeacherCommentRequest
        {
            TeacherName = "张老师",
            CourseName = "高数",
            Star = 5,
            Comment = new string('字', 2001)
        };

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.CreateAsync(UserId, request));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.ParameterOutOfRange));
            Assert.That(ex.Message, Does.Contain("2000"));
        });
    }

    [Test]
    public async Task CreateAsync_WhenCommentExactly2000Chars_ShouldSucceed()
    {
        var request = new CreateTeacherCommentRequest
        {
            TeacherName = "张老师",
            CourseName = "高数",
            Star = 5,
            Comment = new string('字', 2000)
        };

        _mockRepo.Setup(r => r.CreateAsync(It.IsAny<TeacherCommentModel>())).Returns(Task.CompletedTask);

        var result = await _service.CreateAsync(UserId, request);

        Assert.That(result.Comment!.Length, Is.EqualTo(2000));
    }

    // ==================== QueryAsync ====================

    [Test]
    public async Task QueryAsync_ShouldClampPageAndPageSize()
    {
        var items = new List<TeacherCommentModel> { new() { Key = "k1" } };
        _mockRepo
            .Setup(r => r.QueryAsync(null, null, null, null, It.IsAny<int>(), It.IsAny<int>()))
            .ReturnsAsync((items, 1));

        // page=0 / pageSize=999 应被规整
        var result = await _service.QueryAsync(new TeacherCommentQueryRequest { Page = 0, PageSize = 999 });

        Assert.Multiple(() =>
        {
            Assert.That(result.PageIndex, Is.EqualTo(1));
            Assert.That(result.PageSize, Is.EqualTo(100));
            Assert.That(result.TotalCount, Is.EqualTo(1));
        });
        _mockRepo.Verify(r => r.QueryAsync(null, null, null, null, 1, 100), Times.Once);
    }

    [Test]
    public async Task QueryAsync_ShouldForwardFilters()
    {
        _mockRepo
            .Setup(r => r.QueryAsync("张", "高数", true, 4, 1, 20))
            .ReturnsAsync((new List<TeacherCommentModel>(), 0));

        await _service.QueryAsync(new TeacherCommentQueryRequest
        {
            TeacherName = "张",
            CourseName = "高数",
            IsReview = true,
            MinStar = 4
        });

        _mockRepo.Verify(r => r.QueryAsync("张", "高数", true, 4, 1, 20), Times.Once);
    }

    // ==================== ReviewAsync ====================

    [Test]
    public async Task ReviewAsync_WhenApproved_ShouldUpdateStatusAndReviewer()
    {
        var model = new TeacherCommentModel { Key = "k1", IsReview = false };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        var result = await _service.ReviewAsync("k1", AdminId, new ReviewTeacherCommentRequest { IsReview = true, ReviewNote = "ok" });

        Assert.Multiple(() =>
        {
            Assert.That(result.IsReview, Is.True);
            Assert.That(model.ReviewedBy, Is.EqualTo(AdminId));
            Assert.That(model.ReviewedOn, Is.Not.Null);
        });
        _mockRepo.Verify(r => r.UpdateAsync(model), Times.Once);
    }

    [Test]
    public async Task ReviewAsync_WhenRejected_ShouldUpdateStatus()
    {
        var model = new TeacherCommentModel { Key = "k1", IsReview = true };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        var result = await _service.ReviewAsync("k1", AdminId, new ReviewTeacherCommentRequest { IsReview = false });

        Assert.That(result.IsReview, Is.False);
    }

    [Test]
    public void ReviewAsync_WhenNotFound_ShouldThrow()
    {
        _mockRepo.Setup(r => r.GetByKeyAsync("missing")).ReturnsAsync((TeacherCommentModel?)null);

        var ex = Assert.ThrowsAsync<ResourceAccessException>(async () =>
            await _service.ReviewAsync("missing", AdminId, new ReviewTeacherCommentRequest { IsReview = true }));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.CommentNotFound));
            Assert.That(ex.ResourceName, Is.EqualTo("TeacherComment"));
            Assert.That(ex.ResourceId, Is.EqualTo("missing"));
        });
    }

    // ==================== UpdateAsync ====================

    [Test]
    public async Task UpdateAsync_WhenOwner_ShouldUpdateAndRequireReReview()
    {
        var model = new TeacherCommentModel
        {
            Key = "k1",
            UserId = UserId,
            TeacherName = "旧老师",
            CourseName = "旧课程",
            Comment = "旧内容",
            Star = 5,
            IsReview = true
        };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);
        _mockRepo.Setup(r => r.UpdateAsync(It.IsAny<TeacherCommentModel>())).Returns(Task.CompletedTask);

        var request = new UpdateTeacherCommentRequest
        {
            TeacherName = " 张老师 ",
            CourseName = " 高等数学 ",
            Comment = " 新内容 ",
            Star = 4
        };

        var result = await _service.UpdateAsync("k1", UserId, false, request);

        Assert.Multiple(() =>
        {
            Assert.That(model.TeacherName, Is.EqualTo("张老师"));
            Assert.That(model.CourseName, Is.EqualTo("高等数学"));
            Assert.That(model.Comment, Is.EqualTo("新内容"));
            Assert.That(model.Star, Is.EqualTo(4));
            Assert.That(model.IsReview, Is.False); // 作者修改需重新审核
        });
        _mockRepo.Verify(r => r.UpdateAsync(model), Times.Once);

        await using var enumerator = _reviewQueue.DequeueAllAsync(CancellationToken.None).GetAsyncEnumerator();
        Assert.That(await enumerator.MoveNextAsync(), Is.True);
        Assert.Multiple(() =>
        {
            Assert.That(enumerator.Current.TargetId, Is.EqualTo(model.Key));
            Assert.That(enumerator.Current.Type, Is.EqualTo(ReviewType.TeacherComment));
        });
    }

    [Test]
    public async Task UpdateAsync_WhenAdmin_ShouldUpdateAndKeepApproved()
    {
        var model = new TeacherCommentModel { Key = "k1", UserId = "other_user", IsReview = false };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);
        _mockRepo.Setup(r => r.UpdateAsync(It.IsAny<TeacherCommentModel>())).Returns(Task.CompletedTask);

        var request = new UpdateTeacherCommentRequest { TeacherName = "张老师", CourseName = "高数", Star = 3, Comment = "改" };

        var result = await _service.UpdateAsync("k1", AdminId, true, request);

        Assert.Multiple(() =>
        {
            Assert.That(result.IsReview, Is.True); // 管理员修改视为已通过
            Assert.That(model.IsReview, Is.True);
        });
        _mockRepo.Verify(r => r.UpdateAsync(model), Times.Once);
    }

    [Test]
    public void UpdateAsync_WhenNotOwnerNorAdmin_ShouldThrowPermissionError()
    {
        var model = new TeacherCommentModel { Key = "k1", UserId = "other_user" };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.UpdateAsync("k1", UserId, false,
                new UpdateTeacherCommentRequest { TeacherName = "张老师", CourseName = "高数", Star = 5 }));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.InsufficientPermission));
            Assert.That(ex.HttpStatusCode, Is.EqualTo(403));
        });
        _mockRepo.Verify(r => r.UpdateAsync(It.IsAny<TeacherCommentModel>()), Times.Never);
    }

    [Test]
    public void UpdateAsync_WhenNotFound_ShouldThrow()
    {
        _mockRepo.Setup(r => r.GetByKeyAsync("missing")).ReturnsAsync((TeacherCommentModel?)null);

        var ex = Assert.ThrowsAsync<ResourceAccessException>(async () =>
            await _service.UpdateAsync("missing", UserId, false,
                new UpdateTeacherCommentRequest { TeacherName = "张老师", CourseName = "高数", Star = 5 }));

        Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.CommentNotFound));
    }

    [Test]
    public void UpdateAsync_WhenTeacherNameEmpty_ShouldThrow()
    {
        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.UpdateAsync("k1", UserId, false,
                new UpdateTeacherCommentRequest { TeacherName = "", CourseName = "高数", Star = 5 }));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.ParameterEmpty));
            Assert.That(ex.Message, Does.Contain("教师姓名"));
        });
        _mockRepo.Verify(r => r.UpdateAsync(It.IsAny<TeacherCommentModel>()), Times.Never);
    }

    // ==================== DeleteAsync ====================

    [Test]
    public async Task DeleteAsync_WhenOwner_ShouldDelete()
    {
        var model = new TeacherCommentModel { Key = "k1", UserId = UserId };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        await _service.DeleteAsync("k1", UserId);

        _mockRepo.Verify(r => r.DeleteAsync(model), Times.Once);
    }

    [Test]
    public void DeleteAsync_WhenNotOwner_ShouldThrowPermissionError()
    {
        var model = new TeacherCommentModel { Key = "k1", UserId = "other_user" };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.DeleteAsync("k1", UserId));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.InsufficientPermission));
            Assert.That(ex.HttpStatusCode, Is.EqualTo(403));
        });
        _mockRepo.Verify(r => r.DeleteAsync(It.IsAny<TeacherCommentModel>()), Times.Never);
    }

    [Test]
    public void DeleteAsync_WhenNotFound_ShouldThrow()
    {
        _mockRepo.Setup(r => r.GetByKeyAsync("missing")).ReturnsAsync((TeacherCommentModel?)null);

        var ex = Assert.ThrowsAsync<ResourceAccessException>(async () =>
            await _service.DeleteAsync("missing", UserId));

        Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.CommentNotFound));
    }

    // ==================== GetSummaryAsync ====================

    [Test]
    public async Task GetSummaryAsync_ShouldCalculateAverageAndCourses()
    {
        var comments = new List<TeacherCommentModel>
        {
            new() { TeacherName = "张老师", CourseName = "高数", Star = 4, IsReview = true },
            new() { TeacherName = "张老师", CourseName = "线代", Star = 5, IsReview = true },
            new() { TeacherName = "张老师", CourseName = "高数", Star = 3, IsReview = true }
        };
        _mockRepo.Setup(r => r.GetApprovedByTeacherNameAsync("张老师")).ReturnsAsync(comments);

        var summary = await _service.GetSummaryAsync("张老师");

        Assert.Multiple(() =>
        {
            Assert.That(summary.TotalCount, Is.EqualTo(3));
            Assert.That(summary.AverageStar, Is.EqualTo(4.0)); // (4+5+3)/3 = 4.0
            Assert.That(summary.Courses.Count, Is.EqualTo(2));
            Assert.That(summary.Courses, Does.Contain("高数"));
            Assert.That(summary.Courses, Does.Contain("线代"));
        });
    }

    [Test]
    public async Task GetSummaryAsync_WhenNoComments_ShouldReturnZeroAverage()
    {
        _mockRepo.Setup(r => r.GetApprovedByTeacherNameAsync("不存在")).ReturnsAsync(new List<TeacherCommentModel>());

        var summary = await _service.GetSummaryAsync("不存在");

        Assert.Multiple(() =>
        {
            Assert.That(summary.TotalCount, Is.EqualTo(0));
            Assert.That(summary.AverageStar, Is.EqualTo(0));
            Assert.That(summary.Courses, Is.Empty);
        });
    }

    // ==================== GetApprovedByTeacherAsync ====================

    [Test]
    public async Task GetApprovedByTeacherAsync_ShouldDelegateToRepo()
    {
        var comments = new List<TeacherCommentModel>
        {
            new() { Key = "k1", TeacherName = "张老师", IsReview = true }
        };
        _mockRepo.Setup(r => r.GetApprovedByTeacherNameAsync("张老师")).ReturnsAsync(comments);

        var result = await _service.GetApprovedByTeacherAsync("张老师");

        Assert.That(result.Count, Is.EqualTo(1));
        _mockRepo.Verify(r => r.GetApprovedByTeacherNameAsync("张老师"), Times.Once);
    }

    // ==================== GetPendingListAsync ====================

    [Test]
    public async Task GetPendingListAsync_ShouldReturnPendingItems()
    {
        var pending = new List<TeacherCommentModel>
        {
            new() { Key = "k1", IsReview = false },
            new() { Key = "k2", IsReview = false }
        };
        _mockRepo.Setup(r => r.GetPendingAsync()).ReturnsAsync(pending);

        var result = await _service.GetPendingListAsync();

        Assert.That(result.Count, Is.EqualTo(2));
    }

    // ==================== GetMyCommentsAsync ====================

    [Test]
    public async Task GetMyCommentsAsync_ShouldReturnUserComments()
    {
        var mine = new List<TeacherCommentModel>
        {
            new() { Key = "k1", UserId = UserId },
            new() { Key = "k2", UserId = UserId }
        };
        _mockRepo.Setup(r => r.GetByUserIdAsync(UserId)).ReturnsAsync(mine);

        var result = await _service.GetMyCommentsAsync(UserId);

        Assert.That(result.Count, Is.EqualTo(2));
        _mockRepo.Verify(r => r.GetByUserIdAsync(UserId), Times.Once);
    }
}
