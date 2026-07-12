using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddReports : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "reports",
                columns: table => new
                {
                    Id = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    TargetType = table.Column<int>(type: "integer", nullable: false),
                    TargetId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    ReporterUserId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    ReporterName = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    TargetSummary = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: false),
                    Reason = table.Column<int>(type: "integer", nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    ReviewedByUserId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    ResolutionNote = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    ReviewedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_reports", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_reports_ReporterUserId_TargetType_TargetId",
                table: "reports",
                columns: new[] { "ReporterUserId", "TargetType", "TargetId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_reports_Status_CreatedAt",
                table: "reports",
                columns: new[] { "Status", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "reports");
        }
    }
}
