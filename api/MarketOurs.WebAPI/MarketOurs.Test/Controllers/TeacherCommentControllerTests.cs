using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Exceptions;
using MarketOurs.DataAPI.Services;
using MarketOurs.WebAPI.Controllers;
using Microsoft.Extensions.Logging;
using Moq;

namespace MarketOurs.Test.Controllers;

/// <summary>
/// 教师评价控制器层测试 —— 校园集市
/// 覆盖 8 个接口的权限校验、参数透传与响应封装。
/// </summary>
[TestFixture]
public class TeacherCommentControllerTests : ControllerTestBase
{
    private Mock<ITeacherCommentService> _mockService = null!;
    private TeacherCommentController _controller = null!;

    private const string UserId = "student_001";
    private const string AdminId = "admin_001";

    [SetUp]
    public void Setup()
    {
        _mockService = new Mock<ITeacherCommentService>();
        _controller = new TeacherCommentController(_mockService.Object);
        SetupUser(_controller, UserId);
    }

    // ---------- Create ----------

    [Test]
    public async Task Create_ShouldPassUserIdAndReturnSuccess()
    {
        var request = new CreateTeacherCommentRequest
        {
            TeacherName = "张老师",
            CourseName = "高等数学",
            Star = 5,
            Comment = "讲课清晰"
        };
        var item = new TeacherCommentItem { Key = "k1", TeacherName = "张老师", Star = 5 };

        _mockService
            .Setup(s => s.CreateAsync(UserId, null, It.Is<CreateTeacherCommentRequest>(r => r.TeacherName == "张老师")))
            .ReturnsAsync(item);

        var result = await _controller.Create(request);

        Assert.Multiple(() =>
        {
            Assert.That(result.Code, Is.EqualTo(200));
            Assert.That(result.Data!.Key, Is.EqualTo("k1"));
            Assert.That(result.Message, Is.EqualTo("评价已提交"));
        });
        _mockService.Verify(s => s.CreateAsync(UserId, null, request), Times.Once);
    }

    [Test]
    public void Create_WhenNotAuthenticated_ShouldThrowAuthException()
    {
        // 模拟匿名请求：有 HttpContext 但用户无 NameIdentifier claim
        _controller.ControllerContext = new Microsoft.AspNetCore.Mvc.ControllerContext
        {
            HttpContext = new Microsoft.AspNetCore.Http.DefaultHttpContext()
        };

        var ex = Assert.ThrowsAsync<AuthException>(async () =>
            await _controller.Create(new CreateTeacherCommentRequest { TeacherName = "张老师", CourseName = "数学" }));

        Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.Unauthorized));
        _mockService.Verify(s => s.CreateAsync(It.IsAny<string>(), It.IsAny<string?>(), It.IsAny<CreateTeacherCommentRequest>()), Times.Never);
    }

    // ---------- AdminList ----------

    [Test]
    public async Task AdminList_WhenAdmin_ShouldReturnPagedResult()
    {
        SetupUser(_controller, AdminId, "Admin");
        var paged = PagedResultDto<TeacherCommentItem>.Success(
            new List<TeacherCommentItem> { new() { Key = "k1" } }, 1, 1, 20);

        _mockService.Setup(s => s.QueryAsync(It.IsAny<TeacherCommentQueryRequest>())).ReturnsAsync(paged);

        var result = await _controller.AdminList(new TeacherCommentQueryRequest());

        Assert.Multiple(() =>
        {
            Assert.That(result.Code, Is.EqualTo(200));
            Assert.That(result.Data!.Items.Count, Is.EqualTo(1));
            Assert.That(result.Data.TotalCount, Is.EqualTo(1));
        });
    }

    // ---------- AdminPending ----------

    [Test]
    public async Task AdminPending_WhenAdmin_ShouldReturnPendingList()
    {
        SetupUser(_controller, AdminId, "Admin");
        var pending = new List<TeacherCommentItem> { new() { Key = "k1", Status = CommentReviewStatus.Pending } };

        _mockService.Setup(s => s.GetPendingListAsync()).ReturnsAsync(pending);

        var result = await _controller.AdminPending();

        Assert.Multiple(() =>
        {
            Assert.That(result.Code, Is.EqualTo(200));
            Assert.That(result.Data!.Count, Is.EqualTo(1));
        });
    }

    // ---------- AdminReview ----------

    [Test]
    public async Task AdminReview_WhenAdmin_ShouldPassKeyAndAdminId()
    {
        SetupUser(_controller, AdminId, "Admin");
        var reviewed = new TeacherCommentItem { Key = "k1", Status = CommentReviewStatus.Approved };

        _mockService
            .Setup(s => s.ReviewAsync("k1", AdminId, It.IsAny<ReviewTeacherCommentRequest>()))
            .ReturnsAsync(reviewed);

        var result = await _controller.AdminReview("k1", new ReviewTeacherCommentRequest { Status = CommentReviewStatus.Approved });

        Assert.Multiple(() =>
        {
            Assert.That(result.Code, Is.EqualTo(200));
            Assert.That(result.Data!.Status, Is.EqualTo(CommentReviewStatus.Approved));
            Assert.That(result.Message, Is.EqualTo("审核完成"));
        });
        _mockService.Verify(
            s => s.ReviewAsync("k1", AdminId, It.Is<ReviewTeacherCommentRequest>(r => r.Status == CommentReviewStatus.Approved)),
            Times.Once);
    }

    // ---------- MyComments ----------

    [Test]
    public async Task MyComments_ShouldReturnCurrentUserComments()
    {
        var mine = new List<TeacherCommentItem> { new() { Key = "k1" }, new() { Key = "k2" } };

        _mockService.Setup(s => s.GetMyCommentsAsync(UserId)).ReturnsAsync(mine);

        var result = await _controller.MyComments();

        Assert.Multiple(() =>
        {
            Assert.That(result.Code, Is.EqualTo(200));
            Assert.That(result.Data!.Count, Is.EqualTo(2));
        });
        _mockService.Verify(s => s.GetMyCommentsAsync(UserId), Times.Once);
    }

    // ---------- Delete ----------

    [Test]
    public async Task Delete_ShouldPassKeyAndUserId()
    {
        _mockService.Setup(s => s.DeleteAsync("k1", UserId)).Returns(Task.CompletedTask);

        var result = await _controller.Delete("k1");

        Assert.Multiple(() =>
        {
            Assert.That(result.Code, Is.EqualTo(200));
            Assert.That(result.Message, Is.EqualTo("评价已删除"));
        });
        _mockService.Verify(s => s.DeleteAsync("k1", UserId), Times.Once);
    }

    [Test]
    public void Delete_WhenServiceThrowsPermissionError_ShouldPropagate()
    {
        _mockService
            .Setup(s => s.DeleteAsync("k1", UserId))
            .ThrowsAsync(new BusinessException(ErrorCode.InsufficientPermission, "无权删除他人的评价", 403, null));

        var ex = Assert.ThrowsAsync<BusinessException>(async () => await _controller.Delete("k1"));

        Assert.That(ex!.ErrorCode, Is.EqualTo(ErrorCode.InsufficientPermission));
    }

    // ---------- GetByTeacher (公开) ----------

    [Test]
    public async Task GetByTeacher_ShouldReturnApprovedList()
    {
        var list = new List<TeacherCommentItem> { new() { Key = "k1", TeacherName = "张老师" } };

        _mockService.Setup(s => s.GetApprovedByTeacherAsync("张老师")).ReturnsAsync(list);

        var result = await _controller.GetByTeacher("张老师");

        Assert.Multiple(() =>
        {
            Assert.That(result.Code, Is.EqualTo(200));
            Assert.That(result.Data!.Count, Is.EqualTo(1));
        });
        _mockService.Verify(s => s.GetApprovedByTeacherAsync("张老师"), Times.Once);
    }

    // ---------- GetSummary (公开) ----------

    [Test]
    public async Task GetSummary_ShouldReturnSummaryWithTeacherNameAndId()
    {
        var summary = new TeacherCommentSummary
        {
            TeacherName = "张老师",
            TeacherId = "T001",
            TotalCount = 10,
            AverageStar = 4.5,
            Courses = new List<string> { "高数", "线代" }
        };

        _mockService.Setup(s => s.GetSummaryAsync("张老师", "T001")).ReturnsAsync(summary);

        var result = await _controller.GetSummary("张老师", "T001");

        Assert.Multiple(() =>
        {
            Assert.That(result.Code, Is.EqualTo(200));
            Assert.That(result.Data!.TotalCount, Is.EqualTo(10));
            Assert.That(result.Data.AverageStar, Is.EqualTo(4.5));
        });
    }

    [Test]
    public async Task GetSummary_WithoutTeacherId_ShouldPassNull()
    {
        var summary = new TeacherCommentSummary { TeacherName = "张老师" };

        _mockService.Setup(s => s.GetSummaryAsync("张老师", null)).ReturnsAsync(summary);

        var result = await _controller.GetSummary("张老师");

        Assert.That(result.Code, Is.EqualTo(200));
        _mockService.Verify(s => s.GetSummaryAsync("张老师", null), Times.Once);
    }
}
