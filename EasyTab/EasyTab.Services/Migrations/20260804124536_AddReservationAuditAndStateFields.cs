using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyTab.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationAuditAndStateFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsCancelled",
                table: "Reservations");

            migrationBuilder.AddColumn<DateTime>(
                name: "ApprovedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ApprovedById",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CancellationReason",
                table: "Reservations",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CancelledById",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_ApprovedById",
                table: "Reservations",
                column: "ApprovedById");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_CancelledById",
                table: "Reservations",
                column: "CancelledById");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_ApprovedBy",
                table: "Reservations",
                column: "ApprovedById",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_CancelledBy",
                table: "Reservations",
                column: "CancelledById",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_ApprovedBy",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_CancelledBy",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_ApprovedById",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_CancelledById",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "ApprovedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "ApprovedById",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CancellationReason",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CancelledAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CancelledById",
                table: "Reservations");

            migrationBuilder.AddColumn<bool>(
                name: "IsCancelled",
                table: "Reservations",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }
    }
}
