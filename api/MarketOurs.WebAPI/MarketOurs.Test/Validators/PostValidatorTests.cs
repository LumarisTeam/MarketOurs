using MarketOurs.Data.DTOs;
using MarketOurs.WebAPI.Validators;

namespace MarketOurs.Test.Validators;

[TestFixture]
public class PostValidatorTests
{
    private PostCreateDtoValidator _createValidator = null!;
    private PostUpdateDtoValidator _updateValidator = null!;

    [SetUp]
    public void Setup()
    {
        _createValidator = new PostCreateDtoValidator();
        _updateValidator = new PostUpdateDtoValidator();
    }

    [Test]
    public void CreateValidator_WithTextOnly_ShouldPass()
    {
        var result = _createValidator.Validate(Create(content: "正文"));

        Assert.That(result.IsValid, Is.True);
    }

    [Test]
    public void CreateValidator_WithImageOnly_ShouldPass()
    {
        var result = _createValidator.Validate(Create(content: "", images: ["https://blob.example/post.webp"]));

        Assert.That(result.IsValid, Is.True);
    }

    [Test]
    public void CreateValidator_WithNoTextAndNoImages_ShouldFail()
    {
        var result = _createValidator.Validate(Create(content: " "));

        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors.Any(e => e.ErrorMessage == "帖子内容和图片不能同时为空"), Is.True);
    }

    [Test]
    public void CreateValidator_WithContentTooLong_ShouldFail()
    {
        var result = _createValidator.Validate(Create(content: new string('a', 1025)));

        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors.Any(e => e.ErrorMessage == "内容长度不能超过1024位"), Is.True);
    }

    [Test]
    public void UpdateValidator_WithImageOnly_ShouldPass()
    {
        var result = _updateValidator.Validate(new PostUpdateDto
        {
            Title = "标题",
            Content = "",
            Images = ["https://blob.example/post.webp"]
        });

        Assert.That(result.IsValid, Is.True);
    }

    [Test]
    public void UpdateValidator_WithNoTextAndNoImages_ShouldFail()
    {
        var result = _updateValidator.Validate(new PostUpdateDto
        {
            Title = "标题",
            Content = " ",
            Images = []
        });

        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors.Any(e => e.ErrorMessage == "帖子内容和图片不能同时为空"), Is.True);
    }

    private static PostCreateDto Create(string content = "正文", List<string>? images = null)
    {
        return new PostCreateDto
        {
            Title = "标题",
            Content = content,
            Images = images ?? [],
            UserId = "user_1"
        };
    }
}
