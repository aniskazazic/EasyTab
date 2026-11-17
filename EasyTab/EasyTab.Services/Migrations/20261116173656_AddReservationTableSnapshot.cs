using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyTab.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationTableSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "TableCapacity",
                table: "Reservations",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "TableName",
                table: "Reservations",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            // Postojeće rezervacije dobijaju trenutne vrijednosti stola (i uklonjeni stol je i dalje red u Tables).
            migrationBuilder.Sql(
                """
                UPDATE r
                SET r.TableName = t.Name, r.TableCapacity = t.NumberOfGuests
                FROM Reservations r
                INNER JOIN Tables t ON t.Id = r.TableId;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TableCapacity",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "TableName",
                table: "Reservations");
        }
    }
}
