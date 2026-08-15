using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddReviewAuditFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_teacher_comments_Status",
                table: "teacher_comments");

            migrationBuilder.DropIndex(
                name: "IX_teacher_comments_TeacherName_Status",
                table: "teacher_comments");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "teacher_comments");

            migrationBuilder.AddColumn<bool>(
                name: "IsReview",
                table: "teacher_comments",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "AiReason",
                table: "posts",
                type: "character varying(1024)",
                maxLength: 1024,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "AiReviewedOn",
                table: "posts",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReviewedBy",
                table: "posts",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReviewedOn",
                table: "posts",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AiReason",
                table: "comments",
                type: "character varying(1024)",
                maxLength: 1024,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "AiReviewedOn",
                table: "comments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReviewedBy",
                table: "comments",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReviewedOn",
                table: "comments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_IsReview",
                table: "teacher_comments",
                column: "IsReview");

            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_TeacherName_IsReview",
                table: "teacher_comments",
                columns: new[] { "TeacherName", "IsReview" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_teacher_comments_IsReview",
                table: "teacher_comments");

            migrationBuilder.DropIndex(
                name: "IX_teacher_comments_TeacherName_IsReview",
                table: "teacher_comments");

            migrationBuilder.DropColumn(
                name: "IsReview",
                table: "teacher_comments");

            migrationBuilder.DropColumn(
                name: "AiReason",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "AiReviewedOn",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "ReviewedBy",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "ReviewedOn",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "AiReason",
                table: "comments");

            migrationBuilder.DropColumn(
                name: "AiReviewedOn",
                table: "comments");

            migrationBuilder.DropColumn(
                name: "ReviewedBy",
                table: "comments");

            migrationBuilder.DropColumn(
                name: "ReviewedOn",
                table: "comments");

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "teacher_comments",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_Status",
                table: "teacher_comments",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_teacher_comments_TeacherName_Status",
                table: "teacher_comments",
                columns: new[] { "TeacherName", "Status" });
        }
    }
}
