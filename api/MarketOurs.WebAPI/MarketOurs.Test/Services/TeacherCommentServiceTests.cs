using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Exceptions;
using MarketOurs.DataAPI.Repos;
using MarketOurs.DataAPI.Services;
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
    private TeacherCommentService _service = null!;

    private const string StudentId = "student_001";
    private const string AdminId = "admin_001";

    [SetUp]
    public void Setup()
    {
        _mockRepo = new Mock<ITeacherCommentRepo>();
        _mockLogger = new Mock<ILogger<TeacherCommentService>>();
        _service = new TeacherCommentService(_mockRepo.Object, _mockLogger.Object);
    }

    // ==================== CreateAsync ====================

    [Test]
    public async Task CreateAsync_WithValidRequest_ShouldCreatePendingComment()
    {
        var request = new CreateTeacherCommentRequest
        {
            TeacherName = " 张老师 ",
            TeacherId = "T001",
            CourseName = " 高等数学 ",
            Star = 4,
            Comment = " 讲课很清晰 "
        };

        TeacherCommentModel? captured = null;
        _mockRepo
            .Setup(r => r.CreateAsync(It.IsAny<TeacherCommentModel>()))
            .Callback<TeacherCommentModel>(m => captured = m)
            .Returns(Task.CompletedTask);

        var result = await _service.CreateAsync(StudentId, "小明", request);

        Assert.Multiple(() =>
        {
            Assert.That(result.TeacherName, Is.EqualTo("张老师")); // Trim 验证
            Assert.That(result.CourseName, Is.EqualTo("高等数学"));
            Assert.That(result.Comment, Is.EqualTo("讲课很清晰"));
            Assert.That(result.Star, Is.EqualTo(4));
            Assert.That(result.Status, Is.EqualTo(CommentReviewStatus.Pending));
            Assert.That(result.AiVerdict, Is.EqualTo(AiReviewVerdict.None));
        });
        // 验证传入仓库的模型字段
        Assert.Multiple(() =>
        {
            Assert.That(captured!.StudentId, Is.EqualTo(StudentId));
            Assert.That(captured.StudentName, Is.EqualTo("小明"));
            Assert.That(captured.TeacherId, Is.EqualTo("T001"));
            Assert.That(captured.Status, Is.EqualTo(CommentReviewStatus.Pending));
        });
        _mockRepo.Verify(r => r.CreateAsync(It.IsAny<TeacherCommentModel>()), Times.Once);
    }

    [TestCase("", "高数", 5, Description = "教师姓名为空")]
    [TestCase(" ", "高数", 5, Description = "教师姓名为空白")]
    public void CreateAsync_WhenTeacherNameEmpty_ShouldThrow(string teacherName, string courseName, int star)
    {
        var request = new CreateTeacherCommentRequest { TeacherName = teacherName, CourseName = courseName, Star = star };

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.CreateAsync(StudentId, null, request));

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
            await _service.CreateAsync(StudentId, null, request));

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
            await _service.CreateAsync(StudentId, null, request));

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
            await _service.CreateAsync(StudentId, null, request));

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

        var result = await _service.CreateAsync(StudentId, null, request);

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
            .Setup(r => r.QueryAsync("张", "高数", CommentReviewStatus.Approved, 4, 1, 20))
            .ReturnsAsync((new List<TeacherCommentModel>(), 0));

        await _service.QueryAsync(new TeacherCommentQueryRequest
        {
            TeacherName = "张",
            CourseName = "高数",
            Status = CommentReviewStatus.Approved,
            MinStar = 4
        });

        _mockRepo.Verify(r => r.QueryAsync("张", "高数", CommentReviewStatus.Approved, 4, 1, 20), Times.Once);
    }

    // ==================== ReviewAsync ====================

    [Test]
    public async Task ReviewAsync_WhenApproved_ShouldUpdateStatusAndReviewer()
    {
        var model = new TeacherCommentModel { Key = "k1", Status = CommentReviewStatus.Pending };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        var result = await _service.ReviewAsync("k1", AdminId, new ReviewTeacherCommentRequest { Status = CommentReviewStatus.Approved, ReviewNote = "ok" });

        Assert.Multiple(() =>
        {
            Assert.That(result.Status, Is.EqualTo(CommentReviewStatus.Approved));
            Assert.That(model.ReviewedBy, Is.EqualTo(AdminId));
            Assert.That(model.ReviewedOn, Is.Not.Null);
        });
        _mockRepo.Verify(r => r.UpdateAsync(model), Times.Once);
    }

    [Test]
    public async Task ReviewAsync_WhenRejected_ShouldUpdateStatus()
    {
        var model = new TeacherCommentModel { Key = "k1", Status = CommentReviewStatus.Pending };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        var result = await _service.ReviewAsync("k1", AdminId, new ReviewTeacherCommentRequest { Status = CommentReviewStatus.Rejected });

        Assert.That(result.Status, Is.EqualTo(CommentReviewStatus.Rejected));
    }

    [Test]
    public void ReviewAsync_WithPendingStatus_ShouldThrow()
    {
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(new TeacherCommentModel { Key = "k1" });

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.ReviewAsync("k1", AdminId, new ReviewTeacherCommentRequest { Status = CommentReviewStatus.Pending }));

        Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.InvalidStatusForOperation));
        _mockRepo.Verify(r => r.UpdateAsync(It.IsAny<TeacherCommentModel>()), Times.Never);
    }

    [Test]
    public void ReviewAsync_WhenNotFound_ShouldThrow()
    {
        _mockRepo.Setup(r => r.GetByKeyAsync("missing")).ReturnsAsync((TeacherCommentModel?)null);

        var ex = Assert.ThrowsAsync<ResourceAccessException>(async () =>
            await _service.ReviewAsync("missing", AdminId, new ReviewTeacherCommentRequest { Status = CommentReviewStatus.Approved }));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.CommentNotFound));
            Assert.That(ex.ResourceName, Is.EqualTo("TeacherComment"));
            Assert.That(ex.ResourceId, Is.EqualTo("missing"));
        });
    }

    [Test]
    public void ReviewAsync_WhenAlreadyReviewed_ShouldThrow()
    {
        var model = new TeacherCommentModel { Key = "k1", Status = CommentReviewStatus.Approved };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.ReviewAsync("k1", AdminId, new ReviewTeacherCommentRequest { Status = CommentReviewStatus.Rejected }));

        Assert.Multiple(() =>
        {
            Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.InvalidStatusForOperation));
            Assert.That(ex.Message, Does.Contain("重复审核"));
        });
        _mockRepo.Verify(r => r.UpdateAsync(It.IsAny<TeacherCommentModel>()), Times.Never);
    }

    // ==================== DeleteAsync ====================

    [Test]
    public async Task DeleteAsync_WhenOwner_ShouldDelete()
    {
        var model = new TeacherCommentModel { Key = "k1", StudentId = StudentId };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        await _service.DeleteAsync("k1", StudentId);

        _mockRepo.Verify(r => r.DeleteAsync(model), Times.Once);
    }

    [Test]
    public void DeleteAsync_WhenNotOwner_ShouldThrowPermissionError()
    {
        var model = new TeacherCommentModel { Key = "k1", StudentId = "other_user" };
        _mockRepo.Setup(r => r.GetByKeyAsync("k1")).ReturnsAsync(model);

        var ex = Assert.ThrowsAsync<BusinessException>(async () =>
            await _service.DeleteAsync("k1", StudentId));

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
            await _service.DeleteAsync("missing", StudentId));

        Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.CommentNotFound));
    }

    // ==================== GetSummaryAsync ====================

    [Test]
    public async Task GetSummaryAsync_ShouldCalculateAverageAndCourses()
    {
        var comments = new List<TeacherCommentModel>
        {
            new() { TeacherName = "张老师", TeacherId = "T001", CourseName = "高数", Star = 4, Status = CommentReviewStatus.Approved },
            new() { TeacherName = "张老师", TeacherId = "T001", CourseName = "线代", Star = 5, Status = CommentReviewStatus.Approved },
            new() { TeacherName = "张老师", TeacherId = "T001", CourseName = "高数", Star = 3, Status = CommentReviewStatus.Approved }
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
    public async Task GetSummaryAsync_WithTeacherId_ShouldFilterByTeacherId()
    {
        var comments = new List<TeacherCommentModel>
        {
            new() { TeacherName = "张老师", TeacherId = "T001", CourseName = "高数", Star = 5, Status = CommentReviewStatus.Approved },
            new() { TeacherName = "张老师", TeacherId = "T002", CourseName = "线代", Star = 1, Status = CommentReviewStatus.Approved }
        };
        _mockRepo.Setup(r => r.GetApprovedByTeacherNameAsync("张老师")).ReturnsAsync(comments);

        var summary = await _service.GetSummaryAsync("张老师", "T001");

        Assert.Multiple(() =>
        {
            Assert.That(summary.TotalCount, Is.EqualTo(1));
            Assert.That(summary.AverageStar, Is.EqualTo(5.0));
            Assert.That(summary.TeacherId, Is.EqualTo("T001"));
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
            new() { Key = "k1", TeacherName = "张老师", Status = CommentReviewStatus.Approved }
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
            new() { Key = "k1", Status = CommentReviewStatus.Pending },
            new() { Key = "k2", Status = CommentReviewStatus.Pending }
        };
        _mockRepo.Setup(r => r.GetPendingAsync()).ReturnsAsync(pending);

        var result = await _service.GetPendingListAsync();

        Assert.That(result.Count, Is.EqualTo(2));
    }

    // ==================== GetMyCommentsAsync ====================

    [Test]
    public async Task GetMyCommentsAsync_ShouldReturnStudentComments()
    {
        var mine = new List<TeacherCommentModel>
        {
            new() { Key = "k1", StudentId = StudentId },
            new() { Key = "k2", StudentId = StudentId }
        };
        _mockRepo.Setup(r => r.GetByStudentIdAsync(StudentId)).ReturnsAsync(mine);

        var result = await _service.GetMyCommentsAsync(StudentId);

        Assert.That(result.Count, Is.EqualTo(2));
        _mockRepo.Verify(r => r.GetByStudentIdAsync(StudentId), Times.Once);
    }
}
