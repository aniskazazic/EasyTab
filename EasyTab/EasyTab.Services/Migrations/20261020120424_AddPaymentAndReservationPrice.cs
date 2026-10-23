using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyTab.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentAndReservationPrice : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "ReservationPrice",
                table: "Locales",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 5.00m);

            migrationBuilder.CreateTable(
                name: "Payments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReservationId = table.Column<int>(type: "int", nullable: false),
                    AmountKm = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    ApprovalUrl = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    PayPalOrderId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PayPalCaptureId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    PayPalRefundId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime", nullable: true),
                    RefundedAmount = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    RefundedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Payments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Payments_Reservations",
                        column: x => x.ReservationId,
                        principalTable: "Reservations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_PayPalOrderId",
                table: "Payments",
                column: "PayPalOrderId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Payments_ReservationId",
                table: "Payments",
                column: "ReservationId",
                unique: true,
                filter: "[Status] IN ('Created', 'Completed')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Payments");

            migrationBuilder.DropColumn(
                name: "ReservationPrice",
                table: "Locales");
        }
    }
}
