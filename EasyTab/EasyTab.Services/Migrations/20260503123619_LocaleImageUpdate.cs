using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyTab.Services.Migrations
{
    /// <inheritdoc />
    public partial class LocaleImageUpdate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__LocaleIma__Local__787EE5A0",
                table: "LocaleImages");

            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "LocaleImages");

            migrationBuilder.AddColumn<string>(
                name: "Base64Content",
                table: "LocaleImages",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContentType",
                table: "LocaleImages",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "LocaleImages",
                type: "datetime",
                nullable: false,
                defaultValueSql: "GETUTCDATE()");

            migrationBuilder.AddColumn<string>(
                name: "FileName",
                table: "LocaleImages",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddForeignKey(
                name: "FK__LocaleIma__Local__787EE5A0",
                table: "LocaleImages",
                column: "LocaleId",
                principalTable: "Locales",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__LocaleIma__Local__787EE5A0",
                table: "LocaleImages");

            migrationBuilder.DropColumn(
                name: "Base64Content",
                table: "LocaleImages");

            migrationBuilder.DropColumn(
                name: "ContentType",
                table: "LocaleImages");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "LocaleImages");

            migrationBuilder.DropColumn(
                name: "FileName",
                table: "LocaleImages");

            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "LocaleImages",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddForeignKey(
                name: "FK__LocaleIma__Local__787EE5A0",
                table: "LocaleImages",
                column: "LocaleId",
                principalTable: "Locales",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
