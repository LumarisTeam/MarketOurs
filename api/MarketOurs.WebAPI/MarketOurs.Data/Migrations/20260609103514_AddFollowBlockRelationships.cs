using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddFollowBlockRelationships : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "user_blocks",
                columns: table => new
                {
                    BlockedById = table.Column<string>(type: "character varying(64)", nullable: false),
                    BlockedUsersId = table.Column<string>(type: "character varying(64)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_blocks", x => new { x.BlockedById, x.BlockedUsersId });
                    table.ForeignKey(
                        name: "FK_user_blocks_users_BlockedById",
                        column: x => x.BlockedById,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_user_blocks_users_BlockedUsersId",
                        column: x => x.BlockedUsersId,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "user_follows",
                columns: table => new
                {
                    FollowersId = table.Column<string>(type: "character varying(64)", nullable: false),
                    FollowingId = table.Column<string>(type: "character varying(64)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_follows", x => new { x.FollowersId, x.FollowingId });
                    table.ForeignKey(
                        name: "FK_user_follows_users_FollowersId",
                        column: x => x.FollowersId,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_user_follows_users_FollowingId",
                        column: x => x.FollowingId,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_user_blocks_BlockedUsersId",
                table: "user_blocks",
                column: "BlockedUsersId");

            migrationBuilder.CreateIndex(
                name: "IX_user_follows_FollowingId",
                table: "user_follows",
                column: "FollowingId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "user_blocks");

            migrationBuilder.DropTable(
                name: "user_follows");
        }
    }
}
