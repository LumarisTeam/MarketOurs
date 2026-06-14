using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddReadPathPerfIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_posts_UserId",
                table: "posts");

            migrationBuilder.CreateIndex(
                name: "IX_posts_IsReview_TagId_CreatedAt",
                table: "posts",
                columns: new[] { "IsReview", "TagId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_posts_UserId_CreatedAt",
                table: "posts",
                columns: new[] { "UserId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_comments_PostId_IsReview",
                table: "comments",
                columns: new[] { "PostId", "IsReview" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_posts_IsReview_TagId_CreatedAt",
                table: "posts");

            migrationBuilder.DropIndex(
                name: "IX_posts_UserId_CreatedAt",
                table: "posts");

            migrationBuilder.DropIndex(
                name: "IX_comments_PostId_IsReview",
                table: "comments");

            migrationBuilder.CreateIndex(
                name: "IX_posts_UserId",
                table: "posts",
                column: "UserId");
        }
    }
}
