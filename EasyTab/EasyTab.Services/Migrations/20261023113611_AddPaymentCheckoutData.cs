using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyTab.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentCheckoutData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Payments_PayPalOrderId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_ReservationId",
                table: "Payments");

            migrationBuilder.AlterColumn<int>(
                name: "ReservationId",
                table: "Payments",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<string>(
                name: "PayPalOrderId",
                table: "Payments",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);

            migrationBuilder.AddColumn<DateTime>(
                name: "CaptureRequestedAt",
                table: "Payments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "CheckoutId",
                table: "Payments",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<TimeOnly>(
                name: "EndTime",
                table: "Payments",
                type: "time",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastCheckedAt",
                table: "Payments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "NumberOfGuests",
                table: "Payments",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReservationDate",
                table: "Payments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<TimeOnly>(
                name: "StartTime",
                table: "Payments",
                type: "time",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TableId",
                table: "Payments",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "Payments",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Payments_CheckoutId",
                table: "Payments",
                column: "CheckoutId",
                unique: true,
                filter: "[CheckoutId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_PayPalOrderId",
                table: "Payments",
                column: "PayPalOrderId",
                unique: true,
                filter: "[PayPalOrderId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_ReservationId",
                table: "Payments",
                column: "ReservationId",
                unique: true,
                filter: "[ReservationId] IS NOT NULL AND [Status] IN ('Created', 'Completed')");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Status_CaptureRequestedAt_LastCheckedAt",
                table: "Payments",
                columns: new[] { "Status", "CaptureRequestedAt", "LastCheckedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_TableId",
                table: "Payments",
                column: "TableId");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_UserId",
                table: "Payments",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_Tables_TableId",
                table: "Payments",
                column: "TableId",
                principalTable: "Tables",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_Users_UserId",
                table: "Payments",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Payments_Tables_TableId",
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK_Payments_Users_UserId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_CheckoutId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_PayPalOrderId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_ReservationId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_Status_CaptureRequestedAt_LastCheckedAt",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_TableId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_UserId",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "CaptureRequestedAt",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "CheckoutId",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "EndTime",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "LastCheckedAt",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "NumberOfGuests",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "ReservationDate",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "StartTime",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "TableId",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "Payments");

            migrationBuilder.AlterColumn<int>(
                name: "ReservationId",
                table: "Payments",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "PayPalOrderId",
                table: "Payments",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100,
                oldNullable: true);

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
    }
}
