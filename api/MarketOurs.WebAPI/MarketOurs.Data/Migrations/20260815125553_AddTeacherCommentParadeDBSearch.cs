using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddTeacherCommentParadeDBSearch : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ParadeDB 全文索引仅适用于 PostgreSQL；SQLite 本地开发跳过
            if (migrationBuilder.ActiveProvider != "Npgsql.EntityFrameworkCore.PostgreSQL")
            {
                return;
            }

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:pg_search", ",,");

            migrationBuilder.CreateIndex(
                name: "teacher_comments_search_idx",
                table: "teacher_comments",
                column: "Key")
                .Annotation("ParadeDB:IndexFields", new[] { "\"Key\"", "(\"TeacherName\"::pdb.chinese_compatible)", "(\"CourseName\"::pdb.chinese_compatible)", "\"IsReview\"", "\"CreatedOn\"" })
                .Annotation("ParadeDB:IndexKeyField", "Key");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            if (migrationBuilder.ActiveProvider != "Npgsql.EntityFrameworkCore.PostgreSQL")
            {
                return;
            }

            migrationBuilder.DropIndex(
                name: "teacher_comments_search_idx",
                table: "teacher_comments");

            migrationBuilder.AlterDatabase()
                .OldAnnotation("Npgsql:PostgresExtension:pg_search", ",,");
        }
    }
}
