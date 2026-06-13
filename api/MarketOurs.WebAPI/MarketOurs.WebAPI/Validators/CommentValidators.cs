using FluentValidation;
using MarketOurs.Data.DTOs;

namespace MarketOurs.WebAPI.Validators;

public class CommentCreateDtoValidator : AbstractValidator<CommentCreateDto>
{
    private const int MaxCommentImages = 3;

    public CommentCreateDtoValidator()
    {
        RuleFor(x => x.Content)
            .MaximumLength(512).WithMessage("评论内容长度不能超过512位");

        RuleFor(x => x)
            .Must(HasContentOrImage)
            .WithMessage("评论内容和图片不能同时为空");

        RuleFor(x => x.Images)
            .Must(images => images == null || images.Count <= MaxCommentImages)
            .WithMessage($"评论图片不能超过{MaxCommentImages}张");

        RuleForEach(x => x.Images)
            .NotEmpty().WithMessage("评论图片地址不能为空")
            .Must(IsAllowedImageUrl).WithMessage("评论图片地址格式不正确");

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("用户ID不能为空")
            .MaximumLength(64).WithMessage("用户ID长度不能超过64位");

        RuleFor(x => x.PostId)
            .NotEmpty().WithMessage("贴子ID不能为空")
            .MaximumLength(64).WithMessage("贴子ID长度不能超过64位");

        RuleFor(x => x.ParentCommentId)
            .MaximumLength(64).WithMessage("父评论ID长度不能超过64位");
    }

    internal static bool HasContentOrImage(CommentCreateDto dto)
    {
        return !string.IsNullOrWhiteSpace(dto.Content) ||
               (dto.Images != null && dto.Images.Any(image => !string.IsNullOrWhiteSpace(image)));
    }

    internal static bool IsAllowedImageUrl(string? url)
    {
        if (string.IsNullOrWhiteSpace(url)) return false;
        return url.StartsWith("/uploads/", StringComparison.OrdinalIgnoreCase)
               || Uri.TryCreate(url, UriKind.Absolute, out var uri)
               && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);
    }
}

public class CommentUpdateDtoValidator : AbstractValidator<CommentUpdateDto>
{
    private const int MaxCommentImages = 3;

    public CommentUpdateDtoValidator()
    {
        RuleFor(x => x.Content)
            .MaximumLength(512).WithMessage("评论内容长度不能超过512位");

        RuleFor(x => x)
            .Must(HasContentOrImage)
            .WithMessage("评论内容和图片不能同时为空");

        RuleFor(x => x.Images)
            .Must(images => images == null || images.Count <= MaxCommentImages)
            .WithMessage($"评论图片不能超过{MaxCommentImages}张");

        RuleForEach(x => x.Images)
            .NotEmpty().WithMessage("评论图片地址不能为空")
            .Must(CommentCreateDtoValidator.IsAllowedImageUrl).WithMessage("评论图片地址格式不正确");
    }

    private static bool HasContentOrImage(CommentUpdateDto dto)
    {
        return !string.IsNullOrWhiteSpace(dto.Content) ||
               (dto.Images != null && dto.Images.Any(image => !string.IsNullOrWhiteSpace(image)));
    }
}
