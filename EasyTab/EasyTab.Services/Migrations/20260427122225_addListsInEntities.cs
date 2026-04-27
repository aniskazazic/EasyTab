using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyTab.Services.Migrations
{
    /// <inheritdoc />
    public partial class addListsInEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__UserRoles__RoleI__45F365D3",
                table: "UserRoles");

            migrationBuilder.DropForeignKey(
                name: "FK__UserRoles__UserI__44FF419A",
                table: "UserRoles");

            migrationBuilder.AddForeignKey(
                name: "FK__UserRoles__RoleI__45F365D3",
                table: "UserRoles",
                column: "RoleId",
                principalTable: "Roles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK__UserRoles__UserI__44FF419A",
                table: "UserRoles",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__UserRoles__RoleI__45F365D3",
                table: "UserRoles");

            migrationBuilder.DropForeignKey(
                name: "FK__UserRoles__UserI__44FF419A",
                table: "UserRoles");

            migrationBuilder.AddForeignKey(
                name: "FK__UserRoles__RoleI__45F365D3",
                table: "UserRoles",
                column: "RoleId",
                principalTable: "Roles",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK__UserRoles__UserI__44FF419A",
                table: "UserRoles",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");
        }
    }
}
