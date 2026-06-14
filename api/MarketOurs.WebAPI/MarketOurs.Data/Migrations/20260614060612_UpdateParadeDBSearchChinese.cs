using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketOurs.Data.Migrations
{
    /// <summary>
    /// Rebuild the ParadeDB BM25 index with Chinese tokenization and sortable/filterable fields.
    /// </summary>
    public partial class UpdateParadeDBSearchChinese : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            if (migrationBuilder.ActiveProvider != "Npgsql.EntityFrameworkCore.PostgreSQL")
            {
                return;
            }

            migrationBuilder.Sql("CREATE EXTENSION IF NOT EXISTS paradedb CASCADE;");
            migrationBuilder.Sql("""
                DROP INDEX IF EXISTS posts_search_idx;

                CREATE INDEX posts_search_idx
                ON posts
                USING bm25 (
                    "Id",
                    "Title" pdb.chinese_compatible,
                    "Content" pdb.chinese_compatible,
                    "IsReview",
                    "CreatedAt"
                )
                WITH (key_field = 'Id');
                """);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            if (migrationBuilder.ActiveProvider != "Npgsql.EntityFrameworkCore.PostgreSQL")
            {
                return;
            }

            migrationBuilder.Sql("DROP INDEX IF EXISTS posts_search_idx;");
            migrationBuilder.Sql("""
                CALL paradedb.create_bm25(
                    index_name => 'posts_search_idx',
                    table_name => 'posts',
                    columns => '{"Title": {}, "Content": {}}'
                );
                """);
        }
    }
}
