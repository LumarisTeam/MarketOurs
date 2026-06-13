using MarketOurs.Data.DTOs;
using MarketOurs.WebAPI.Validators;

namespace MarketOurs.Test.Validators;

[TestFixture]
public class CommentValidatorTests
{
    private CommentCreateDtoValidator _createValidator = null!;
    private CommentUpdateDtoValidator _updateValidator = null!;

    [SetUp]
    public void Setup()
    {
        _createValidator = new CommentCreateDtoValidator();
        _updateValidator = new CommentUpdateDtoValidator();
    }

    [Test]
    public void CreateValidator_WithTextOnly_ShouldPass()
    {
        var result = _createValidator.Validate(ValidCreate(content: "这是一条评论"));

        Assert.That(result.IsValid, Is.True);
    }

    [Test]
    public void CreateValidator_WithImageOnly_ShouldPass()
    {
        var result = _createValidator.Validate(ValidCreate(content: "", images: ["https://blob.example/comment.webp"]));

        Assert.That(result.IsValid, Is.True);
    }

    [Test]
    public void CreateValidator_WithTextAndImages_ShouldPass()
    {
        var result = _createValidator.Validate(ValidCreate(images: ["/uploads/comments/1.webp"]));

        Assert.That(result.IsValid, Is.True);
    }

    [Test]
    public void CreateValidator_WithNoTextAndNoImages_ShouldFail()
    {
        var result = _createValidator.Validate(ValidCreate(content: " ", images: []));

        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors.Any(e => e.ErrorMessage == "评论内容和图片不能同时为空"), Is.True);
    }

    [Test]
    public void CreateValidator_WithMoreThanThreeImages_ShouldFail()
    {
        var result = _createValidator.Validate(ValidCreate(images:
        [
            "https://blob.example/1.webp",
            "https://blob.example/2.webp",
            "https://blob.example/3.webp",
            "https://blob.example/4.webp"
        ]));

        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors.Any(e => e.ErrorMessage == "评论图片不能超过3张"), Is.True);
    }

    [Test]
    public void CreateValidator_WithEmptyImageUrl_ShouldFail()
    {
        var result = _createValidator.Validate(ValidCreate(images: [""]));

        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors.Any(e => e.ErrorMessage == "评论图片地址不能为空"), Is.True);
    }

    [Test]
    public void UpdateValidator_WithImageOnly_ShouldPass()
    {
        var result = _updateValidator.Validate(new CommentUpdateDto
        {
            Content = "",
            Images = ["https://blob.example/comment.webp"]
        });

        Assert.That(result.IsValid, Is.True);
    }

    private static CommentCreateDto ValidCreate(string content = "评论", List<string>? images = null)
    {
        return new CommentCreateDto
        {
            Content = content,
            Images = images ?? [],
            UserId = "user_1",
            PostId = "post_1"
        };
    }
}
