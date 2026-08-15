using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarketOurs.WebAPI.Controllers;

/// <summary>
/// 教师评价接口 —— 校园集市
/// </summary>
[ApiController, Route("[controller]")]
public class TeacherCommentController(ITeacherCommentService commentService) : ControllerBase
{
    /// <summary>
    /// 提交教师评价
    /// </summary>
    [HttpPost, Authorize]
    public async Task<ApiResponse<TeacherCommentItem>> Create([FromBody] CreateTeacherCommentRequest request) =>
        ApiResponse<TeacherCommentItem>.Success(
            await commentService.CreateAsync(this.GetRequiredUserId(), request), "评价已提交");

    /// <summary>
    /// 分页查询评价列表（管理员接口）
    /// </summary>
    [HttpGet("admin/list"), Authorize(Roles = "Admin")]
    public async Task<ApiResponse<PagedResultDto<TeacherCommentItem>>> AdminList(
        [FromQuery] TeacherCommentQueryRequest request) =>
        ApiResponse<PagedResultDto<TeacherCommentItem>>.Success(await commentService.QueryAsync(request));

    /// <summary>
    /// 获取待审核评价列表（管理员接口）
    /// </summary>
    [HttpGet("admin/pending"), Authorize(Roles = "Admin")]
    public async Task<ApiResponse<List<TeacherCommentItem>>> AdminPending() =>
        ApiResponse<List<TeacherCommentItem>>.Success(await commentService.GetPendingListAsync());

    /// <summary>
    /// 审核评价（管理员接口）
    /// </summary>
    [HttpPut("admin/review/{key}"), Authorize(Roles = "Admin")]
    public async Task<ApiResponse<TeacherCommentItem>> AdminReview(
        string key, [FromBody] ReviewTeacherCommentRequest request) =>
        ApiResponse<TeacherCommentItem>.Success(
            await commentService.ReviewAsync(key, this.GetRequiredUserId(), request), "审核完成");

    /// <summary>
    /// 获取我的评价列表
    /// </summary>
    [HttpGet("mine"), Authorize]
    public async Task<ApiResponse<List<TeacherCommentItem>>> MyComments() =>
        ApiResponse<List<TeacherCommentItem>>.Success(
            await commentService.GetMyCommentsAsync(this.GetRequiredUserId()));

    /// <summary>
    /// 搜索已通过评价（公开接口，可按教师或课程搜索）
    /// </summary>
    [HttpGet("search")]
    public async Task<ApiResponse<PagedResultDto<TeacherCommentItem>>> SearchApproved(
        [FromQuery] string? keyword, [FromQuery] int page = 1, [FromQuery] int pageSize = 20) =>
        ApiResponse<PagedResultDto<TeacherCommentItem>>.Success(
            await commentService.SearchApprovedAsync(keyword, page, pageSize));

    /// <summary>
    /// 删除我的评价
    /// </summary>
    [HttpDelete("{key}"), Authorize]
    public async Task<ApiResponse> Delete(string key)
    {
        await commentService.DeleteAsync(key, this.GetRequiredUserId());
        return ApiResponse.Success("评价已删除");
    }

    /// <summary>
    /// 查询指定教师的已通过评价（公开接口）
    /// </summary>
    [HttpGet("teacher/{teacherName}")]
    public async Task<ApiResponse<List<TeacherCommentItem>>> GetByTeacher(string teacherName) =>
        ApiResponse<List<TeacherCommentItem>>.Success(
            await commentService.GetApprovedByTeacherAsync(teacherName));

    /// <summary>
    /// 获取教师评价汇总（公开接口）
    /// </summary>
    [HttpGet("summary")]
    public async Task<ApiResponse<TeacherCommentSummary>> GetSummary([FromQuery] string teacherName) =>
        ApiResponse<TeacherCommentSummary>.Success(
            await commentService.GetSummaryAsync(teacherName));
}
