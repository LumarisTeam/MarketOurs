using FluentValidation;
using MarketOurs.Data.DTOs;

namespace MarketOurs.WebAPI.Validators;

public class PostCreateDtoValidator : AbstractValidator<PostCreateDto>
{
    public PostCreateDtoValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("标题不能为空")
            .MaximumLength(128).WithMessage("标题长度不能超过128位");

        RuleFor(x => x.Content)
            .MaximumLength(1024).WithMessage("内容长度不能超过1024位");

        RuleFor(x => x)
            .Must(HasContentOrImage)
            .WithMessage("帖子内容和图片不能同时为空");

        RuleFor(x => x.UserId)
            .NotEmpty().WithMessage("用户ID不能为空")
            .MaximumLength(64).WithMessage("用户ID长度不能超过64位");
    }

    private static bool HasContentOrImage(PostCreateDto dto)
    {
        return !string.IsNullOrWhiteSpace(dto.Content) ||
               (dto.Images != null && dto.Images.Any(image => !string.IsNullOrWhiteSpace(image)));
    }
}

public class PostUpdateDtoValidator : AbstractValidator<PostUpdateDto>
{
    public PostUpdateDtoValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("标题不能为空")
            .MaximumLength(128).WithMessage("标题长度不能超过128位");

        RuleFor(x => x.Content)
            .MaximumLength(1024).WithMessage("内容长度不能超过1024位");

        RuleFor(x => x)
            .Must(HasContentOrImage)
            .WithMessage("帖子内容和图片不能同时为空");
    }

    private static bool HasContentOrImage(PostUpdateDto dto)
    {
        return !string.IsNullOrWhiteSpace(dto.Content) ||
               (dto.Images != null && dto.Images.Any(image => !string.IsNullOrWhiteSpace(image)));
    }
}
