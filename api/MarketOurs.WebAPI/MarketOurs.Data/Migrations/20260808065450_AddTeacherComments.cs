using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddTeacherComments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "teacher_comments",
                columns: table => new
                {
                    Key = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    TeacherName = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    TeacherId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    CourseName = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    StudentId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    StudentName = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    Comment = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    Star = table.Column<int>(type: "integer", nullable: false, defaultValue: 5),
                    Status = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    AiVerdict = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    AiReason = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: true),
                    AiScore = table.Column<int>(type: "integer", nullable: true),
                    AiReviewedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ReviewedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ReviewedBy = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_teacher_comments", x => x.Key);
                });

            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_Status",
                table: "teacher_comments",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_StudentId",
                table: "teacher_comments",
                column: "StudentId");

            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_TeacherName",
                table: "teacher_comments",
                column: "TeacherName");

            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_TeacherName_Status",
                table: "teacher_comments",
                columns: new[] { "TeacherName", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "teacher_comments");
        }
    }
}
