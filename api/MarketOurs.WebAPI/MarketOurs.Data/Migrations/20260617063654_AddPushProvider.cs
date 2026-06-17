using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPushProvider : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PushProvider",
                table: "users",
                type: "character varying(32)",
                maxLength: 32,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PushProvider",
                table: "users");
        }
    }
}
