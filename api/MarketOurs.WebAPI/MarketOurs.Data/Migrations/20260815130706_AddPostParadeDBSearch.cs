using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPostParadeDBSearch : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ParadeDB 全文索引仅适用于 PostgreSQL；SQLite 本地开发跳过
            if (migrationBuilder.ActiveProvider != "Npgsql.EntityFrameworkCore.PostgreSQL")
            {
                return;
            }

            migrationBuilder.CreateIndex(
                name: "posts_search_idx",
                table: "posts",
                column: "Id")
                .Annotation("ParadeDB:IndexFields", new[] { "\"Id\"", "(\"Title\"::pdb.chinese_compatible)", "(\"Content\"::pdb.chinese_compatible)", "\"IsReview\"", "\"TagId\"", "\"CreatedAt\"" })
                .Annotation("ParadeDB:IndexKeyField", "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            if (migrationBuilder.ActiveProvider != "Npgsql.EntityFrameworkCore.PostgreSQL")
            {
                return;
            }

            migrationBuilder.DropIndex(
                name: "posts_search_idx",
                table: "posts");
        }
    }
}
