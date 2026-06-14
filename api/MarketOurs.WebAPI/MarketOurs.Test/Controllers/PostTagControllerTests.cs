using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Exceptions;
using MarketOurs.DataAPI.Services;
using MarketOurs.WebAPI.Controllers;
using Moq;

namespace MarketOurs.Test.Controllers;

[TestFixture]
public class PostTagControllerTests : ControllerTestBase
{
    private Mock<IPostTagService> _mockPostTagService;
    private PostTagController _controller;

    [SetUp]
    public void Setup()
    {
        _mockPostTagService = new Mock<IPostTagService>();
        _controller = new PostTagController(_mockPostTagService.Object);
        SetupUser(_controller, "admin-1", "Admin");
    }

    [Test]
    public async Task GetById_WhenTagExists_ShouldReturnTag()
    {
        var tag = new PostTagDto { Id = "tag-1", Name = "二手闲置", IsActive = true };
        _mockPostTagService.Setup(s => s.GetByIdAsync("tag-1")).ReturnsAsync(tag);

        var result = await _controller.GetById("tag-1");

        Assert.That(result.Code, Is.EqualTo(200));
        Assert.That(result.Data, Is.Not.Null);
        Assert.That(result.Data!.Id, Is.EqualTo("tag-1"));
        Assert.That(result.Data.Name, Is.EqualTo("二手闲置"));
    }

    [Test]
    public void GetById_WhenTagMissing_ShouldThrowNotFound()
    {
        _mockPostTagService.Setup(s => s.GetByIdAsync("missing")).ReturnsAsync((PostTagDto?)null);

        var ex = Assert.ThrowsAsync<ResourceAccessException>(async () => await _controller.GetById("missing"));

        Assert.That(ex!.HttpStatusCode, Is.EqualTo(404));
        Assert.That(ex.ResourceName, Is.EqualTo("PostTag"));
    }
}
