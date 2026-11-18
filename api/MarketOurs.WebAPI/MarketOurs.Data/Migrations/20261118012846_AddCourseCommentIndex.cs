using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddCourseCommentIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_CourseName_IsReview_CreatedOn",
                table: "teacher_comments",
                columns: new[] { "CourseName", "IsReview", "CreatedOn" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_teacher_comments_CourseName_IsReview_CreatedOn",
                table: "teacher_comments");
        }
    }
}
