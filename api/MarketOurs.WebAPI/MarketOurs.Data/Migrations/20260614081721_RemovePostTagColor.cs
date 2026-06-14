using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class RemovePostTagColor : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Color",
                table: "post_tags");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Color",
                table: "post_tags",
                type: "character varying(32)",
                maxLength: 32,
                nullable: false,
                defaultValue: "");
        }
    }
}
